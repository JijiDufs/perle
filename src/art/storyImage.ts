// Image verticale 1080×1920 (format story) d'une carte, pour la partager (cahier §10).
// Une seule mise en page ; perles, bijoux et créations fournissent chacun une StorySpec.
import { metalById, RECIPES, type CraftedCard } from '../core/atelier';
import { pearlById } from '../core/catalog';
import { GRADE_LABELS } from '../core/expertise';
import { bottleMessage, findAlbum, findById, findRarity, type FindCard } from '../core/finds';
import { MARKS, traitsLabel, traitsOf } from '../core/pearlTraits';
import { GEM_CUTS, jewelRarity, jewelVariant, withVariant } from '../core/jewels';
import type { JewelCard, PearlCard } from '../core/player';
import { CARD_FRAMES, formatCarats, formatEuros, JEWEL_FRAMES, SANS, SERIF, serialLabel } from './cardStyle';
import { craftedJewel } from './atelier';
import { drawJewel, drawSparkles, jewelYOffset } from './jewel';
import { drawFind } from './finds';
import { drawGlow, drawPearl } from './pearl';

const W = 1080;
const H = 1920;

type Ctx = CanvasRenderingContext2D;

/** Ce qui change d'une carte à l'autre dans l'image. */
interface StorySpec {
  subtitle: string;
  title: string;
  rarity: string;
  frame: { colors: [string, string]; dark: boolean };
  glow: string | null;
  /** Fond de la zone d'illustration. */
  artBackground: 'nacre' | 'velvet';
  drawArt(c: Ctx, x: number, y: number, w: number, h: number): void;
  stats: [string, string][];
  flavor: string;
  flags: { text: string; tone: 'danger' | 'gold' }[];
  fine: string | null;
  /** Reflet holographique en diagonale. */
  holo: boolean;
}

function roundRect(c: Ctx, x: number, y: number, w: number, h: number, r: number): void {
  c.beginPath();
  c.moveTo(x + r, y);
  c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x, y, r);
  c.arcTo(x, y, x + w, y, r);
  c.closePath();
}

/** Écrit un texte sur plusieurs lignes ; renvoie la position y après la dernière ligne. */
function wrapText(c: Ctx, text: string, x: number, y: number, maxWidth: number, lineHeight: number): number {
  let line = '';
  for (const word of text.split(' ')) {
    const attempt = line ? `${line} ${word}` : word;
    if (c.measureText(attempt).width > maxWidth && line) {
      c.fillText(line, x, y);
      line = word;
      y += lineHeight;
    } else {
      line = attempt;
    }
  }
  if (line) c.fillText(line, x, y);
  return y + lineHeight;
}

/** Réduit la police jusqu'à ce que le texte tienne sur une ligne. */
function fitFont(c: Ctx, text: string, maxWidth: number, size: number, family: string, min = 36): void {
  let s = size;
  c.font = `${s}px ${family}`;
  while (s > min && c.measureText(text).width > maxWidth) {
    s -= 2;
    c.font = `${s}px ${family}`;
  }
}

async function render(spec: StorySpec): Promise<Blob> {
  await Promise.all([document.fonts.load(`64px ${SERIF}`), document.fonts.load(`600 32px ${SANS}`), document.fonts.load(`italic 32px ${SANS}`)]).catch(() => undefined);
  const canvas = document.createElement('canvas');
  canvas.width = W;
  canvas.height = H;
  const c = canvas.getContext('2d')!;

  // Fond : eau profonde (perles) ou nuit chaude (bijoux), reflets, halo.
  const bg = c.createLinearGradient(0, 0, 0, H);
  const [top, bottom, light] = spec.artBackground === 'velvet' ? ['#1a1520', '#0b090e', '255,220,170'] : ['#0c3b45', '#03161c', '170,240,235'];
  bg.addColorStop(0, top);
  bg.addColorStop(1, bottom);
  c.fillStyle = bg;
  c.fillRect(0, 0, W, H);
  [[0.2, 0.15], [0.85, 0.35], [0.3, 0.8], [0.75, 0.92]].forEach(([fx, fy]) => {
    const g = c.createRadialGradient(W * fx, H * fy, 0, W * fx, H * fy, 520);
    g.addColorStop(0, `rgba(${light},.08)`);
    g.addColorStop(1, `rgba(${light},0)`);
    c.fillStyle = g;
    c.fillRect(0, 0, W, H);
  });
  drawGlow(c, W / 2, H * 0.47, 900, spec.glow, 0.35);

  // En-tête.
  c.textAlign = 'center';
  c.fillStyle = '#e8f1f0';
  c.font = `96px ${SERIF}`;
  c.fillText('Pearl Inc.', W / 2, 200);
  c.font = `500 36px ${SANS}`;
  c.fillStyle = '#9db5b5';
  c.fillText(spec.subtitle, W / 2, 262);

  // Carte.
  const cw = 800;
  const ch = Math.round((cw * 88) / 63);
  const cx = (W - cw) / 2;
  const cy = 340;
  const pad = 48;
  c.save();
  c.shadowColor = 'rgba(0,0,0,.55)';
  c.shadowBlur = 60;
  c.shadowOffsetY = 24;
  roundRect(c, cx, cy, cw, ch, 44);
  const fg = c.createLinearGradient(cx, cy, cx + cw, cy + ch);
  fg.addColorStop(0, spec.frame.colors[0]);
  fg.addColorStop(1, spec.frame.colors[1]);
  c.fillStyle = fg;
  c.fill();
  c.restore();

  const ink = spec.frame.dark ? '#eef0ff' : '#1b2326';
  c.textAlign = 'left';
  c.fillStyle = ink;
  fitFont(c, spec.title, cw - pad * 2 - 140, 64, SERIF);
  c.fillText(spec.title, cx + pad, cy + 100);
  c.textAlign = 'right';
  c.font = `600 48px ${SANS}`;
  c.fillText(spec.rarity, cx + cw - pad, cy + 96);

  // Illustration.
  const ax = cx + 36;
  const ay = cy + 140;
  const aw = cw - 72;
  const ah = Math.round(ch * 0.52);
  c.save();
  roundRect(c, ax, ay, aw, ah, 28);
  c.clip();
  const fill = c.createRadialGradient(ax + aw / 2, ay + ah * 0.55, 10, ax + aw / 2, ay + ah * 0.55, aw * 0.75);
  const stops = spec.artBackground === 'velvet' ? ['#3a3550', '#1d1a28', '#0e0c14'] : ['#fdfaff', '#e7ddf2', '#a99fbd'];
  stops.forEach((col, i) => fill.addColorStop([0, 0.5, 1][i], col));
  c.fillStyle = fill;
  c.fillRect(ax, ay, aw, ah);
  spec.drawArt(c, ax, ay, aw, ah);
  c.restore();

  // Statistiques.
  const sy = ay + ah + 70;
  const colWidth = (cw - pad * 2) / spec.stats.length;
  c.textAlign = 'left';
  spec.stats.forEach(([label, value], i) => {
    const x = cx + pad + i * colWidth;
    c.globalAlpha = 0.7;
    c.font = `500 28px ${SANS}`;
    c.fillStyle = ink;
    c.fillText(label, x, sy);
    c.globalAlpha = 1;
    c.font = `700 38px ${SANS}`;
    c.fillText(value, x, sy + 48, colWidth - 12);
  });

  c.font = `italic 34px ${SANS}`;
  c.globalAlpha = 0.85;
  let y = spec.flavor ? wrapText(c, spec.flavor, cx + pad, sy + 130, cw - pad * 2, 46) : sy + 130;
  c.globalAlpha = 1;
  for (const flag of spec.flags) {
    c.font = `600 30px ${SANS}`;
    c.fillStyle = flag.tone === 'gold' ? (spec.frame.dark ? '#ffe08a' : '#7a5000') : spec.frame.dark ? '#ffb3a6' : '#8a2a1e';
    y = wrapText(c, flag.text, cx + pad, y, cw - pad * 2, 40);
  }
  if (spec.fine) {
    c.font = `500 24px ${SANS}`;
    c.fillStyle = ink;
    c.globalAlpha = 0.6;
    c.fillText(spec.fine, cx + pad, cy + ch - 36);
    c.globalAlpha = 1;
  }

  // Reflet holographique (bijoux rares, éclat parfait).
  if (spec.holo) {
    c.save();
    roundRect(c, cx, cy, cw, ch, 44);
    c.clip();
    c.globalCompositeOperation = 'overlay';
    const holo = c.createLinearGradient(cx, cy, cx + cw, cy + ch);
    [['rgba(255,209,232,0)', 0.25], ['rgba(255,209,232,.55)', 0.38], ['rgba(201,242,255,.55)', 0.46], ['rgba(255,242,196,.55)', 0.54], ['rgba(255,242,196,0)', 0.68]].forEach(([col, at]) =>
      holo.addColorStop(at as number, col as string),
    );
    c.fillStyle = holo;
    c.fillRect(cx, cy, cw, ch);
    c.restore();
  }

  // Pied de page.
  c.textAlign = 'center';
  c.fillStyle = '#e8f1f0';
  c.font = `52px ${SERIF}`;
  c.fillText('Et toi, tu vas trouver quoi ?', W / 2, H - 200);
  c.font = `600 34px ${SANS}`;
  c.fillStyle = '#e8be5a';
  c.fillText('PERLE · BÊTA', W / 2, H - 130);

  return new Promise((resolve, reject) => canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error('Image impossible'))), 'image/png'));
}

export function renderStoryImage(card: PearlCard): Promise<Blob> {
  const pearl = pearlById(card.pearlId);
  const traits = traitsOf(card);
  return render({
    subtitle: traits ? `${traitsLabel(traits)} · ${serialLabel(card.serial)}` : `Pêchée à La Crique · ${serialLabel(card.serial)}`,
    title: `${pearl.name}${card.cracked ? ' fêlée' : ''}`,
    rarity: pearl.rarity,
    frame: CARD_FRAMES[card.pearlId],
    glow: pearl.glow,
    artBackground: 'nacre',
    drawArt(c, x, y, w, h) {
      drawGlow(c, x + w / 2, y + h / 2, w * 0.55, pearl.glow, 0.55, false);
      drawPearl(c, x + w / 2, y + h / 2, w * (card.pearlId === 'giant' ? 0.27 : 0.19), pearl, card.cracked, traits);
    },
    stats: [
      ['Taille', `${card.sizeMm.toFixed(1)} mm`],
      ['Lustre', card.lustre],
      ['Valeur', String(card.value)],
      ['N°', serialLabel(card.serial)],
    ],
    flavor: pearl.flavor,
    flags: [
      ...(traits?.mark ? [{ text: `✦ Perle ${MARKS[traits.mark].label.toLowerCase()}`, tone: 'gold' as const }] : []),
      ...(card.cracked ? [{ text: 'Fêlée : valeur divisée par deux', tone: 'danger' as const }] : []),
    ],
    fine: null,
    holo: !!traits?.mark,
  });
}

export function renderJewelStoryImage(card: JewelCard): Promise<Blob> {
  const variant = card.variant ? jewelVariant(card.variant) : null;
  const jewel = withVariant(card.jewel, card.variant);
  const rarity = jewelRarity(jewel.rarityId);
  const glow = variant?.glow ?? rarity.glow;
  return render({
    subtitle: `${variant ? 'Variante rare' : jewel.cut ? `Taille ${GEM_CUTS[jewel.cut].label.toLowerCase()}` : 'Trouvé dans un écrin'} · ${serialLabel(card.serial)}`,
    title: jewel.name,
    rarity: rarity.rarity,
    frame: variant?.frame ?? JEWEL_FRAMES[rarity.tier],
    glow,
    artBackground: 'velvet',
    drawArt(c, x, y, w, h) {
      const cxArt = x + w / 2;
      const yOffset = jewelYOffset(jewel);
      drawGlow(c, cxArt, y + h / 2, w * 0.6, glow, 0.45);
      drawJewel(c, cxArt, y + h * yOffset, (w / 520) * 1.05, jewel);
      if (glow) drawSparkles(c, cxArt, y + h / 2, Math.max(rarity.tier, variant ? 4 : 0), glow, 1.3, card.perfect ? 1 : 0.7, w / 600);
    },
    stats: [
      ['Métal', jewel.metalName],
      ['Carats', formatCarats(jewel.carats)],
      ['Estimation', formatEuros(card.value)],
      ['N°', serialLabel(card.serial)],
    ],
    flavor: jewel.flavor,
    flags: [
      ...(variant ? [{ text: `Variante rare ${variant.label} : valeur ×2`, tone: 'gold' as const }] : card.perfect ? [{ text: 'Éclat parfait : valeur ×1,5', tone: 'gold' as const }] : []),
      ...(card.expertise && card.expertise.bonus > 0 ? [{ text: `✦ Certificat d’expertise : ${GRADE_LABELS[card.expertise.grade]} (+${Math.round(card.expertise.bonus * 100)} %)`, tone: 'gold' as const }] : []),
    ],
    fine: 'Estimation fictive',
    holo: rarity.tier >= 3 || card.perfect,
  });
}

export function renderCraftedStoryImage(card: CraftedCard): Promise<Blob> {
  const jewel = craftedJewel({ name: card.name, type: card.type, metal: card.metal }, card.pearlColors);
  const recipe = RECIPES.find((r) => r.id === card.recipeId);
  return render({
    subtitle: `Fait main à l’atelier · ${serialLabel(card.serial)}`,
    title: card.name,
    rarity: '★'.repeat(card.stars) + '☆'.repeat(5 - card.stars),
    frame: JEWEL_FRAMES[Math.min(JEWEL_FRAMES.length - 1, card.stars)],
    glow: '#fff1d6',
    artBackground: 'velvet',
    drawArt(c, x, y, w, h) {
      const cxArt = x + w / 2;
      const yOffset = jewelYOffset(jewel);
      drawGlow(c, cxArt, y + h / 2, w * 0.6, '#fff1d6', 0.4);
      drawJewel(c, cxArt, y + h * yOffset, (w / 520) * 1.05, jewel);
      if (card.stars >= 4) drawSparkles(c, cxArt, y + h / 2, card.stars - 1, '#fff1d6', 1.3, 1, w / 600);
    },
    stats: [
      ['Métal', metalById(card.metal).name],
      ['Perles', String(card.pearlIds.length)],
      ['Estimation', formatEuros(card.value)],
      ['N°', serialLabel(card.serial)],
    ],
    flavor: recipe?.flavor ?? '',
    flags: [{ text: card.setting === 'parfait' ? 'Fait main · sertissage parfait' : 'Fait main', tone: 'gold' }],
    fine: 'Estimation fictive',
    holo: card.stars >= 4,
  });
}

export function renderFindStoryImage(card: FindCard): Promise<Blob> {
  const find = findById(card.findId);
  return render({
    subtitle: `Trouvée dans une huître · ${serialLabel(card.serial)}`,
    title: find.name,
    rarity: findRarity(find),
    frame: JEWEL_FRAMES[find.tier],
    glow: find.glow,
    artBackground: 'nacre',
    drawArt(c, x, y, w, h) {
      drawGlow(c, x + w / 2, y + h / 2, w * 0.55, find.glow, 0.5, false);
      drawFind(c, x + w / 2, y + h / 2, w * 0.3, find, 1);
    },
    stats: [
      ['Album', findAlbum(find.album).name.replace(/^Le |^Les /, '')],
      ['Valeur', String(card.value)],
      ['N°', serialLabel(card.serial)],
    ],
    flavor: find.effect === 'message' ? `« ${bottleMessage(card.serial)} »` : find.flavor,
    flags: [],
    fine: null,
    holo: find.tier >= 3,
  });
}
