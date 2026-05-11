create extension if not exists citext;
create extension if not exists pgcrypto;

create table if not exists public.admin_emails (
  email citext primary key,
  created_at timestamptz not null default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  name citext not null unique,
  rating int not null check (rating between 1 and 10),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  event_date date not null unique,
  winner_player_id uuid not null references public.players(id) on delete restrict,
  loser_player_id uuid not null references public.players(id) on delete restrict,
  winner_rating_before int not null check (winner_rating_before between 1 and 10),
  winner_rating_after int not null check (winner_rating_after between 1 and 10),
  loser_rating_before int not null check (loser_rating_before between 1 and 10),
  loser_rating_after int not null check (loser_rating_after between 1 and 10),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  check (winner_player_id <> loser_player_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists players_set_updated_at on public.players;
create trigger players_set_updated_at
before update on public.players
for each row
execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.admin_emails a
    where a.email = auth.email()
  );
$$;

create or replace function public.record_tournament_result(
  p_event_date date,
  p_winner_player_id uuid,
  p_loser_player_id uuid
)
returns public.tournaments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_winner_rating int;
  v_loser_rating int;
  v_winner_after int;
  v_loser_after int;
  v_row public.tournaments;
begin
  if not public.is_admin() then
    raise exception 'Only admins can record tournaments';
  end if;

  if p_winner_player_id = p_loser_player_id then
    raise exception 'Winner and loser must be different players';
  end if;

  if exists (select 1 from public.tournaments where event_date = p_event_date) then
    raise exception 'A tournament result already exists for this date';
  end if;

  select rating into v_winner_rating
  from public.players
  where id = p_winner_player_id
  for update;

  if v_winner_rating is null then
    raise exception 'Winner player not found';
  end if;

  select rating into v_loser_rating
  from public.players
  where id = p_loser_player_id
  for update;

  if v_loser_rating is null then
    raise exception 'Loser player not found';
  end if;

  v_winner_after := least(10, greatest(1, v_winner_rating + 1));
  v_loser_after := least(10, greatest(1, v_loser_rating - 1));

  update public.players
  set rating = v_winner_after
  where id = p_winner_player_id;

  update public.players
  set rating = v_loser_after
  where id = p_loser_player_id;

  insert into public.tournaments (
    event_date,
    winner_player_id,
    loser_player_id,
    winner_rating_before,
    winner_rating_after,
    loser_rating_before,
    loser_rating_after,
    created_by
  ) values (
    p_event_date,
    p_winner_player_id,
    p_loser_player_id,
    v_winner_rating,
    v_winner_after,
    v_loser_rating,
    v_loser_after,
    auth.uid()
  )
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.record_tournament_result(date, uuid, uuid) from public;
grant execute on function public.record_tournament_result(date, uuid, uuid) to authenticated;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.players enable row level security;
alter table public.tournaments enable row level security;
alter table public.admin_emails enable row level security;

drop policy if exists "public_read_players" on public.players;
create policy "public_read_players"
on public.players
for select
to anon, authenticated
using (true);

drop policy if exists "admin_write_players" on public.players;
create policy "admin_write_players"
on public.players
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "public_read_tournaments" on public.tournaments;
create policy "public_read_tournaments"
on public.tournaments
for select
to anon, authenticated
using (true);

drop policy if exists "admin_insert_tournaments" on public.tournaments;
create policy "admin_insert_tournaments"
on public.tournaments
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "admin_select_admin_emails" on public.admin_emails;
create policy "admin_select_admin_emails"
on public.admin_emails
for select
to authenticated
using (public.is_admin());
