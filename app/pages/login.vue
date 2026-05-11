<script setup lang="ts">
const route = useRoute()
const client = useSupabaseClient()
const user = useSupabaseUser()

const email = ref('')
const loading = ref(false)
const message = ref('')
const errorMessage = ref('')
const cooldownSeconds = ref(0)
let cooldownInterval: ReturnType<typeof setInterval> | null = null

function startCooldown(seconds = 60) {
  cooldownSeconds.value = seconds
  if (cooldownInterval) {
    clearInterval(cooldownInterval)
  }

  cooldownInterval = setInterval(() => {
    cooldownSeconds.value -= 1
    if (cooldownSeconds.value <= 0 && cooldownInterval) {
      clearInterval(cooldownInterval)
      cooldownInterval = null
    }
  }, 1000)
}

watchEffect(async () => {
  if (user.value) {
    await navigateTo(String(route.query.redirect || '/admin'))
  }
})

async function signIn() {
  if (cooldownSeconds.value > 0) {
    return
  }

  loading.value = true
  message.value = ''
  errorMessage.value = ''

  const { error } = await client.auth.signInWithOtp({
    email: email.value,
    options: {
      emailRedirectTo: new URL('/login?redirect=/admin', window.location.origin).toString()
    }
  })

  loading.value = false

  if (error) {
    if (error.message.toLowerCase().includes('rate limit')) {
      errorMessage.value = 'Je hebt te veel e-mails op korte tijd aangevraagd. Wacht even en probeer daarna opnieuw.'
      startCooldown(60)
      return
    }

    errorMessage.value = error.message
    return
  }

  message.value = 'Controleer je e-mail voor de aanmeldlink.'
  startCooldown(60)
}

onBeforeUnmount(() => {
  if (cooldownInterval) {
    clearInterval(cooldownInterval)
  }
})
</script>

<template>
  <UContainer class="py-10 max-w-xl">
    <UCard>
      <template #header>
        <h1 class="text-xl font-semibold">
          Aanmelden
        </h1>
      </template>

      <form class="space-y-4" @submit.prevent="signIn">
        <div class="space-y-1">
          <label for="email" class="text-sm font-medium">E-mail</label>
          <input id="email" v-model="email" type="email" required class="w-full border rounded px-3 py-2 bg-transparent">
        </div>

        <UButton
          type="submit"
          :loading="loading"
          :disabled="cooldownSeconds > 0"
          :label="cooldownSeconds > 0 ? `Opnieuw mogelijk over ${cooldownSeconds}s` : 'Magic link verzenden'"
        />
      </form>

      <p v-if="message" class="text-sm mt-4 text-green-600">
        {{ message }}
      </p>
      <p v-if="errorMessage" class="text-sm mt-4 text-red-600">
        {{ errorMessage }}
      </p>
    </UCard>
  </UContainer>
</template>
