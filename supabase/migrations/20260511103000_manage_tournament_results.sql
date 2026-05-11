create or replace function public.delete_tournament_result(
  p_tournament_id uuid
)
returns public.tournaments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.tournaments;
  v_latest_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admins can delete tournaments';
  end if;

  select *
  into v_row
  from public.tournaments
  where id = p_tournament_id
  for update;

  if v_row.id is null then
    raise exception 'Tournament result not found';
  end if;

  select id
  into v_latest_id
  from public.tournaments
  order by event_date desc, created_at desc
  limit 1;

  if v_row.id <> v_latest_id then
    raise exception 'Only the most recent tournament result can be deleted';
  end if;

  update public.players
  set rating = v_row.winner_rating_before
  where id = v_row.winner_player_id;

  update public.players
  set rating = v_row.loser_rating_before
  where id = v_row.loser_player_id;

  delete from public.tournaments
  where id = v_row.id;

  return v_row;
end;
$$;

revoke all on function public.delete_tournament_result(uuid) from public;
grant execute on function public.delete_tournament_result(uuid) to authenticated;
