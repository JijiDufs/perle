-- Recopiée telle qu'appliquée au projet Supabase « Pearl Inc. » le 2026-10-12, absente du dépôt jusqu'au 2026-10-27.
insert into public.pearl_types values
  ('blanche', 'Perle blanche',         'White pearl',          'commune',    70,   1),
  ('rose',    'Perle rose',            'Pink pearl',           'rare',       22,   5),
  ('noire',   'Perle noire de Tahiti', 'Tahitian black pearl', 'epique',      7,  20),
  ('doree',   'Perle dorée',           'Golden pearl',         'legendaire',  1, 100);

insert into public.skins values
  ('huitre_classique', 'Huître classique', 'Classic oyster', 'huitre', false),
  ('huitre_pionniere', 'Huître pionnière', 'Pioneer oyster', 'huitre', true);

create or replace function public.handle_user_upsert()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, equipped_skin) values (new.id, 'huitre_classique')
    on conflict do nothing;
  insert into public.entitlements (user_id) values (new.id) on conflict do nothing;
  insert into public.user_skins (user_id, skin_id, source)
    values (new.id, 'huitre_classique', 'defaut') on conflict do nothing;
  if new.email is not null and exists (
       select 1 from public.early_access_signups e where lower(e.email) = lower(new.email)) then
    insert into public.user_skins (user_id, skin_id, source)
      values (new.id, 'huitre_pionniere', 'early_access') on conflict do nothing;
  end if;
  return new;
end; $$;

revoke execute on function public.handle_user_upsert() from public, anon, authenticated;

create trigger on_auth_user_change
  after insert or update of email on auth.users
  for each row execute function public.handle_user_upsert();

create or replace function public.open_oyster()
returns json language plpgsql security definer set search_path = '' as $$
declare
  uid     uuid := auth.uid();
  total   int;
  roll    int;
  picked  public.pearl_types%rowtype;
  xp_gain int := 10;
begin
  if uid is null then raise exception 'Non authentifié'; end if;

  select sum(drop_weight) into total from public.pearl_types;
  roll := floor(random() * total)::int;
  for picked in select * from public.pearl_types order by id loop
    roll := roll - picked.drop_weight;
    exit when roll < 0;
  end loop;

  insert into public.user_pearls (user_id, pearl_type_id, quantity)
    values (uid, picked.id, 1)
    on conflict (user_id, pearl_type_id)
    do update set quantity = public.user_pearls.quantity + 1;

  update public.profiles
    set oysters_opened = oysters_opened + 1,
        xp         = xp + xp_gain,
        level      = 1 + (xp + xp_gain) / 100,
        updated_at = now()
    where id = uid;

  return json_build_object('pearl', picked.id, 'rarity', picked.rarity, 'xp_gain', xp_gain);
end; $$;

revoke execute on function public.open_oyster() from public, anon;
grant  execute on function public.open_oyster() to authenticated;
