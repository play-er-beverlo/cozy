<script setup lang="ts">
definePageMeta({
  middleware: 'admin'
})

type Player = {
  id: string
  name: string
  rating: number
}

type TournamentRow = {
  id: string
  event_date: string
  winner_player_id: string
  loser_player_id: string
  winner_rating_before: number
  winner_rating_after: number
  loser_rating_before: number
  loser_rating_after: number
  created_at: string
}

const client = useSupabaseClient()

const { data: playersData, pending, error, refresh } = await useAsyncData('admin-players', async () => {
  const { data, error } = await client
    .from('players')
    .select('id,name,rating')
    .order('name', { ascending: true })

  if (error) {
    throw error
  }

  return data as Player[]
})

const { data: tournamentsData, pending: tournamentsPending, error: tournamentsError, refresh: refreshTournaments } = await useAsyncData('admin-tournaments', async () => {
  const { data, error } = await client
    .from('tournaments')
    .select('id,event_date,winner_player_id,loser_player_id,winner_rating_before,winner_rating_after,loser_rating_before,loser_rating_after,created_at')
    .order('event_date', { ascending: false })

  if (error) {
    throw error
  }

  return data as TournamentRow[]
})

const players = computed(() => playersData.value ?? [])
const tournaments = computed(() => tournamentsData.value ?? [])
const latestTournamentId = computed(() => tournaments.value[0]?.id ?? null)
const playerMap = computed(() => new Map(players.value.map(player => [player.id, player.name])))

function formatDate(dateString: string) {
  return new Date(`${dateString}T00:00:00`).toLocaleDateString('nl-BE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  })
}

const playerName = ref('')
const playerRating = ref(1)

const savingPlayer = ref(false)
const playerMessage = ref('')
const playerError = ref('')

const tournamentDate = ref(new Date().toISOString().slice(0, 10))
const winnerId = ref('')
const loserId = ref('')
const savingTournament = ref(false)
const tournamentMessage = ref('')
const tournamentError = ref('')
const deletingTournamentId = ref<string | null>(null)
const tournamentManageMessage = ref('')
const tournamentManageError = ref('')

async function addPlayer() {
  savingPlayer.value = true
  playerMessage.value = ''
  playerError.value = ''

  const { error } = await client.from('players').insert({
    name: playerName.value.trim(),
    rating: playerRating.value
  })

  savingPlayer.value = false

  if (error) {
    playerError.value = error.message
    return
  }

  playerMessage.value = 'Speler toegevoegd.'
  playerName.value = ''
  playerRating.value = 1
  await refresh()
}

async function updatePlayer(player: Player) {
  const { error } = await client
    .from('players')
    .update({
      name: player.name.trim(),
      rating: player.rating
    })
    .eq('id', player.id)

  if (error) {
    playerError.value = error.message
    return
  }

  playerMessage.value = `${player.name} bijgewerkt.`
}

async function deletePlayer(playerId: string) {
  const { error } = await client
    .from('players')
    .delete()
    .eq('id', playerId)

  if (error) {
    playerError.value = error.message
    return
  }

  playerMessage.value = 'Speler verwijderd.'
  await refresh()
}

async function recordTournament() {
  savingTournament.value = true
  tournamentMessage.value = ''
  tournamentError.value = ''

  if (winnerId.value === loserId.value) {
    savingTournament.value = false
    tournamentError.value = 'Winnaar en verliezer moeten verschillende spelers zijn.'
    return
  }

  const { error } = await client.rpc('record_tournament_result', {
    p_event_date: tournamentDate.value,
    p_winner_player_id: winnerId.value,
    p_loser_player_id: loserId.value
  })

  savingTournament.value = false

  if (error) {
    tournamentError.value = error.message
    return
  }

  tournamentMessage.value = 'Tornooiresultaat opgeslagen en niveaus bijgewerkt.'
  winnerId.value = ''
  loserId.value = ''
  await Promise.all([refresh(), refreshTournaments()])
}

async function deleteTournamentResult(tournamentId: string) {
  deletingTournamentId.value = tournamentId
  tournamentManageMessage.value = ''
  tournamentManageError.value = ''

  const { error } = await client.rpc('delete_tournament_result', {
    p_tournament_id: tournamentId
  })

  deletingTournamentId.value = null

  if (error) {
    tournamentManageError.value = error.message
    return
  }

  tournamentManageMessage.value = 'Tornooiresultaat verwijderd en niveaus teruggezet.'
  await Promise.all([refresh(), refreshTournaments()])
}
</script>

<template>
  <UContainer class="py-8 space-y-8">
    <h1 class="text-xl font-semibold">
      Beheer
    </h1>

    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Tornooiresultaat registreren
        </h2>
      </template>

      <form class="grid md:grid-cols-3 gap-3 items-end" @submit.prevent="recordTournament">
        <div class="space-y-1">
          <label for="event-date" class="text-sm font-medium">Datum</label>
          <input id="event-date" v-model="tournamentDate" type="date" required class="w-full border rounded px-3 py-2 bg-transparent">
        </div>

        <div class="space-y-1">
          <label for="winner" class="text-sm font-medium">Winnaar</label>
          <select id="winner" v-model="winnerId" required class="w-full border rounded px-3 py-2 bg-transparent">
            <option value="">
              Kies winnaar
            </option>
            <option v-for="player in players" :key="`winner-${player.id}`" :value="player.id">
              {{ player.name }} ({{ player.rating }})
            </option>
          </select>
        </div>

        <div class="space-y-1">
          <label for="loser" class="text-sm font-medium">Verliezer</label>
          <select id="loser" v-model="loserId" required class="w-full border rounded px-3 py-2 bg-transparent">
            <option value="">
              Kies verliezer
            </option>
            <option v-for="player in players" :key="`loser-${player.id}`" :value="player.id">
              {{ player.name }} ({{ player.rating }})
            </option>
          </select>
        </div>

        <UButton class="md:col-span-3 w-fit" type="submit" :loading="savingTournament" label="Resultaat registreren" />
      </form>

      <p v-if="tournamentMessage" class="text-sm text-green-600 mt-3">
        {{ tournamentMessage }}
      </p>
      <p v-if="tournamentError" class="text-sm text-red-600 mt-3">
        {{ tournamentError }}
      </p>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Tornooiresultaten beheren
        </h2>
      </template>

      <p class="text-sm text-muted pb-3">
        Om niveaus consistent te houden kan enkel het meest recente tornooiresultaat verwijderd worden.
      </p>

      <div v-if="tournamentsPending">
        Tornooiresultaten laden...
      </div>
      <div v-else-if="tournamentsError">
        Laden van tornooiresultaten mislukt: {{ tournamentsError.message }}
      </div>
      <div v-else-if="!tournaments.length">
        Er zijn nog geen tornooiresultaten geregistreerd.
      </div>
      <div v-else class="space-y-3">
        <div
          v-for="row in tournaments"
          :key="row.id"
          class="grid md:grid-cols-[130px_1fr_1fr_1fr_auto] gap-2 items-end border-b pb-3"
        >
          <div class="text-sm">
            <p class="font-medium">
              {{ formatDate(row.event_date) }}
            </p>
          </div>
          <div class="text-sm">
            <p><span class="font-medium">Winnaar:</span> {{ playerMap.get(row.winner_player_id) ?? 'Onbekend' }}</p>
            <p>Niveau: {{ row.winner_rating_before }} -> {{ row.winner_rating_after }}</p>
          </div>
          <div class="text-sm">
            <p><span class="font-medium">Verliezer:</span> {{ playerMap.get(row.loser_player_id) ?? 'Onbekend' }}</p>
            <p>Niveau: {{ row.loser_rating_before }} -> {{ row.loser_rating_after }}</p>
          </div>
          <div class="text-sm text-muted">
            <p v-if="row.id === latestTournamentId">
              Meest recent
            </p>
          </div>
          <UButton
            color="error"
            variant="outline"
            label="Verwijderen"
            :disabled="row.id !== latestTournamentId"
            :loading="deletingTournamentId === row.id"
            @click="deleteTournamentResult(row.id)"
          />
        </div>
      </div>

      <p v-if="tournamentManageMessage" class="text-sm text-green-600 mt-3">
        {{ tournamentManageMessage }}
      </p>
      <p v-if="tournamentManageError" class="text-sm text-red-600 mt-3">
        {{ tournamentManageError }}
      </p>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Speler toevoegen
        </h2>
      </template>

      <p class="text-sm text-muted pb-3">
        Ere: 8, 1ste: 7, 2de: 6, 3de: 5, 4de: 4, 5de: 3
      </p>

      <form class="grid md:grid-cols-3 gap-3 items-end" @submit.prevent="addPlayer">
        <div class="space-y-1 md:col-span-2">
          <label for="player-name" class="text-sm font-medium">Naam speler</label>
          <input id="player-name" v-model="playerName" type="text" required class="w-full border rounded px-3 py-2 bg-transparent">
        </div>

        <div class="space-y-1">
          <label for="player-rating" class="text-sm font-medium">Niveau (1-10)</label>
          <input id="player-rating" v-model.number="playerRating" type="number" min="1" max="10" required class="w-full border rounded px-3 py-2 bg-transparent">
        </div>

        <UButton class="md:col-span-3 w-fit" type="submit" :loading="savingPlayer" label="Speler toevoegen" />
      </form>

      <p v-if="playerMessage" class="text-sm text-green-600 mt-3">
        {{ playerMessage }}
      </p>
      <p v-if="playerError" class="text-sm text-red-600 mt-3">
        {{ playerError }}
      </p>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Spelers beheren
        </h2>
      </template>

      <div v-if="pending">
        Spelers laden...
      </div>
      <div v-else-if="error">
        Laden van spelers mislukt: {{ error.message }}
      </div>
      <div v-else class="space-y-3">
        <div v-for="player in players" :key="player.id" class="grid md:grid-cols-[1fr_120px_auto_auto] gap-2 items-end border-b pb-3">
          <div class="space-y-1">
            <label class="text-sm font-medium">Naam</label>
            <input v-model="player.name" type="text" class="w-full border rounded px-3 py-2 bg-transparent">
          </div>
          <div class="space-y-1">
            <label class="text-sm font-medium">Niveau</label>
            <input v-model.number="player.rating" type="number" min="1" max="10" class="w-full border rounded px-3 py-2 bg-transparent">
          </div>
          <UButton color="primary" label="Opslaan" @click="updatePlayer(player)" />
          <UButton color="error" variant="outline" label="Verwijderen" @click="deletePlayer(player.id)" />
        </div>
      </div>
    </UCard>

  </UContainer>
</template>
