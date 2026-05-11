drop policy if exists "admin_manage_admin_emails" on public.admin_emails;

create policy "admin_manage_admin_emails"
on public.admin_emails
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
