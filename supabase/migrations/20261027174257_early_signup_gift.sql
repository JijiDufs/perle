-- La coquille « Première marée » pour les inscrits d'avant la sortie (app iOS 1.1).
-- La liste (early_access_signups, créée le 2026-10-12) reste illisible par les clients : RLS sans aucune règle,
-- et aucun droit pour anon / authenticated. L'app demande seulement si l'e-mail du joueur connecté y figure :
-- auth.email() est l'adresse vérifiée du compte (code par e-mail, ou Apple sans « Masquer mon e-mail »).

-- E-mails rangés en minuscules (l'import les met en minuscules ; la comparaison se fait sur la clé).
alter table public.early_access_signups add constraint early_access_signups_email_lower check (email = lower(email));
revoke all on public.early_access_signups from anon, authenticated;

create or replace function public.is_early_signup()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.early_access_signups e where e.email = lower(auth.email()));
$$;
revoke all on function public.is_early_signup() from public, anon;
grant execute on function public.is_early_signup() to authenticated;
