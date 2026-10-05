// « Ma progression » : niveau, rang, chemin des rangs, déblocages à venir, comment gagner de la réputation.
import { PEARLS } from '../../core/catalog';
import { JEWEL_RARITIES } from '../../core/jewels';
import { levelFromXp, MILESTONES, rankForLevel, RANKS } from '../../core/levels';
import type { PlayerState } from '../../core/player';
import type { Tuning } from '../../tuning';
import { formatEuros } from '../../art/cardStyle';

export function openProgressSheet(player: PlayerState, tuning: Tuning): void {
  const progress = levelFromXp(player.reputation, tuning);
  const rank = rankForLevel(progress.level);
  const pearlsFound = new Set(player.cards.map((c) => c.pearlId)).size;
  const pearlsTotal = PEARLS.filter((p) => p.id !== 'empty').length;
  const jewelsFound = new Set(player.jewelCards.map((c) => c.jewel.rarityId)).size;
  const percent = progress.needed ? Math.round((progress.into / progress.needed) * 100) : 100;
  const jewelValue = player.jewelCards.reduce((sum, c) => sum + c.value, 0);

  const sheet = document.createElement('div');
  sheet.className = 'dust-sheet progress-sheet';
  sheet.setAttribute('role', 'dialog');
  sheet.setAttribute('aria-label', 'Ma progression');
  sheet.innerHTML = `
    <div class="dust-panel">
      <button type="button" class="dust-close" aria-label="Fermer">✕</button>
      <p class="progress-kicker">${rank.title}</p>
      <h2>Niveau ${progress.level}</h2>
      <div class="xp-bar" role="progressbar" aria-valuenow="${percent}" aria-valuemin="0" aria-valuemax="100"><i style="width:${percent}%"></i></div>
      <p class="muted xp-text">${progress.needed ? `${progress.into} / ${progress.needed} réputation pour le niveau ${progress.level + 1}` : 'Niveau maximum'}</p>

      <div class="progress-stats">
        <div><b>${player.oystersOpened}</b><span>huîtres ouvertes</span></div>
        <div><b>${pearlsFound}/${pearlsTotal}</b><span>perles découvertes</span></div>
        <div><b>${jewelsFound}/${JEWEL_RARITIES.length}</b><span>raretés de bijoux</span></div>
        <div><b>${formatEuros(jewelValue)}</b><span>de bijoux (fictifs)</span></div>
      </div>

      <h3>Les rangs</h3>
      <ol class="rank-road">
        ${RANKS.map((r) => {
          const state = progress.level >= r.level ? (r.id === rank.id ? 'current' : 'done') : 'locked';
          return `<li class="${state}"><span class="rank-level">${r.level}</span><span><b>${r.title}</b><small>${r.opens}</small></span></li>`;
        }).join('')}
      </ol>

      <h3>Déblocages</h3>
      <ul class="milestones">
        ${MILESTONES.map((m) => {
          const reached = progress.level >= m.level;
          const status = m.available ? (reached ? 'Débloqué' : `Niveau ${m.level}`) : 'À venir';
          return `<li class="${reached && m.available ? 'done' : ''}"><span class="rank-level">${m.level}</span><span>${m.label}</span><em>${status}</em></li>`;
        }).join('')}
      </ul>

      <h3>Gagner de la réputation</h3>
      <ul class="rep-list">
        <li>Ouvrir une huître <b>+${tuning.repOyster}</b></li>
        <li>Par ◆ de rareté de la perle <b>+${tuning.repPerTier}</b></li>
        <li>Lustre S / A (sans fêlure) <b>+${tuning.repLustreS} / +${tuning.repLustreA}</b></li>
        <li>Nouvelle perle ou nouvelle rareté de bijou <b>+${tuning.repDiscovery}</b></li>
        <li>Ouvrir un écrin <b>+${tuning.repEcrin}</b> · éclat parfait <b>+${tuning.repPerfect}</b></li>
        <li>Certificat d’expertise <b>+${tuning.repExpertise}</b></li>
      </ul>
      <p class="dust-fine">Chaque niveau rapporte ${tuning.levelRewardOysters} huîtres et ${tuning.levelRewardDust} ✦ ; un écrin tous les ${tuning.levelEcrinEvery} niveaux et à chaque nouveau rang.</p>
    </div>`;
  const close = () => sheet.remove();
  for (const type of ['pointerdown', 'pointerup'] as const) sheet.addEventListener(type, (event) => event.stopPropagation());
  sheet.addEventListener('click', (event) => {
    event.stopPropagation();
    if (event.target === sheet || (event.target as HTMLElement).closest('.dust-close')) close();
  });
  document.body.append(sheet);
}
