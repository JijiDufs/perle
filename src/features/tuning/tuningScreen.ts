// Écran de réglages (debug) : ajuste le geste en direct, sans toucher au code.
import { PEARLS, type PearlId } from '../../core/catalog';
import { oysterWith } from '../../core/oyster';
import { INITIAL_PLAYER_STATE } from '../../core/player';
import { localEvents } from '../../platform/analytics';
import { isStandalone } from '../../platform/offline';
import { DEFAULT_TUNING, TUNING_FIELDS, type Tuning } from '../../tuning';
import type { AppContext } from '../context';

export function mountTuningScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen tuning-screen';

  const render = () => {
    const sliders = TUNING_FIELDS.map(
      (f) => `
      <label class="slider">
        <span class="slider-label">${f.label}</span>
        <span class="slider-value" data-value="${f.key}">${ctx.tuning[f.key]} ${f.unit}</span>
        <input type="range" min="${f.min}" max="${f.max}" step="${f.step}" value="${ctx.tuning[f.key]}" data-key="${f.key}" />
      </label>`,
    ).join('');

    const pearlOptions = PEARLS.map((p) => `<option value="${p.id}">${p.name} (${p.rarity})</option>`).join('');

    root.innerHTML = `
      <h2>Réglages du geste</h2>
      <p class="muted">Les changements s'appliquent à la prochaine huître.</p>
      ${sliders}
      <button data-action="reset-tuning">Revenir aux valeurs par défaut</button>

      <h2>Affichage</h2>
      <label class="toggle"><input type="checkbox" data-action="hud" ${ctx.settings.showHud ? 'checked' : ''}/> Afficher la jauge (angle, vitesse, zone fragile)</label>
      <label class="toggle"><input type="checkbox" data-action="sound" ${ctx.settings.sound ? 'checked' : ''}/> Son</label>

      <h2>Installer l'app</h2>
      <p class="muted">${isStandalone()
        ? 'Pearl Inc. est installé sur ton écran d’accueil. Le jeu marche aussi sans réseau.'
        : 'Sur iPhone, dans Safari : touche <strong>Partager</strong> puis <strong>« Sur l’écran d’accueil »</strong>. Pearl Inc. s’ouvrira en plein écran et marchera sans réseau.'}</p>

      <h2>Test</h2>
      <label class="toggle">Forcer la prochaine huître :
        <select data-action="force"><option value="">—</option>${pearlOptions}</select>
      </label>
      <p class="muted">${localEvents().length} événements de mesure enregistrés sur cet appareil.</p>
      <button data-action="fill-stock">Remplir le stock d’huîtres</button>
      <button data-action="empty-stock">Vider le stock d’huîtres</button>
      <button data-action="add-dust">Ajouter 200 ✦ de poussière d’or</button>
      <button class="danger" data-action="reset-player">Effacer ma collection</button>
    `;

    root.querySelectorAll<HTMLInputElement>('input[type=range]').forEach((input) => {
      input.addEventListener('input', () => {
        const key = input.dataset.key as keyof Tuning;
        const field = TUNING_FIELDS.find((f) => f.key === key)!;
        ctx.setTuning({ ...ctx.tuning, [key]: Number(input.value) });
        root.querySelector(`[data-value="${key}"]`)!.textContent = `${input.value} ${field.unit}`;
      });
    });
  };

  root.addEventListener('click', (event) => {
    const action = (event.target as HTMLElement).dataset.action;
    if (action === 'reset-tuning') {
      ctx.setTuning({ ...DEFAULT_TUNING });
      render();
    } else if (action === 'fill-stock' || action === 'empty-stock') {
      const count = action === 'fill-stock' ? ctx.tuning.oysterStockMax : 0;
      ctx.setPlayer({ ...ctx.player, stock: { count, lastRefillAt: Date.now() } });
    } else if (action === 'add-dust') {
      ctx.setPlayer({ ...ctx.player, dust: ctx.player.dust + 200 });
    } else if (action === 'reset-player' && confirm('Effacer toute la collection de cet appareil ?')) {
      ctx.setPlayer(INITIAL_PLAYER_STATE);
      render();
    }
  });
  root.addEventListener('change', (event) => {
    const target = event.target as HTMLInputElement | HTMLSelectElement;
    if (target.dataset.action === 'hud') {
      ctx.setSettings({ ...ctx.settings, showHud: (target as HTMLInputElement).checked });
    } else if (target.dataset.action === 'sound') {
      ctx.setSettings({ ...ctx.settings, sound: (target as HTMLInputElement).checked });
    } else if (target.dataset.action === 'force' && target.value) {
      ctx.setPlayer({ ...ctx.player, currentOyster: oysterWith(target.value as PearlId, ctx.rng) });
    }
  });

  render();
  return () => {};
}
