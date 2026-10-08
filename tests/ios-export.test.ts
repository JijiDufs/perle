// Pont entre le jeu web et l'app iOS (ios/PearlCore) : les catalogues et les réglages restent
// définis ici, une seule fois, et sont exportés en JSON pour le Swift. Des cas de référence
// (même graine → même huître, mêmes mesures → même lustre) vérifient que les deux moteurs
// donnent exactement les mêmes résultats.
// Ce test échoue si les fichiers exportés ne sont plus à jour : lancer `npm run ios:export`.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { APP_CONSUMABLES, APP_ECONOMY, APP_MISSING_PEARL_PRICE_BY_TIER, APP_MISSIONS, APP_RARE_MISSION_TIER, APP_SELL_DUST_BY_TIER, APP_SKINS } from '../src/core/appEconomy';
import { FIND_PROBABILITY, PEARLS } from '../src/core/catalog';
import { RARITY_SYMBOLS } from '../src/core/jewels';
import { INITIAL_DRAW_STATE } from '../src/core/draw';
import { FIND_TIER_WEIGHTS, FINDS, FIND_ALBUMS, BOTTLE_MESSAGES } from '../src/core/finds';
import { OpeningEngine, type OpeningSample } from '../src/core/opening';
import { createOyster } from '../src/core/oyster';
import { pearlValue } from '../src/core/player';
import { MARKS, OVERTONES, OVERTONE_WEIGHTS, SHAPES, SHAPE_WEIGHTS } from '../src/core/pearlTraits';
import { seededRng } from '../src/core/rng';
import { DEFAULT_TUNING } from '../src/tuning';
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
    economy: {
      ...APP_ECONOMY,
      sellDustByTier: APP_SELL_DUST_BY_TIER,
      missingPearlPriceByTier: APP_MISSING_PEARL_PRICE_BY_TIER,
      rareMissionTier: APP_RARE_MISSION_TIER,
      missions: APP_MISSIONS,
      skins: APP_SKINS,
      consumables: APP_CONSUMABLES,
    },
    markWeights: pairs(Object.fromEntries(Object.entries(MARKS).map(([id, mark]) => [id, mark.weight]))),
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

  return { rngSeed: 2026, rngValues, oysterSeed: 42, oysters, openings, thumbAngles, values };
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
