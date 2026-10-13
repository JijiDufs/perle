-- Suppression du compte par le joueur lui-même, depuis l'app (règle 5.1.1 (v) de l'App Store).
-- Ne supprime que le compte de l'appelant (auth.uid()). Les données liées partent en cascade :
-- auth.users → profiles → game_saves, user_skins, entitlements (ON DELETE CASCADE).
-- La liste d'attente (early_access_signups, par e-mail) n'est pas liée au compte : elle suit la politique des inscriptions.
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Non connecté' using errcode = '28000';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
