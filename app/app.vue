<script setup lang="ts">
import logoLight from '~/assets/images/Play-ER.svg'
import logoDark from '~/assets/images/Play-ER_Dark.svg'

const user = useSupabaseUser()
const client = useSupabaseClient()

const title = 'Play-ER - Cozy Monday'
const description = 'Wekelijkse snooker clubavond op maandag.'

useHead({
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  link: [
    { rel: 'icon', href: '/favicon.ico' }
  ],
  htmlAttrs: {
    lang: 'nl'
  }
})

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  twitterCard: 'summary_large_image'
})

async function signOut() {
  await client.auth.signOut()
  await navigateTo('/')
}
</script>

<template>
  <UApp>
    <UHeader :toggle="false">
      <template #left>
        <NuxtLink to="/" class="flex items-center gap-3">
          <img :src="logoLight" alt="Play-ER" class="h-8 w-auto dark:hidden">
          <img :src="logoDark" alt="Play-ER" class="hidden h-8 w-auto dark:block">
          <span class="text-lg font-semibold">Cozy Monday</span>
        </NuxtLink>
      </template>

      <template #right>
        <UColorModeButton />
        <UButton to="/admin" color="neutral" variant="ghost" label="Beheer" />
        <UButton v-if="user" color="neutral" variant="outline" label="Afmelden" @click="signOut" />
      </template>
    </UHeader>

    <UMain>
      <NuxtPage />
    </UMain>
  </UApp>
</template>
