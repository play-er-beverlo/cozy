<script setup lang="ts">
import { h, resolveComponent } from 'vue'
import type { TableColumn } from '@nuxt/ui'

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
}

const client = useSupabaseClient()
const sorting = ref([{ id: 'name', desc: false }])
const UButton = resolveComponent('UButton')

const { data: playersData, pending: playersPending, error: playersError } = await useAsyncData('players', async () => {
  const { data, error } = await client
    .from('players')
    .select('id,name,rating')

  if (error) {
    throw error
  }
  return data as Player[]
})

const { data: tournamentsData, pending: tournamentsPending, error: tournamentsError } = await useAsyncData('tournaments', async () => {
  const { data, error } = await client
    .from('tournaments')
    .select('id,event_date,winner_player_id,loser_player_id,winner_rating_before,winner_rating_after,loser_rating_before,loser_rating_after')
    .order('event_date', { ascending: false })

  if (error) {
    throw error
  }
  return data as TournamentRow[]
})

const players = computed(() => playersData.value ?? [])
const tournaments = computed(() => tournamentsData.value ?? [])
const playerMap = computed(() => new Map(players.value.map(player => [player.id, player.name])))

function formatDate(dateString: string) {
  return new Date(`${dateString}T00:00:00`).toLocaleDateString('nl-BE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  })
}

function getSortableHeader(column: { getIsSorted: () => false | 'asc' | 'desc', toggleSorting: (desc?: boolean) => void }, label: string) {
  const isSorted = column.getIsSorted()
  return h(UButton, {
    color: 'neutral',
    variant: 'ghost',
    label,
    icon: isSorted
      ? isSorted === 'asc'
        ? 'i-lucide-arrow-up-narrow-wide'
        : 'i-lucide-arrow-down-wide-narrow'
      : 'i-lucide-arrow-up-down',
    class: '-mx-2.5',
    onClick: () => column.toggleSorting(column.getIsSorted() === 'asc')
  })
}

const playerColumns: TableColumn<Player>[] = [
  {
    accessorKey: 'name',
    header: ({ column }) => getSortableHeader(column, 'Naam')
  },
  {
    accessorKey: 'rating',
    header: ({ column }) => getSortableHeader(column, 'Niveau')
  }
]

</script>

<template>
  <UContainer class="py-8 space-y-8">
    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Spelers
        </h2>
      </template>

      <div v-if="playersPending">
        Spelers laden...
      </div>
      <div v-else-if="playersError">
        Laden van spelers mislukt: {{ playersError.message }}
      </div>
      <UTable
        v-else
        v-model:sorting="sorting"
        :data="players"
        :columns="playerColumns"
        empty="Geen spelers gevonden."
      />
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Tornooigeschiedenis
        </h2>
      </template>

      <div class="text-sm text-muted">
        <div v-if="tournamentsPending">
          Tornooigeschiedenis laden...
        </div>
        <div v-else-if="tournamentsError">
          Laden van tornooien mislukt: {{ tournamentsError.message }}
        </div>
        <div v-else-if="!tournaments.length">
          Er zijn nog geen tornooiresultaten geregistreerd.
        </div>
        <div v-else class="overflow-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b">
                <th class="text-left py-2">
                  Datum
                </th>
                <th class="text-left py-2">
                  Winnaar
                </th>
                <th class="text-left py-2">
                  Verliezer
                </th>
                <!-- <th class="text-left py-2">
                  Niveau winnaar
                </th>
                <th class="text-left py-2">
                  Niveau verliezer
                </th> -->
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in tournaments" :key="row.id" class="border-b last:border-b-0">
                <td class="py-2">
                  {{ formatDate(row.event_date) }}
                </td>
                <td class="py-2">
                  {{ playerMap.get(row.winner_player_id) ?? 'Onbekend' }}
                </td>
                <td class="py-2">
                  {{ playerMap.get(row.loser_player_id) ?? 'Onbekend' }}
                </td>
                <!-- <td class="py-2">
                  {{ row.winner_rating_before }} -> {{ row.winner_rating_after }}
                </td>
                <td class="py-2">
                  {{ row.loser_rating_before }} -> {{ row.loser_rating_after }}
                </td> -->
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold">
          Hoe werkt Cozy Monday?
        </h2>
      </template>

      <div class="space-y-3 text-sm text-muted">
        <p>
          Tijdens Cozy Monday spelen we wekelijks een tornooi.
        </p>
        <ul class="list-disc pl-5 space-y-2">
          <li>Elke speler heeft een niveau van 1 tot 10. Startniveau op basis van afdeling in competitie: Ere: 8, 1ste: 7, 2de: 6, 3de: 5, 4de: 4, 5de: 3</li>
          <li>Bij een onderlinge wedstrijd krijgt de lager geplaatste speler 5 punten voorsprong per niveauverschil.</li>
          <li>Na een tornooi, stijgt de winnaar en daalt de verliezer, met 1 niveaupunt.</li>
          <li>Niveaus blijven altijd binnen de grenzen van 1 tot 10.</li>
        </ul>
      </div>
    </UCard>
  </UContainer>
</template>
