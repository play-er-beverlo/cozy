# Snooker Club Evening App

Nuxt 4 + Nuxt UI app for:
- Public leaderboard (sortable by name/rating)
- Handicap preview (`5` points per rating difference)
- Public tournament history
- Admin-only player management and tournament result recording

## Stack

- Nuxt 4
- Nuxt UI
- Supabase (`@nuxtjs/supabase`)

## Environment

Copy `.env.example` to `.env` and set:

```bash
NUXT_PUBLIC_SUPABASE_URL=...
NUXT_PUBLIC_SUPABASE_KEY=...
```

## Database setup (Supabase SQL)

Run the migration in:

`supabase/migrations/20260510213000_snooker_schema.sql`

What it creates:
- `players` table with rating range check (`1..10`)
- `tournaments` table with one result per date and winner/loser constraints
- `admin_emails` allowlist table
- `is_admin()` function
- `record_tournament_result(...)` RPC to atomically:
  - read current ratings
  - apply `+1/-1` with clamping
  - update players
  - insert tournament history row
- RLS policies:
  - public `SELECT` on players/tournaments
  - admin-only writes

### Add an admin

Insert admin emails into `admin_emails`:

```sql
insert into public.admin_emails (email) values ('admin@example.com');
```

## Run

```bash
pnpm install
pnpm dev
```

## Verify

```bash
pnpm lint
pnpm typecheck
pnpm test
```
