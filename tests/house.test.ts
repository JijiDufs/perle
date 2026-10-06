import { describe, expect, it } from 'vitest';
import { CHAPTERS, houseBrand, houseBrandName, houseStageName, isHouseUnlocked, readChapter, restoredFeatures, unreadChapters } from '../src/core/house';
import { xpToNext } from '../src/core/levels';
import { INITIAL_PLAYER_STATE, type PlayerState } from '../src/core/player';
import { TUTORIAL_PEARLS } from '../src/core/tutorial';
import { DEFAULT_TUNING } from '../src/tuning';

const t = { ...DEFAULT_TUNING, levelBaseXp: 1e9 };
const afterTutorial: PlayerState = { ...INITIAL_PLAYER_STATE, oystersOpened: TUTORIAL_PEARLS.length };

describe('La Maison', () => {
  it('chapitres numérotés dans l’ordre des niveaux, identifiants uniques', () => {
    expect(new Set(CHAPTERS.map((c) => c.id)).size).toBe(CHAPTERS.length);
    CHAPTERS.forEach((c, i) => {
      expect(c.number).toBe(i + 1);
      if (i > 0) expect(c.level).toBeGreaterThanOrEqual(CHAPTERS[i - 1].level);
    });
  });

  it('fermée pendant le tutoriel, puis la première lettre attend', () => {
    expect(isHouseUnlocked(INITIAL_PLAYER_STATE)).toBe(false);
    expect(unreadChapters(INITIAL_PLAYER_STATE, t)).toEqual([]);
    expect(unreadChapters(afterTutorial, t).map((c) => c.id)).toEqual(['cle']);
  });

  it('les lettres suivantes suivent le niveau', () => {
    const level3 = { ...afterTutorial, reputation: xpToNext(1, DEFAULT_TUNING) + xpToNext(2, DEFAULT_TUNING) };
    expect(unreadChapters(level3, DEFAULT_TUNING).map((c) => c.id)).toEqual(['cle', 'lanterne']);
  });

  it('lire une lettre restaure un élément et récompense une seule fois', () => {
    const read = readChapter(afterTutorial, 'cle', t);
    expect(read.chaptersRead).toEqual(['cle']);
    expect(read.dust).toBe(t.chapterRewardDust);
    expect(read.reputation).toBe(t.chapterRewardReputation);
    expect(restoredFeatures(read).has('door')).toBe(true);
    expect(readChapter(read, 'cle', t)).toBe(read);
    // Pas encore débloquée : rien.
    expect(readChapter(read, 'tiroir', t)).toBe(read);
  });

  it('la Maison change de nom avec les rangs', () => {
    expect(houseStageName(1)).toBe('La cabane du ponton');
    expect(houseStageName(5)).toBe('L’atelier de fortune');
    expect(houseStageName(10)).toBe('La petite boutique');
    expect(houseStageName(20)).toBe('Pearl Inc.');
  });

  it('la Maison de Rose devient Pearl Inc. au rang de Joaillier', () => {
    expect(houseBrand(19)).toBe('rose');
    expect(houseBrandName(19)).toBe('Maison Rose');
    expect(houseBrand(20)).toBe('pearl-inc');
    expect(houseBrandName(50)).toBe('Pearl Inc.');
  });
});
