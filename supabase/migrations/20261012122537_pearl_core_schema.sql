-- Recopiée telle qu'appliquée au projet Supabase « Pearl Inc. » (ywyiidsldgfkguivuvox, eu-west-1) le 2026-10-12,
-- absente du dépôt jusqu'au 2026-10-27.
create table public.pearl_types (
  id text primary key,
  name_fr text not null,
  name_en text not null,
  rarity text not null check (rarity in ('commune','rare','epique','legendaire')),
  drop_weight int not null check (drop_weight > 0),
  value int not null default 1
);

create table public.skins (
  id text primary key,
  name_fr text not null,
  name_en text not null,
  kind text not null check (kind in ('huitre','ecrin')),
  is_exclusive boolean not null default false
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  level int not null default 1,
  xp int not null default 0,
  nacre int not null default 0,
  oysters_opened int not null default 0,
  equipped_skin text references public.skins(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_pearls (
  user_id uuid references public.profiles(id) on delete cascade,
  pearl_type_id text references public.pearl_types(id),
  quantity int not null default 0 check (quantity >= 0),
  primary key (user_id, pearl_type_id)
);

create table public.user_skins (
  user_id uuid references public.profiles(id) on delete cascade,
  skin_id text references public.skins(id),
  source text not null check (source in ('defaut','early_access','achat','recompense','pub')),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, skin_id)
);

create table public.entitlements (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  is_premium boolean not null default false,
  expires_at timestamptz,
  original_transaction_id text,
  updated_at timestamptz not null default now()
);

create table public.early_access_signups (
  email text primary key,
  signed_up_at timestamptz not null default now()
);

alter table public.pearl_types          enable row level security;
alter table public.skins                enable row level security;
alter table public.profiles             enable row level security;
alter table public.user_pearls          enable row level security;
alter table public.user_skins           enable row level security;
alter table public.entitlements         enable row level security;
alter table public.early_access_signups enable row level security;

create policy "catalogue perles lisible" on public.pearl_types for select using (true);
create policy "catalogue skins lisible"  on public.skins       for select using (true);

create policy "voir mon profil" on public.profiles for select using ((select auth.uid()) = id);

revoke update on public.profiles from authenticated, anon;
grant update (username, equipped_skin) on public.profiles to authenticated;
create policy "modifier mon pseudo / skin" on public.profiles
  for update using ((select auth.uid()) = id)
  with check (
    (select auth.uid()) = id
    and (equipped_skin is null or exists (
      select 1 from public.user_skins us
      where us.user_id = (select auth.uid()) and us.skin_id = equipped_skin))
  );

create policy "voir mes perles"     on public.user_pearls  for select using ((select auth.uid()) = user_id);
create policy "voir mes skins"      on public.user_skins   for select using ((select auth.uid()) = user_id);
create policy "voir mon abonnement" on public.entitlements for select using ((select auth.uid()) = user_id);

create index on public.user_pearls (pearl_type_id);
create index on public.user_skins (skin_id);
create index on public.profiles (equipped_skin);
