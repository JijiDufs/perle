-- Sauvegarde de la partie sur le compte du joueur (app iOS 1.1).
-- La table existe depuis 20261012122706 : une ligne par compte (user_id → profiles → auth.users, ON DELETE CASCADE),
-- RLS « chacun ne lit, ne crée et ne modifie que sa ligne », écriture par save_game (révision anti-conflit).
-- Suppression du compte (delete_account) : auth.users → profiles → game_saves, la partie part avec le compte.

-- 1. Les parties de l'app iOS sont des PlayerState de PearlCore, pas le format de la webapp.
alter table public.game_saves alter column save_format set default 'pearlinc.player.v1';

-- 2. Droits au plus juste : un visiteur non connecté n'y touche pas ; un joueur lit, crée et modifie sa ligne (RLS),
--    jamais de suppression directe (elle passe par delete_account).
revoke all on public.game_saves from anon;
revoke delete, truncate, references, trigger on public.game_saves from authenticated;
