// Chaque élément du catalogue a son texte anglais (app iOS) : une trouvaille, un skin ou un produit
// ajouté sans traduction ferait échouer ce test.
import { describe, expect, it } from 'vitest';
import { APP_ACHIEVEMENTS, APP_CONSUMABLES, APP_SKINS } from '../src/core/appEconomy';
import { PEARLS } from '../src/core/catalog';
import { RANKS } from '../src/core/levels';
import { CATALOG_ENGLISH } from '../src/core/catalogEnglish';
import { BOTTLE_MESSAGES, FINDS, FIND_ALBUMS } from '../src/core/finds';
import { MARKS, OVERTONES, SHAPES } from '../src/core/pearlTraits';
import { GEM_CUTS, GEM_WORDS, JEWEL_NAMES, JEWEL_RARITIES, JEWEL_TYPE_LABELS, JEWEL_VARIANTS, METAL_OPTIONS, TOC_VARIANTS } from '../src/core/jewels';

const filled = (text: string | undefined) => typeof text === 'string' && text.trim().length > 0;

describe('textes anglais du catalogue', () => {
  it('perles et albums', () => {
    for (const pearl of PEARLS) expect(filled(CATALOG_ENGLISH.pearls[pearl.id]?.name) && filled(CATALOG_ENGLISH.pearls[pearl.id]?.flavor), pearl.id).toBe(true);
    for (const album of FIND_ALBUMS) expect(filled(CATALOG_ENGLISH.findAlbums[album.id]?.name), album.id).toBe(true);
  });

  it('trouvailles et messages en bouteille', () => {
    for (const find of FINDS) expect(filled(CATALOG_ENGLISH.finds[find.id]?.name) && filled(CATALOG_ENGLISH.finds[find.id]?.flavor), find.id).toBe(true);
    expect(Object.keys(CATALOG_ENGLISH.finds).sort()).toEqual(FINDS.map((find) => find.id).sort());
    expect(CATALOG_ENGLISH.bottleMessages).toHaveLength(BOTTLE_MESSAGES.length);
  });

  it('formes, reflets et marques', () => {
    for (const id of Object.keys(SHAPES)) expect(filled(CATALOG_ENGLISH.shapes[id as keyof typeof SHAPES]), id).toBe(true);
    for (const id of Object.keys(OVERTONES)) expect(filled(CATALOG_ENGLISH.overtones[id as keyof typeof OVERTONES]), id).toBe(true);
    for (const id of Object.keys(MARKS)) expect(filled(CATALOG_ENGLISH.marks[id as keyof typeof MARKS]?.label), id).toBe(true);
  });

  it('coquilles et produits de la boutique', () => {
    for (const skin of APP_SKINS) expect(filled(CATALOG_ENGLISH.skins[skin.id]?.name), skin.id).toBe(true);
    for (const product of APP_CONSUMABLES) expect(filled(CATALOG_ENGLISH.consumables[product.id]), product.id).toBe(true);
  });

  it('succès et titres', () => {
    for (const a of APP_ACHIEVEMENTS) {
      const text = CATALOG_ENGLISH.achievements[a.id];
      expect(filled(text?.name) && filled(text?.description), a.id).toBe(true);
      expect(filled(text?.title), a.id).toBe(a.title !== undefined);
    }
    expect(Object.keys(CATALOG_ENGLISH.achievements).sort()).toEqual(APP_ACHIEVEMENTS.map((a) => a.id).sort());
  });

  it('rangs', () => {
    for (const rank of RANKS) expect(filled(CATALOG_ENGLISH.ranks[rank.id]), rank.id).toBe(true);
  });

  it('bijoux : raretés, métaux, tailles, noms et variantes', () => {
    const en = CATALOG_ENGLISH.jewels;
    for (const j of JEWEL_RARITIES) {
      expect(filled(en.rarities[j.id]?.label), j.id).toBe(true);
      expect(filled(en.rarities[j.id]?.flavor), j.id).toBe(filled(j.flavor));
      expect(filled(en.metals[j.metalName]), j.metalName).toBe(true);
    }
    expect(en.tocVariants).toHaveLength(TOC_VARIANTS.length);
    for (const variant of TOC_VARIANTS) expect(filled(en.metals[variant.metalName]), variant.metalName).toBe(true);
    for (const options of Object.values(METAL_OPTIONS)) for (const [, name] of options!) expect(filled(en.metals[name]), name).toBe(true);
    for (const v of JEWEL_VARIANTS) {
      expect(filled(en.variants[v.id]?.label) && filled(en.variants[v.id]?.flavor), v.id).toBe(true);
      expect(filled(en.metals[v.metalName]), v.metalName).toBe(true);
    }
    for (const id of Object.keys(GEM_CUTS)) expect(filled(en.cuts[id as keyof typeof GEM_CUTS]), id).toBe(true);
    for (const id of Object.keys(JEWEL_TYPE_LABELS)) expect(filled(en.types[id as keyof typeof JEWEL_TYPE_LABELS]), id).toBe(true);
    expect(Object.keys(en.gemWords).sort()).toEqual(Object.keys(GEM_WORDS).sort());
    for (const [ornament, names] of Object.entries(JEWEL_NAMES)) {
      expect(Object.keys(en.names[ornament as keyof typeof JEWEL_NAMES]).sort(), ornament).toEqual(Object.keys(names).sort());
    }
  });
});
