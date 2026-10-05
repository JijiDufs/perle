// Quêtes du jour : avancement, bouton « Récupérer », bonus des trois (un écrin), renouvellement à minuit.
import { canClaimDaily, CALENDAR } from '../../core/daily';
import { claimQuest, currentQuests } from '../../core/progression';
import { isClaimable, isComplete, msUntilNextDay, questText } from '../../core/quests';
import { track } from '../../platform/analytics';
import { chimeNotes } from '../../platform/audio';
import { hapticBurst } from '../../platform/haptics';
import type { AppContext } from '../context';
import { openDailyCalendar } from './dailyCalendar';

const formatHours = (ms: number) => {
  const minutes = Math.ceil(ms / 60_000);
  return minutes >= 60 ? `${Math.floor(minutes / 60)} h ${String(minutes % 60).padStart(2, '0')}` : `${minutes} min`;
};

export function openQuestsSheet(ctx: AppContext): void {
  const sheet = document.createElement('div');
  sheet.className = 'dust-sheet quests-sheet';
  sheet.setAttribute('role', 'dialog');
  sheet.setAttribute('aria-label', 'Quêtes du jour');
  document.body.append(sheet);
  track('quests_viewed', {});

  function render(): void {
    const now = Date.now();
    const daily = currentQuests(ctx.player, now, ctx.tuning);
    const scroll = sheet.querySelector('.dust-panel')?.scrollTop ?? 0;
    if (!daily) {
      sheet.innerHTML = `<div class="dust-panel"><button type="button" class="dust-close" aria-label="Fermer">✕</button><h2>Quêtes du jour</h2><p class="muted">Termine d’abord tes premières huîtres.</p></div>`;
    } else {
      const claimedCount = daily.quests.filter((q) => q.claimed).length;
      sheet.innerHTML = `
        <div class="dust-panel">
          <button type="button" class="dust-close" aria-label="Fermer">✕</button>
          <h2>Quêtes du jour</h2>
          <p class="muted">Nouvelles quêtes dans ${formatHours(msUntilNextDay(now))}.</p>
          <button type="button" class="daily-row${canClaimDaily(ctx.player, now) ? ' ready' : ''}" data-action="calendar">
            <span class="flame" aria-hidden="true"></span>
            <span><b>${ctx.player.login.streak} jour${ctx.player.login.streak > 1 ? 's' : ''} d’affilée</b><small>Calendrier · jour ${(canClaimDaily(ctx.player, now) ? ctx.player.login.calendarIndex : (ctx.player.login.calendarIndex + CALENDAR.length - 1) % CALENDAR.length) + 1} sur ${CALENDAR.length}</small></span>
            <span class="chapter-action">${canClaimDaily(ctx.player, now) ? 'Récupérer' : 'Voir'}</span>
          </button>
          <ul class="quest-list">
            ${daily.quests
              .map((quest, index) => {
                const percent = Math.round((quest.progress / quest.goal) * 100);
                const action = quest.claimed
                  ? '<span class="quest-done">✓</span>'
                  : isClaimable(quest)
                    ? `<button type="button" class="dust-buy" data-claim="${index}">Récupérer</button>`
                    : `<span class="quest-count">${quest.progress}/${quest.goal}</span>`;
                return `<li class="${quest.claimed ? 'claimed' : isComplete(quest) ? 'complete' : ''}">
                  <div class="quest-main"><span>${questText(quest)}</span>
                    <div class="quest-bar"><i style="width:${percent}%"></i></div>
                    <small>+${ctx.tuning.questRewardDust} ✦ · +${ctx.tuning.questRewardReputation} réputation</small></div>
                  ${action}</li>`;
              })
              .join('')}
          </ul>
          <div class="quest-bonus${daily.bonusClaimed ? ' claimed' : ''}">
            <span class="dust-row-art dust-row-ecrin" aria-hidden="true"></span>
            <span><b>Les ${daily.quests.length} quêtes</b><small>${daily.bonusClaimed ? 'Écrin récupéré. À demain !' : `Un écrin en bonus · ${claimedCount}/${daily.quests.length}`}</small></span>
          </div>
        </div>`;
    }
    const panel = sheet.querySelector<HTMLElement>('.dust-panel')!;
    if (sheet.dataset.shown) panel.style.animation = 'none';
    sheet.dataset.shown = 'true';
    panel.scrollTop = scroll;
  }

  for (const type of ['pointerdown', 'pointerup'] as const) sheet.addEventListener(type, (event) => event.stopPropagation());
  sheet.addEventListener('click', (event) => {
    event.stopPropagation();
    const target = event.target as HTMLElement;
    if (target === sheet || target.closest('.dust-close')) {
      sheet.remove();
      ctx.showRewards();
      return;
    }
    if (target.closest('[data-action="calendar"]')) {
      openDailyCalendar(ctx, render);
      return;
    }
    const claim = target.closest<HTMLElement>('[data-claim]');
    if (claim) {
      const index = Number(claim.dataset.claim);
      const before = ctx.player;
      ctx.setPlayer(claimQuest(ctx.player, index, Date.now(), ctx.tuning));
      if (ctx.player !== before) {
        track('quest_claimed', { kind: before.quests?.quests[index]?.kind ?? '', bonus: ctx.player.ecrins > before.ecrins });
        chimeNotes('normal', ctx.player.ecrins > before.ecrins ? 3 : 1);
        hapticBurst(2, 80);
      }
      render();
    }
  });
  render();
}
