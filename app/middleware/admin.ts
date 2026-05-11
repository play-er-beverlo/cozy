export default defineNuxtRouteMiddleware(async () => {
  if (import.meta.server) {
    return
  }

  const client = useSupabaseClient()
  const user = useSupabaseUser()
  const { data: sessionData } = await client.auth.getSession()
  const hasSession = Boolean(sessionData.session)

  if (!user.value && !hasSession) {
    return navigateTo('/login?redirect=/admin')
  }

  const { data, error } = await client.rpc('is_admin')

  if (error || !data) {
    return navigateTo('/')
  }
})
