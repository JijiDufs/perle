import { describe, expect, it } from 'vitest';
import { PEARLS, type PearlId } from '../src/core/catalog';
import { meltOrdinaryDuplicates } from '../src/core/dust';
import { GEM_CUTS, gemCutsFor, JEWEL_RARITIES, jewelOfRarity, jewelTypesFor } from '../src/core/jewels';
import { oysterWith } from '../src/core/oyster';
import { defaultTraits, overtonesOf, rollTraits, shapesOf, traitsOf, traitsValueFactor } from '../src/core/pearlTraits';
import { INITIAL_PLAYER_STATE, pearlValue, recordOpening, type PearlCard, type PlayerState } from '../src/core/player';
import { seededRng } from '../src/core/rng';
import { DEFAULT_TUNING } from '../src/tuning';

const FINDABLE = PEARLS.filter((p) => p.id !== 'empty').map((p) => p.id as Exclude<PearlId, 'empty'>);

describe('perles uniques', () => {
  it('chaque perle tire une forme et un reflet qui lui sont possibles', () => {
    const rng = seededRng(21);
    for (const id of FINDABLE) {
      for (let i = 0; i < 300; i++) {
        const traits = rollTraits(id, rng, 0.04);
        expect(shapesOf(id)).toContain(traits.shape);
        expect(overtonesOf(id)).toContain(traits.overtone);
        expect(traits.seed).toBeGreaterThanOrEqual(0);
        expect(traits.seed).toBeLessThanOrEqual(1);
      }
    }
  });

  it('les marques rares suivent leur chance, et jamais pendant le tutoriel', () => {
    const rng = seededRng(5);
    const draws = 50_000;
    let marked = 0;
    for (let i = 0; i < draws; i++) if (rollTraits('white', rng, 0.04).mark) marked++;
    expect(marked / draws).toBeCloseTo(0.04, 2);
    for (let i = 0; i < 2000; i++) expect(oysterWith('rose', rng).traits!.mark).toBeNull();
  });

  it('la forme, le reflet et la marque changent la valeur', () => {
    const plain = { ...defaultTraits('black'), shape: 'presque-ronde' as const, overtone: 'aubergine' as const };
    const twin = { ...plain, mark: 'jumelle' as const };
    expect(pearlValue('black', 11, false, twin)).toBeGreaterThan(pearlValue('black', 11, false, plain));
    expect(traitsValueFactor({ ...plain, shape: 'ronde' })).toBeGreaterThan(traitsValueFactor({ ...plain, shape: 'cerclee' }));
  });

  it('la carte garde les traits de l’huître ; une ancienne carte reçoit ceux par défaut', () => {
    const traits = { shape: 'goutte' as const, overtone: 'vert-paon' as const, mark: 'etoile' as const, seed: 0.3 };
    const state: PlayerState = { ...INITIAL_PLAYER_STATE, oystersOpened: 10, currentOyster: { pearlId: 'black', sizeMm: 11, traits } };
    const { card } = recordOpening(state, { lustre: 'A', cracked: false }, 1000);
    expect(card!.traits).toEqual(traits);
    expect(card!.value).toBe(pearlValue('black', 11, false, traits));
    const old: PearlCard = { serial: 1, pearlId: 'rose', sizeMm: 7, value: 18, lustre: 'B', cracked: false, foundAt: 0 };
    expect(traitsOf(old)).toEqual(defaultTraits('rose'));
  });

  it('une perle marquée n’est jamais fondue en lot', () => {
    const card = (serial: number, value: number, mark: 'lune' | null): PearlCard => ({
      serial, pearlId: 'white', sizeMm: 6, value, lustre: 'B', cracked: false, foundAt: 0, traits: { ...defaultTraits('white'), mark },
    });
    const state: PlayerState = { ...INITIAL_PLAYER_STATE, cards: [card(1, 30, null), card(2, 10, 'lune'), card(3, 8, null)] };
    const after = meltOrdinaryDuplicates(state, DEFAULT_TUNING);
    expect(after.cards.map((c) => c.serial).sort()).toEqual([1, 2]);
  });
});

describe('bijoux variés', () => {
  it('chaque rareté donne des bijoux nommés, d’un type et d’une taille possibles', () => {
    const rng = seededRng(8);
    for (const rarity of JEWEL_RARITIES) {
      for (let i = 0; i < 300; i++) {
        const jewel = jewelOfRarity(rarity, rng);
        expect(jewel.name).not.toMatch(/undefined|null/);
        expect(jewel.value).toBeGreaterThan(0);
        expect(jewel.style).toBeTruthy();
        expect(jewelTypesFor(rarity.id)).toContain(jewel.type);
        if (jewel.cut && rarity.id !== 'legende') expect(gemCutsFor(rarity.id)).toContain(jewel.cut);
        if (rarity.id === 'argent' || rarity.id === 'or' || rarity.id === 'perles' || rarity.id === 'toc') expect(jewel.cut).toBeUndefined();
      }
    }
  });

  it('les bijoux à pierre prennent toutes les formes : pendentifs, broches, toutes les tailles', () => {
    const rng = seededRng(13);
    const types = new Set<string>();
    const cuts = new Set<string>();
    for (let i = 0; i < 5000; i++) {
      const jewel = jewelOfRarity(JEWEL_RARITIES.find((r) => r.id === 'diamant')!, rng);
      types.add(jewel.type);
      if (jewel.cut) cuts.add(jewel.cut);
    }
    for (const type of ['bague', 'collier', 'bracelet', 'boucles', 'pendentif', 'broche', 'diademe']) expect(types).toContain(type);
    expect([...cuts].sort()).toEqual(Object.keys(GEM_CUTS).sort());
  });

  it('un pendentif cœur porte une pierre en cœur, un pendentif goutte une pierre en poire', () => {
    const rng = seededRng(17);
    for (let i = 0; i < 3000; i++) {
      const jewel = jewelOfRarity(JEWEL_RARITIES.find((r) => r.id === 'rubis')!, rng);
      if (jewel.type === 'pendentif' && jewel.style === 'coeur') expect(jewel.cut).toBe('coeur');
      if (jewel.type === 'pendentif' && jewel.style === 'goutte') expect(jewel.cut).toBe('poire');
    }
  });
});
