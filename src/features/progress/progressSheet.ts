// « Ma progression » : deux volets.
// - Progression : niveau, titre porté, statistiques, chemin des rangs, déblocages, barème de réputation.
// - Succès : obtenus, en cours (avec avancement), secrets ; titres à porter.
import { formatEuros } from '../../art/cardStyle';
import { ACHIEVEMENTS, achievementReward, earnedTitles, wearTitle } from '../../core/achievements';
import { PEARLS } from '../../core/catalog';
import { JEWEL_RARITIES } from '../../core/jewels';
import { levelFromXp, MILESTONES, rankForLevel, RANKS } from '../../core/levels';
import { track } from '../../platform/analytics';
import type { AppContext } from '../context';

type Tab = 'progress' | 'achievements';

export function openProgressSheet(ctx: AppContext, initialTab: Tab): void {
  let tab: Tab = initialTab;
  const sheet = document.createElement('div');
  sheet.className = 'dust-sheet progress-sheet';
  sheet.setAttribute('role', 'dialog');
  sheet.setAttribute('aria-label', 'Ma progression');
  document.body.append(sheet);

  function progressTab(): string {
    const { player, tuning } = ctx;
    const progress = levelFromXp(player.reputation, tuning);
    const pearlsFound = new Set(player.cards.map((c) => c.pearlId)).size;
    const pearlsTotal = PEARLS.filter((p) => p.id !== 'empty').length;
    const jewelsFound = new Set(player.jewelCards.map((c) => c.jewel.rarityId)).size;
    const jewelValue = player.jewelCards.reduce((sum, c) => sum + c.value, 0);
    const rank = rankForLevel(progress.level);
    return `
      <div class="progress-stats">
        <div><b>${player.oystersOpened}</b><span>huîtres ouvertes</span></div>
        <div><b>${pearlsFound}/${pearlsTotal}</b><span>perles découvertes</span></div>
        <div><b>${jewelsFound}/${JEWEL_RARITIES.length}</b><span>raretés de bijoux</span></div>
        <div><b>${formatEuros(jewelValue)}</b><span>de bijoux (fictifs)</span></div>
        <div><b>${player.stats.bestCrackFreeStreak}</b><span>meilleure série sans fêlure</span></div>
        <div><b>${player.stats.lustreS}</b><span>lustres S</span></div>
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
        <li>Quête du jour <b>+${tuning.questRewardReputation}</b> · succès <b>+${tuning.achievementReputation}</b></li>
      </ul>
      <p class="dust-fine">Chaque niveau rapporte ${tuning.levelRewardOysters} huîtres et ${tuning.levelRewardDust} ✦ ; un écrin tous les ${tuning.levelEcrinEvery} niveaux et à chaque nouveau rang.</p>
      <button type="button" class="link settings-link" data-action="settings">Réglages du prototype</button>`;
  }

  function achievementsTab(): string {
    const { player, tuning } = ctx;
    const titles = earnedTitles(player);
    const rows = ACHIEVEMENTS.map((a) => {
      const done = player.achievements[a.id] !== undefined;
      const [n, goal] = a.progress(player);
      const hidden = a.secret && !done;
      const reward = achievementReward(a.tier, tuning);
      const percent = Math.round((n / goal) * 100);
      return `<li class="achievement ${done ? 'done' : ''} tier-${a.tier}">
        <span class="achievement-medal" aria-hidden="true">${done ? '★' : hidden ? '?' : '☆'}</span>
        <span class="achievement-text">
          <b>${hidden ? 'Succès secret' : a.name}</b>
          <small>${hidden ? 'Continue à pêcher…' : a.description}</small>
          ${!done && !hidden && goal > 1 ? `<span class="quest-bar"><i style="width:${percent}%"></i></span><small>${n}/${goal}</small>` : ''}
          ${a.title && !hidden ? `<small class="achievement-title">Titre : « ${a.title} »</small>` : ''}
        </span>
        <em>${done ? new Date(player.achievements[a.id]).toLocaleDateString('fr-FR') : `+${reward.dust} ✦`}</em>
      </li>`;
    });
    const doneCount = ACHIEVEMENTS.filter((a) => player.achievements[a.id] !== undefined).length;
    return `
      <p class="muted">${doneCount} sur ${ACHIEVEMENTS.length} succès</p>
      ${
        titles.length
          ? `<h3>Mes titres</h3><div class="title-list">
              <button type="button" data-title="" class="${player.title === null ? 'active' : ''}">Aucun</button>
              ${titles.map((t) => `<button type="button" data-title="${t}" class="${player.title === t ? 'active' : ''}">${t}</button>`).join('')}
            </div>`
          : '<p class="dust-fine">Certains succès donnent un titre, affiché sous ton rang.</p>'
      }
      <ul class="achievement-list">${rows.join('')}</ul>`;
  }

  function render(): void {
    const { player, tuning } = ctx;
    const progress = levelFromXp(player.reputation, tuning);
    const rank = rankForLevel(progress.level);
    const percent = progress.needed ? Math.round((progress.into / progress.needed) * 100) : 100;
    const scroll = sheet.querySelector('.dust-panel')?.scrollTop ?? 0;
    sheet.innerHTML = `
      <div class="dust-panel">
        <button type="button" class="dust-close" aria-label="Fermer">✕</button>
        <p class="progress-kicker">${rank.title}${player.title ? ` · <span class="worn-title">« ${player.title} »</span>` : ''}</p>
        <h2>Niveau ${progress.level}</h2>
        <div class="xp-bar" role="progressbar" aria-valuenow="${percent}" aria-valuemin="0" aria-valuemax="100"><i style="width:${percent}%"></i></div>
        <p class="muted xp-text">${progress.needed ? `${progress.into} / ${progress.needed} réputation pour le niveau ${progress.level + 1}` : 'Niveau maximum'}</p>
        <div class="tabs sheet-tabs" role="group" aria-label="Volet">
          <button type="button" data-tab="progress" class="${tab === 'progress' ? 'active' : ''}">Progression</button>
          <button type="button" data-tab="achievements" class="${tab === 'achievements' ? 'active' : ''}">Succès</button>
        </div>
        ${tab === 'progress' ? progressTab() : achievementsTab()}
      </div>`;
    const panel = sheet.querySelector<HTMLElement>('.dust-panel')!;
    if (sheet.dataset.shown) panel.style.animation = 'none';
    sheet.dataset.shown = 'true';
    panel.scrollTop = scroll;
  }

  const close = () => {
    sheet.remove();
    ctx.showRewards();
  };
  for (const type of ['pointerdown', 'pointerup'] as const) sheet.addEventListener(type, (event) => event.stopPropagation());
  sheet.addEventListener('click', (event) => {
    event.stopPropagation();
    const target = event.target as HTMLElement;
    if (target === sheet || target.closest('.dust-close')) return close();
    const tabButton = target.closest<HTMLElement>('[data-tab]');
    if (tabButton) {
      tab = tabButton.dataset.tab as Tab;
      sheet.querySelector<HTMLElement>('.dust-panel')!.scrollTop = 0;
      return render();
    }
    const titleButton = target.closest<HTMLElement>('[data-title]');
    if (titleButton) {
      const title = titleButton.dataset.title || null;
      ctx.setPlayer(wearTitle(ctx.player, title));
      track('title_worn', { title: title ?? 'aucun' });
      return render();
    }
    if (target.closest('[data-action="settings"]')) {
      sheet.remove();
      ctx.goTo('tuning');
    }
  });
  render();
}
