// Chaque élément du catalogue a son texte anglais (app iOS) : une trouvaille, un skin ou un produit
// ajouté sans traduction ferait échouer ce test.
import { describe, expect, it } from 'vitest';
import { APP_CONSUMABLES, APP_SKINS } from '../src/core/appEconomy';
import { PEARLS } from '../src/core/catalog';
import { RANKS } from '../src/core/levels';
import { CATALOG_ENGLISH } from '../src/core/catalogEnglish';
import { BOTTLE_MESSAGES, FINDS, FIND_ALBUMS } from '../src/core/finds';
import { MARKS, OVERTONES, SHAPES } from '../src/core/pearlTraits';

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

  it('rangs', () => {
    for (const rank of RANKS) expect(filled(CATALOG_ENGLISH.ranks[rank.id]), rank.id).toBe(true);
  });
});
