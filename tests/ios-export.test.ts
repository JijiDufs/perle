// Pont entre le jeu web et l'app iOS (ios/PearlCore) : les catalogues et les réglages restent
// définis ici, une seule fois, et sont exportés en JSON pour le Swift. Des cas de référence
// (même graine → même huître, mêmes mesures → même lustre) vérifient que les deux moteurs
// donnent exactement les mêmes résultats.
// Ce test échoue si les fichiers exportés ne sont plus à jour : lancer `npm run ios:export`.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { ACHIEVEMENTS } from '../src/core/achievements';
import { APP_ACHIEVEMENT_REWARDS, APP_ACHIEVEMENTS, APP_CALENDAR, APP_CONSUMABLES, APP_ECONOMY, APP_FISH_THIEF, APP_LEVELS, APP_MISSIONS, APP_RARE_MISSION_TIER, APP_SELL_DUST_BY_TIER, APP_SKINS } from '../src/core/appEconomy';
import { FIND_PROBABILITY, PEARLS } from '../src/core/catalog';
import { INITIAL_LOGIN, streakIfClaimed, type LoginState } from '../src/core/daily';
import { CATALOG_ENGLISH } from '../src/core/catalogEnglish';
import { RARITY_SYMBOLS } from '../src/core/jewels';
import { levelFromXp, RANKS, reputationFor, xpToNext } from '../src/core/levels';
import { INITIAL_DRAW_STATE } from '../src/core/draw';
import { FIND_TIER_WEIGHTS, FINDS, FIND_ALBUMS, BOTTLE_MESSAGES } from '../src/core/finds';
import { OpeningEngine, type OpeningSample } from '../src/core/opening';
import { createOyster, oysterWith } from '../src/core/oyster';
import { rarityRank, sortCards } from '../src/core/collection';
import { pearlValue, type PearlCard, type PlayerState } from '../src/core/player';
import { INITIAL_STATS } from '../src/core/progression';
import { MARKS, OVERTONES, OVERTONE_WEIGHTS, SHAPES, SHAPE_WEIGHTS } from '../src/core/pearlTraits';
import { seededRng } from '../src/core/rng';
import { scriptedPearl, TUTORIAL_PEARLS } from '../src/core/tutorial';
import { APP_AUDIO, DEFAULT_TUNING } from '../src/tuning';
import { thumbDistanceToAngle } from '../src/input/thumb';

const ROOT = resolve(__dirname, '..');
const CATALOG_PATH = resolve(ROOT, 'ios/PearlCore/Sources/PearlCore/Resources/catalog.json');
const PARITY_PATH = resolve(ROOT, 'ios/PearlCore/Tests/PearlCoreTests/Resources/parity.json');
const UPDATE = process.env.UPDATE_IOS_FIXTURES === '1';

/** Les poids gardent leur ordre (il compte pour le tirage) : on les exporte en liste de paires. */
const pairs = (weights: Readonly<Record<string, number | undefined>>) =>
  Object.entries(weights).map(([id, weight]) => ({ id, weight: weight ?? 0 }));
const perPearl = (table: Readonly<Record<string, Readonly<Record<string, number | undefined>>>>) =>
  Object.fromEntries(Object.entries(table).map(([pearl, weights]) => [pearl, pairs(weights)]));

function catalog() {
  return {
    tuning: DEFAULT_TUNING,
    audio: APP_AUDIO,
    pearls: PEARLS,
    findProbability: FIND_PROBABILITY,
    findTierWeights: pairs(FIND_TIER_WEIGHTS),
    findAlbums: FIND_ALBUMS,
    finds: FINDS,
    bottleMessages: BOTTLE_MESSAGES,
    shapes: SHAPES,
    overtones: OVERTONES,
    marks: MARKS,
    shapeWeights: perPearl(SHAPE_WEIGHTS),
    overtoneWeights: perPearl(OVERTONE_WEIGHTS),
    raritySymbols: RARITY_SYMBOLS,
    tutorialPearls: TUTORIAL_PEARLS,
    // Ce que le rang ouvre (`opens`) n'est pas exporté : l'app ne parle pas des fonctions à venir (règle Apple 2.1).
    ranks: RANKS.map(({ id, title, level }) => ({ id, title, level })),
    economy: {
      ...APP_ECONOMY,
      sellDustByTier: APP_SELL_DUST_BY_TIER,
      rareMissionTier: APP_RARE_MISSION_TIER,
      missions: APP_MISSIONS,
      skins: APP_SKINS,
      consumables: APP_CONSUMABLES,
      calendar: APP_CALENDAR,
      fishThief: APP_FISH_THIEF,
      levels: APP_LEVELS,
      achievements: APP_ACHIEVEMENTS,
      achievementRewards: APP_ACHIEVEMENT_REWARDS,
    },
    markWeights: pairs(Object.fromEntries(Object.entries(MARKS).map(([id, mark]) => [id, mark.weight]))),
    english: CATALOG_ENGLISH,
  };
}

/** Une ouverture au pouce : distances (pt) dans le temps → mesures d'angle. */
function thumbSamples(distances: number[], stepMs: number): OpeningSample[] {
  return distances.map((distance, i) => ({ angle: thumbDistanceToAngle(distance, DEFAULT_TUNING), time: i * stepMs }));
}

function openingCase(name: string, samples: OpeningSample[], crackProtected = false) {
  const engine = new OpeningEngine(DEFAULT_TUNING, crackProtected);
  const events = samples.map((sample) => engine.push(sample).map((event) => event.type));
  return { name, crackProtected, samples, events, phase: engine.phase, cracked: engine.cracked, lustre: engine.lustre };
}

const ramp = (from: number, to: number, steps: number) => Array.from({ length: steps + 1 }, (_, i) => from + ((to - from) * i) / steps);

function parity() {
  const rng = seededRng(2026);
  const rngValues = Array.from({ length: 20 }, () => rng());

  // 400 huîtres d'affilée, garantie comprise.
  const oysterRng = seededRng(42);
  let drawState = INITIAL_DRAW_STATE;
  const oysters = Array.from({ length: 400 }, () => {
    const result = createOyster(drawState, oysterRng, DEFAULT_TUNING);
    drawState = result.drawState;
    return { ...result.oyster, sinceGoldenOrBetter: drawState.sinceGoldenOrBetter };
  });

  const openings = [
    openingCase('lent et régulier', thumbSamples(ramp(0, 330, 110), 16)),
    openingCase('trop vite', thumbSamples(ramp(0, 330, 12), 16)),
    openingCase('trop vite mais protégée', thumbSamples(ramp(0, 330, 12), 16), true),
    openingCase('irrégulier', thumbSamples([0, 20, 40, 60, 75, 80, 82, 95, 130, 135, 140, 170, 180, 220, 230, 260, 300, 330], 33)),
    openingCase('lâché avant le pop', thumbSamples([0, 10, 30, 50, 40], 16)),
  ];

  const thumbAngles = [-10, 0, 10, 35, 69.9, 70, 71, 150, 200, 330, 400].map((distance) => ({
    distance,
    angle: thumbDistanceToAngle(distance, DEFAULT_TUNING),
  }));

  // Valeur des cartes : taille, traits et fêlure (une sur trois).
  const values = oysters.slice(0, 80).map((oyster, i) => ({
    pearlId: oyster.pearlId,
    sizeMm: oyster.sizeMm,
    cracked: i % 3 === 0,
    traits: oyster.traits ?? null,
    value: pearlValue(oyster.pearlId, oyster.sizeMm, i % 3 === 0, oyster.traits),
  }));

  // Premières minutes : les huîtres écrites à l'avance, puis le tirage normal (même générateur).
  const tutorialRng = seededRng(7);
  let tutorialDraw = INITIAL_DRAW_STATE;
  const tutorialOysters = Array.from({ length: TUTORIAL_PEARLS.length + 4 }, (_, opened) => {
    const scripted = scriptedPearl(opened);
    if (scripted) {
      const goldenOrBetter = PEARLS.find((pearl) => pearl.id === scripted)?.goldenOrBetter ?? false;
      tutorialDraw = { sinceGoldenOrBetter: goldenOrBetter ? 0 : tutorialDraw.sinceGoldenOrBetter + 1 };
      return { ...oysterWith(scripted, tutorialRng), sinceGoldenOrBetter: tutorialDraw.sinceGoldenOrBetter };
    }
    const result = createOyster(tutorialDraw, tutorialRng, DEFAULT_TUNING);
    tutorialDraw = result.drawState;
    return { ...result.oyster, sinceGoldenOrBetter: tutorialDraw.sinceGoldenOrBetter };
  });

  // Calendrier de connexion : série et joker jour après jour (même règle que la webapp, src/core/daily.ts).
  // Midi heure locale : dayKey(now) donne bien le jour voulu.
  const noon = (day: string) => {
    const [y, m, d] = day.split('-').map(Number);
    return new Date(y, m - 1, d, 12).getTime();
  };
  let login: LoginState = INITIAL_LOGIN;
  const loginDays = ['2026-10-01', '2026-10-02', '2026-10-03', '2026-10-05', '2026-10-06', '2026-10-09', '2026-10-10',
    '2026-10-12', '2026-10-14', '2026-10-15', '2026-10-31', '2026-11-01', '2026-12-31', '2027-01-01', '2027-01-03'];
  const logins = loginDays.map((day) => {
    const { streak, jokerUsed } = streakIfClaimed(login, noon(day));
    login = {
      lastClaimDay: day,
      calendarIndex: (login.calendarIndex + 1) % APP_CALENDAR.length,
      streak,
      bestStreak: Math.max(login.bestStreak, streak),
      jokerUsedDay: jokerUsed ? day : login.jokerUsedDay,
    };
    return { day, ...login };
  });

  // Niveaux de l'app : courbe accélérée au début (APP_LEVELS), réputation de chaque huître et trouvaille.
  const fast = APP_LEVELS.fastStart;
  const xpToNextLevels = Array.from({ length: 60 }, (_, i) => xpToNext(i + 1, DEFAULT_TUNING, fast));
  const levelProgress = [0, 1, 37, 38, 94, 95, 500, 1756, 1757, 5000, 20000, 106000, 1e9].map((xp) => ({ xp, ...levelFromXp(xp, DEFAULT_TUNING, fast) }));
  const lustres = ['S', 'A', 'B', 'C'] as const;
  const reputations = [
    ...PEARLS.flatMap((pearl, i) => [
      { pearlId: pearl.id, lustre: lustres[i % 4], cracked: false, discovery: true },
      { pearlId: pearl.id, lustre: lustres[(i + 1) % 4], cracked: i % 2 === 0, discovery: false },
      { pearlId: pearl.id, lustre: 'S' as const, cracked: true, discovery: false },
    ]).map((event) => ({ kind: 'oyster', ...event, reputation: reputationFor({ kind: 'oyster', ...event }, DEFAULT_TUNING) })),
    ...[1, 2, 3, 4, 5].flatMap((tier) => [true, false].map((discovery) => ({
      kind: 'find', tier, discovery, reputation: reputationFor({ kind: 'find', tier, discovery }, DEFAULT_TUNING),
    }))),
  ];

  // Tri de la collection : les cartes des valeurs ci-dessus, plus dix doublons de même valeur (départage par la plus récente).
  const sortable = values.filter((v) => v.pearlId !== 'empty').map((v, i) => ({ serial: i + 1, pearlId: v.pearlId, value: v.value }));
  const collectionCards = [...sortable, ...sortable.slice(0, 10).map((card, i) => ({ ...card, serial: 200 + i }))];
  const cardSorts = (['rarity', 'recent', 'value'] as const).map((sort) => ({
    sort,
    serials: sortCards(collectionCards as unknown as PearlCard[], sort).map((card) => card.serial),
  }));
  const rarityRanks = PEARLS.map((pearl) => ({ pearlId: pearl.id, rank: rarityRank(pearl.id) }));

  // Succès repris de la webapp : leur avancement (src/core/achievements.ts) sur des parties de plus en plus longues,
  // faites des huîtres ci-dessus (la dernière avec toutes les trouvailles). Statistiques et série de jours inventées.
  const achievementStates = [0, 3, 30, 150, 400, 400].map((n, i, all) => {
    const opened = oysters.slice(0, n);
    const pearlCards = opened.filter((o) => !o.findId && o.pearlId !== 'empty').map((o) => ({ pearlId: o.pearlId, traits: o.traits ?? null }));
    const findIds = i === all.length - 1 ? FINDS.map((f) => f.id) : opened.flatMap((o) => (o.findId ? [o.findId] : []));
    const stats = {
      emptyOysters: opened.filter((o) => o.pearlId === 'empty' && !o.findId).length,
      lustreS: Math.floor(n / 9),
      bestCrackFreeStreak: Math.floor(n / 7),
      sold: Math.floor(n / 15),
    };
    const bestStreak = Math.floor(n / 11);
    const web = {
      cards: pearlCards.map((c) => ({ pearlId: c.pearlId, traits: c.traits ?? undefined })),
      findCards: findIds.map((findId) => ({ findId })),
      oystersOpened: n,
      stats: { ...INITIAL_STATS, emptyOysters: stats.emptyOysters, lustreS: stats.lustreS, bestCrackFreeStreak: stats.bestCrackFreeStreak, melted: stats.sold },
      login: { ...INITIAL_LOGIN, bestStreak },
      jewelCards: [],
      craftedCards: [],
    } as unknown as PlayerState;
    const progress = Object.fromEntries(APP_ACHIEVEMENTS.flatMap((a) => {
      const achievement = ACHIEVEMENTS.find((w) => w.id === a.id);
      return achievement ? [[a.id, achievement.progress(web)]] : [];
    }));
    return { oystersOpened: n, pearlCards, findIds, stats, bestStreak, progress };
  });

  return {
    rngSeed: 2026, rngValues, oysterSeed: 42, oysters, tutorialSeed: 7, tutorialOysters, openings, thumbAngles, values, logins,
    xpToNextLevels, levelProgress, reputations, collectionCards, cardSorts, rarityRanks, achievementStates,
  };
}

function check(path: string, data: unknown) {
  const json = `${JSON.stringify(data, null, 2)}\n`;
  if (UPDATE) writeFileSync(path, json);
  expect(existsSync(path), `${path} manque : lancer npm run ios:export`).toBe(true);
  expect(readFileSync(path, 'utf8'), 'Fichier iOS périmé : lancer npm run ios:export').toBe(json);
}

describe('export vers l’app iOS', () => {
  it('catalogues et réglages à jour', () => check(CATALOG_PATH, catalog()));
  it('cas de référence à jour', () => check(PARITY_PATH, parity()));
});
