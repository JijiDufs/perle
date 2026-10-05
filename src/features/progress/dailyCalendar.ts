// Calendrier de connexion (cahier §15) : 7 cases, la case du jour à récupérer, la série de jours.
import { CALENDAR, canClaimDaily, claimDaily, jokerAvailable, streakIfClaimed, type CalendarReward } from '../../core/daily';
import { track } from '../../platform/analytics';
import { chimeNotes } from '../../platform/audio';
import { hapticBurst } from '../../platform/haptics';
import type { AppContext } from '../context';

const rewardText = (r: CalendarReward) =>
  [r.oysters ? `+${r.oysters} huîtres` : '', r.dust ? `+${r.dust} ✦` : '', r.ecrins ? `+${r.ecrins} écrin` : ''].filter(Boolean).join('<br>');

const rewardIcon = (r: CalendarReward) => (r.ecrins ? '<span class="cal-ecrin"></span>' : r.dust ? '<span class="cal-dust">✦</span>' : '<span class="cal-oyster"></span>');

/** Ouvre le calendrier. `onClose` est appelé à la fermeture. */
export function openDailyCalendar(ctx: AppContext, onClose: () => void = () => {}): void {
  const root = document.createElement('div');
  root.className = 'levelup daily';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-label', 'Calendrier de la semaine');
  document.body.append(root);
  track('daily_viewed', { canClaim: canClaimDaily(ctx.player, Date.now()) });

  function render(justClaimed: boolean): void {
    const now = Date.now();
    const { login } = ctx.player;
    const claimable = canClaimDaily(ctx.player, now);
    // Case du jour : celle à récupérer, ou celle qu'on vient de récupérer.
    const todayIndex = claimable ? login.calendarIndex : (login.calendarIndex + CALENDAR.length - 1) % CALENDAR.length;
    const preview = claimable ? streakIfClaimed(login, now) : { streak: login.streak, jokerUsed: false };
    root.innerHTML = `
      <div class="levelup-panel daily-panel">
        <p class="levelup-kicker">Rendez-vous du ponton</p>
        <h2 class="daily-title">${claimable ? 'Ta récompense du jour' : justClaimed ? 'À demain !' : 'Déjà récupérée aujourd’hui'}</h2>
        <ol class="cal">
          ${CALENDAR.map((reward, i) => {
            const done = claimable ? i < login.calendarIndex : i <= todayIndex;
            const today = i === todayIndex;
            return `<li style="--i:${i}" class="${done ? 'done' : ''}${today ? ' today' : ''}${reward.ecrins ? ' big' : ''}">
              <small>Jour ${i + 1}</small>${rewardIcon(reward)}<span>${rewardText(reward)}</span>${done && !(today && claimable) ? '<i class="cal-check">✓</i>' : ''}</li>`;
          }).join('')}
        </ol>
        <p class="daily-streak"><span class="flame" aria-hidden="true"></span><b>${preview.streak} jour${preview.streak > 1 ? 's' : ''}</b> d’affilée
          ${preview.jokerUsed ? '<em>· joker utilisé pour hier</em>' : jokerAvailable(login, now) ? '<em>· joker disponible</em>' : '<em>· joker déjà utilisé cette semaine</em>'}</p>
        <p class="levelup-next">Un jour manqué ? Le joker garde ta série, une fois par semaine.</p>
        <button type="button" class="levelup-button">${claimable ? 'Récupérer' : 'Fermer'}</button>
      </div>`;
    root.querySelector('.levelup-button')!.addEventListener('click', () => {
      if (claimable) {
        ctx.setPlayer(claimDaily(ctx.player, Date.now(), ctx.tuning));
        track('daily_claimed', { day: todayIndex + 1, streak: ctx.player.login.streak });
        chimeNotes('normal', CALENDAR[todayIndex].ecrins ? 3 : 2);
        hapticBurst(3, 90);
        render(true);
        return;
      }
      root.classList.add('closing');
      window.setTimeout(() => {
        root.remove();
        onClose();
      }, 220);
    });
  }
  for (const type of ['pointerdown', 'pointerup', 'click'] as const) root.addEventListener(type, (event) => event.stopPropagation());
  render(false);
}
