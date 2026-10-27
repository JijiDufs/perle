-- Recopiée telle qu'appliquée au projet Supabase « Pearl Inc. » le 2026-10-12, absente du dépôt jusqu'au 2026-10-27.
-- 1. Retirer le modèle simplifié (remplacé par la sauvegarde complète du jeu)
drop function if exists public.open_oyster();
drop table if exists public.user_pearls;
drop table if exists public.pearl_types;

-- 2. Catalogue réel des perles (src/core/catalog.ts) — référence pour stats / site / futur anti-triche
create table public.pearl_types (
  id               text primary key,
  name_fr          text not null,
  rarity_symbol    text not null,
  tier             int  not null check (tier between 0 and 5),
  probability      numeric(6,4) not null check (probability >= 0 and probability <= 1),
  base_value       int  not null,
  size_min_mm      numeric(4,1) not null,
  size_max_mm      numeric(4,1) not null,
  golden_or_better boolean not null default false,
  reveal_tier      int  not null check (reveal_tier between 0 and 3),
  color            text not null
);
alter table public.pearl_types enable row level security;
create policy "catalogue perles lisible" on public.pearl_types for select using (true);

insert into public.pearl_types values
  ('empty',   'Huître vide',    '—',   0, 0.0900,   0,  0,  0, false, 0, '#5b6b6b'),
  ('white',   'Perle blanche',  '◆',   1, 0.3800,  10,  5,  7.5, false, 0, '#F3F0EA'),
  ('rose',    'Perle rosée',    '◆',   1, 0.2200,  18,  6,  8.5, false, 0, '#F2C4CC'),
  ('baroque', 'Perle baroque',  '◆◆',  2, 0.1200,  30,  7, 11, false, 1, '#C9C4D8'),
  ('black',   'Perle noire',    '◆◆◆', 3, 0.0800,  60,  9, 13, false, 2, '#33374a'),
  ('golden',  'Perle dorée',    '★',   4, 0.0450, 120, 10, 14, true,  3, '#E2B04A'),
  ('giant',   'Perle géante',   '★★',  5, 0.0120, 300, 18, 26, true,  3, '#F6F2FF'),
  ('cursed',  'Perle maudite',  '★★',  5, 0.0030, 666, 13, 13, true,  3, '#3a0f2a');
-- + 5 % de trouvailles (FIND_PROBABILITY) : total = 1

-- 3. Profil : colonnes alignées sur le jeu (réputation, poussière d'or)
alter table public.profiles rename column xp to reputation;
alter table public.profiles rename column nacre to dust;

-- 4. Sauvegarde cloud : le PlayerState complet (perle.player.v1), avec révision anti-conflit multi-appareils
create table public.game_saves (
  user_id      uuid primary key references public.profiles(id) on delete cascade,
  state        jsonb not null check (jsonb_typeof(state) = 'object' and pg_column_size(state) < 2000000),
  save_format  text not null default 'perle.player.v1',
  revision     bigint not null default 1,
  updated_at   timestamptz not null default now()
);
alter table public.game_saves enable row level security;
create policy "lire ma sauvegarde" on public.game_saves
  for select using ((select auth.uid()) = user_id);
create policy "créer ma sauvegarde" on public.game_saves
  for insert with check ((select auth.uid()) = user_id);
create policy "modifier ma sauvegarde" on public.game_saves
  for update using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- 5. Courbe de niveaux (src/core/levels.ts + tuning : base 60, croissance 15, puissance 1.5, max 100)
create or replace function public.level_from_reputation(rep int)
returns int language plpgsql immutable set search_path = '' as $$
declare
  lvl  int := 1;
  rest int := greatest(0, coalesce(rep, 0));
  need int;
begin
  loop
    exit when lvl >= 100;
    need := round(60 + 15 * power(lvl, 1.5));
    exit when rest < need;
    rest := rest - need;
    lvl := lvl + 1;
  end loop;
  return lvl;
end; $$;

-- 6. Enregistrer une partie (refuse si un autre appareil a sauvegardé entre-temps)
create or replace function public.save_game(p_state jsonb, p_expected_revision bigint)
returns bigint language plpgsql security invoker set search_path = '' as $$
declare
  uid uuid := auth.uid();
  new_rev bigint;
begin
  if uid is null then raise exception 'Non authentifié'; end if;
  if p_expected_revision = 0 then
    insert into public.game_saves (user_id, state) values (uid, p_state)
      on conflict (user_id) do nothing
      returning revision into new_rev;
  else
    update public.game_saves
      set state = p_state, revision = revision + 1, updated_at = now()
      where user_id = uid and revision = p_expected_revision
      returning revision into new_rev;
  end if;
  if new_rev is null then
    raise exception 'save_conflict' using errcode = '40001',
      hint = 'Une sauvegarde plus récente existe : la recharger avant de réécrire.';
  end if;
  return new_rev;
end; $$;
revoke execute on function public.save_game(jsonb, bigint) from public, anon;
grant  execute on function public.save_game(jsonb, bigint) to authenticated;

-- 7. Synchroniser le profil (niveau, réputation, huîtres, poussière) depuis la sauvegarde
create or replace function public.sync_profile_from_save()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  rep int := case when jsonb_typeof(new.state->'reputation') = 'number'
                  then (new.state->>'reputation')::numeric::int else 0 end;
begin
  update public.profiles set
    reputation     = rep,
    level          = public.level_from_reputation(rep),
    oysters_opened = case when jsonb_typeof(new.state->'oystersOpened') = 'number'
                          then (new.state->>'oystersOpened')::numeric::int else oysters_opened end,
    dust           = case when jsonb_typeof(new.state->'dust') = 'number'
                          then (new.state->>'dust')::numeric::int else dust end,
    updated_at     = now()
  where id = new.user_id;
  return new;
end; $$;
revoke execute on function public.sync_profile_from_save() from public, anon, authenticated;

create trigger on_game_save_change
  after insert or update of state on public.game_saves
  for each row execute function public.sync_profile_from_save();
