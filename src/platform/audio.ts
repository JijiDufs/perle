// Sons générés (Web Audio), repris du prototype Duo : aucun fichier audio à charger.
// Le navigateur n'autorise le son qu'après un premier geste : unlockAudio() est appelé au premier appui.
import type { PearlType } from '../core/catalog';

let context: AudioContext | null = null;
let muted = false;

export function setMuted(value: boolean): void {
  muted = value;
}

export function unlockAudio(): void {
  try {
    if (!context) {
      const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      context = new Ctor();
    }
    if (context.state === 'suspended') void context.resume();
  } catch {
    // Pas de son disponible : le jeu reste jouable.
  }
}

/** Bruit filtré bref : craquement, pop, fêlure. */
export function noise(duration: number, frequency: number, gain: number): void {
  if (!context || muted) return;
  const length = Math.max(1, Math.floor(context.sampleRate * duration));
  const buffer = context.createBuffer(1, length, context.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, 3);
  const source = context.createBufferSource();
  source.buffer = buffer;
  const filter = context.createBiquadFilter();
  filter.type = 'bandpass';
  filter.frequency.value = frequency;
  filter.Q.value = 2.5;
  const volume = context.createGain();
  volume.gain.value = gain;
  source.connect(filter);
  filter.connect(volume);
  volume.connect(context.destination);
  source.start();
}

/** Carillon de révélation : plus la perle est rare, plus il monte. La maudite grince. */
export function chime(pearl: PearlType): void {
  chimeNotes(pearl.id === 'cursed' ? 'cursed' : !pearl.glow ? 'empty' : 'normal', pearl.revealTier);
}

/** Carillon générique : `level` 0 à 3 ajoute des notes ; `cursed` grince ; `empty` descend. */
export function chimeNotes(style: 'normal' | 'cursed' | 'empty', level: number): void {
  if (!context || muted) return;
  const cursed = style === 'cursed';
  const notes = cursed ? [220, 233, 311, 207] : style === 'empty' ? [330, 262] : [523, 659, 784, 988, 1175, 1568].slice(0, 3 + level);
  notes.forEach((frequency, i) => {
    const oscillator = context!.createOscillator();
    const volume = context!.createGain();
    const t = context!.currentTime + i * 0.09;
    oscillator.type = cursed ? 'sawtooth' : 'sine';
    oscillator.frequency.value = frequency;
    volume.gain.setValueAtTime(0, t);
    volume.gain.linearRampToValueAtTime(cursed ? 0.05 : 0.12, t + 0.02);
    volume.gain.exponentialRampToValueAtTime(0.0001, t + 0.9);
    oscillator.connect(volume);
    volume.connect(context!.destination);
    oscillator.start(t);
    oscillator.stop(t + 1);
  });
}

/** Tintement cristallin : éclat parfait. */
export function ding(): void {
  if (!context || muted) return;
  [1568, 2093, 2637].forEach((frequency, i) => {
    const oscillator = context!.createOscillator();
    const volume = context!.createGain();
    const t = context!.currentTime + i * 0.06;
    oscillator.type = 'sine';
    oscillator.frequency.value = frequency;
    volume.gain.setValueAtTime(0, t);
    volume.gain.linearRampToValueAtTime(0.08, t + 0.01);
    volume.gain.exponentialRampToValueAtTime(0.0001, t + 0.7);
    oscillator.connect(volume);
    volume.connect(context!.destination);
    oscillator.start(t);
    oscillator.stop(t + 0.8);
  });
}

/** « Pouet » : bijou en toc. */
export function pouet(): void {
  if (!context || muted) return;
  const oscillator = context.createOscillator();
  const volume = context.createGain();
  const t = context.currentTime;
  oscillator.type = 'square';
  oscillator.frequency.setValueAtTime(420, t);
  oscillator.frequency.exponentialRampToValueAtTime(140, t + 0.45);
  volume.gain.setValueAtTime(0.06, t);
  volume.gain.exponentialRampToValueAtTime(0.0001, t + 0.5);
  oscillator.connect(volume);
  volume.connect(context.destination);
  oscillator.start(t);
  oscillator.stop(t + 0.55);
}
