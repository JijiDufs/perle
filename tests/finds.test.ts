import { describe, expect, it } from 'vitest';
import { ACHIEVEMENTS } from '../src/core/achievements';
import { createOyster } from '../src/core/oyster';
import { albumProgress, bottleMessage, FIND_ALBUMS, findById, FINDS, findShare, rollFind } from '../src/core/finds';
import { INITIAL_DRAW_STATE } from '../src/core/draw';
import { INITIAL_PLAYER_STATE, recordOpening, type PlayerState } from '../src/core/player';
import { seededRng } from '../src/core/rng';
import { TUTORIAL_PEARLS } from '../src/core/tutorial';
import { DEFAULT_TUNING } from '../src/tuning';

/** Joueur sorti du tutoriel, avec une trouvaille dans l'huître en cours. */
function withFind(findId: string, state: Partial<PlayerState> = {}): PlayerState {
  return { ...INITIAL_PLAYER_STATE, oystersOpened: TUTORIAL_PEARLS.length + 1, ...state, currentOyster: { pearlId: 'empty', sizeMm: 0, findId } };
}

describe('catalogue des trouvailles', () => {
  it('des identifiants uniques, des raretés de ◆ à ★★, chaque album rempli', () => {
    expect(new Set(FINDS.map((f) => f.id)).size).toBe(FINDS.length);
    for (const find of FINDS) expect(find.tier).toBeGreaterThanOrEqual(1);
    for (const find of FINDS) expect(find.tier).toBeLessThanOrEqual(5);
    for (const album of FIND_ALBUMS) expect(FINDS.some((f) => f.album === album.id)).toBe(true);
  });

  it('les parts de tirage font 100 %, et une trouvaille plus rare est moins probable', () => {
    expect(FINDS.reduce((sum, f) => sum + findShare(f), 0)).toBeCloseTo(1, 10);
    expect(findShare(findById('tong'))).toBeGreaterThan(findShare(findById('dentier')));
    expect(findShare(findById('dentier'))).toBeGreaterThan(findShare(findById('coeur-ocean')));
  });

  it('le tirage suit les parts', () => {
    const rng = seededRng(9);
    const counts = new Map<string, number>();
    const draws = 100_000;
    for (let i = 0; i < draws; i++) {
      const id = rollFind(rng).id;
      counts.set(id, (counts.get(id) ?? 0) + 1);
    }
    for (const find of FINDS) expect((counts.get(find.id) ?? 0) / draws).toBeCloseTo(findShare(find), 2);
  });

  it('une huître à trouvaille n’a pas de perle', () => {
    const rng = seededRng(4);
    for (let i = 0; i < 2000; i++) {
      const { oyster } = createOyster(INITIAL_DRAW_STATE, rng, DEFAULT_TUNING);
      if (oyster.findId) {
        expect(oyster.pearlId).toBe('empty');
        expect(oyster.sizeMm).toBe(0);
        return;
      }
    }
    throw new Error('aucune trouvaille en 2000 huîtres');
  });

  it('chaque bouteille porte un message', () => {
    for (let serial = 0; serial < 20; serial++) expect(bottleMessage(serial).length).toBeGreaterThan(0);
  });
});

describe('ouvrir une trouvaille', () => {
  it('crée une carte numérotée de trouvaille, pas de perle, et ne compte pas comme huître vide', () => {
    const { state, card, find } = recordOpening(withFind('tong', { nextSerial: 7 }), { lustre: 'A', cracked: true }, 1000);
    expect(card).toBeNull();
    expect(find).toMatchObject({ serial: 7, findId: 'tong', value: findById('tong').value });
    expect(state.findCards).toHaveLength(1);
    expect(state.cards).toHaveLength(0);
    expect(state.nextSerial).toBe(8);
    expect(state.stats.emptyOysters).toBe(0);
    expect(state.stats.crackFreeStreak).toBe(1);
  });

  it('une première trouvaille rapporte la réputation de découverte, pas la suivante', () => {
    const first = recordOpening(withFind('dentier'), { lustre: 'B', cracked: false }, 1000).state;
    const second = recordOpening({ ...first, currentOyster: { pearlId: 'empty', sizeMm: 0, findId: 'dentier' } }, { lustre: 'B', cracked: false }, 2000).state;
    const gainFirst = first.reputation;
    expect(second.reputation - first.reputation).toBe(gainFirst - DEFAULT_TUNING.repDiscovery - DEFAULT_TUNING.achievementReputation);
  });

  it('la pièce d’or donne de la poussière d’or, la clé d’épave un écrin', () => {
    const coin = recordOpening(withFind('piece-or', { dust: 3 }), { lustre: 'B', cracked: false }, 1000).state;
    expect(coin.dust).toBeGreaterThanOrEqual(3 + DEFAULT_TUNING.findCoinDust);
    const key = recordOpening(withFind('cle-epave', { ecrins: 0 }), { lustre: 'B', cracked: false }, 1000).state;
    expect(key.ecrins).toBeGreaterThanOrEqual(DEFAULT_TUNING.findKeyEcrins);
  });

  it('compléter un album donne le succès, son titre et un écrin', () => {
    const tresors = FINDS.filter((f) => f.album === 'tresors');
    const owned = tresors.slice(1).map((f, i) => ({ serial: i + 1, findId: f.id, value: f.value, foundAt: 0 }));
    const before = withFind(tresors[0].id, { findCards: owned, ecrins: 0, nextSerial: 100 });
    expect(albumProgress(before.findCards, 'tresors')).toEqual([tresors.length - 1, tresors.length]);
    const after = recordOpening(before, { lustre: 'B', cracked: false }, 1000).state;
    expect(albumProgress(after.findCards, 'tresors')).toEqual([tresors.length, tresors.length]);
    expect(after.achievements['album-tresors']).toBe(1000);
    expect(ACHIEVEMENTS.find((a) => a.id === 'album-tresors')!.title).toBeTruthy();
    const keyEcrins = tresors[0].effect === 'ecrin' ? DEFAULT_TUNING.findKeyEcrins : 0;
    expect(after.ecrins).toBe(keyEcrins + DEFAULT_TUNING.albumRewardEcrins);
  });
});
