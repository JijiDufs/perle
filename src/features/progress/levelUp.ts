// Célébration de montée de niveau : récompenses, nouveau rang, prochain horizon (cahier §9 et §15).
import { levelReward, nextMilestone, nextRank, rankForLevel } from '../../core/levels';
import { chimeNotes } from '../../platform/audio';
import { hapticBurst } from '../../platform/haptics';
import type { Tuning } from '../../tuning';

/** Montre les niveaux franchis (de `from` exclu à `to` inclus) en une seule célébration, et les lettres qui attendent. */
export function showLevelUp(from: number, to: number, tuning: Tuning, unreadLetters: number, onClose: () => void): void {
  let oysters = 0;
  let dust = 0;
  let ecrins = 0;
  let newRank = null as ReturnType<typeof levelReward>['rank'];
  for (let level = from + 1; level <= to; level++) {
    const reward = levelReward(level, tuning);
    oysters += reward.oysters;
    dust += reward.dust;
    ecrins += reward.ecrins;
    newRank = reward.rank ?? newRank;
  }
  const rank = rankForLevel(to);
  const upcoming = nextMilestone(to);
  const following = nextRank(to);
  const plural = (n: number, one: string, many: string) => `${n} ${n > 1 ? many : one}`;

  const root = document.createElement('div');
  root.className = 'levelup';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-label', `Niveau ${to}`);
  root.innerHTML = `
    <div class="levelup-rays" aria-hidden="true"></div>
    <div class="levelup-panel">
      <p class="levelup-kicker">${newRank ? 'Nouveau rang' : 'Niveau supérieur'}</p>
      <div class="levelup-level"><span>Niveau</span><strong>${to}</strong></div>
      <p class="levelup-rank">${newRank ? `Te voilà <b>${newRank.title}</b>` : rank.title}</p>
      ${newRank ? `<p class="levelup-opens">${newRank.opens} <em>(à venir dans le jeu)</em></p>` : ''}
      <ul class="levelup-rewards">
        ${oysters ? `<li><b>+${oysters}</b> huîtres</li>` : ''}
        ${dust ? `<li><b>+${dust} ✦</b> poussière d’or</li>` : ''}
        ${ecrins ? `<li class="gold"><b>+${plural(ecrins, 'écrin', 'écrins')}</b></li>` : ''}
      </ul>
      ${
        upcoming
          ? `<p class="levelup-next">Prochain déblocage · niveau ${upcoming.level} : ${upcoming.label}${upcoming.available ? '' : ' <em>(à venir)</em>'}</p>`
          : ''
      }
      ${unreadLetters ? `<p class="levelup-letter">✉ ${unreadLetters > 1 ? `${unreadLetters} lettres de grand-mère t’attendent` : 'Une lettre de grand-mère t’attend'} dans la Maison</p>` : ''}
      ${following ? `<p class="levelup-next">Rang suivant · ${following.title} au niveau ${following.level}</p>` : ''}
      <button type="button" class="levelup-button">Continuer</button>
    </div>`;
  for (const type of ['pointerdown', 'pointerup', 'click'] as const) root.addEventListener(type, (event) => event.stopPropagation());
  root.querySelector('.levelup-button')!.addEventListener('click', () => {
    root.classList.add('closing');
    window.setTimeout(() => {
      root.remove();
      onClose();
    }, 220);
  });
  document.body.append(root);
  chimeNotes('normal', 3);
  hapticBurst(newRank ? 5 : 3, 110);
}
