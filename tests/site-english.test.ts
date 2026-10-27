// Page d'inscription en anglais à sa propre adresse (pearl-inc.app/en), pour mesurer la campagne
// par langue. Le texte de la page se traduit en JavaScript (site/index.html) ; seul l'en-tête
// change : langue, titre, adresse canonique et aperçu de lien (X, LinkedIn…), lus sans JavaScript.
// site/en/index.html est donc généré depuis site/index.html : ne jamais l'éditer à la main.
// Ce test échoue si la page anglaise n'est plus à jour : lancer `npm run site:en`.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const ROOT = resolve(__dirname, '..');
const FRENCH_PATH = resolve(ROOT, 'site/index.html');
const ENGLISH_PATH = resolve(ROOT, 'site/en/index.html');
const UPDATE = process.env.UPDATE_SITE_EN === '1';

const ENGLISH_URL = 'https://pearl-inc.app/en';
const OG_TITLE = 'Pearl Inc.: the oyster opens with your iPhone Duo';

/** Remplacements de l'en-tête, du français vers l'anglais (chacun doit trouver exactement une fois son motif). */
const HEAD_REPLACEMENTS: ReadonlyArray<readonly [RegExp, string]> = [
  [/<!doctype html>\n/, '<!doctype html>\n<!-- Fichier généré depuis site/index.html par `npm run site:en` : ne pas éditer à la main. -->\n'],
  [/<html lang="fr">/, '<html lang="en">'],
  [/<meta name="description" content="[^"]*">/, '<meta name="description" content="Pearl Inc.: the game where the oyster opens with your iPhone Duo. Free on the App Store, try it here.">'],
  [/<title>[^<]*<\/title>/, '<title>Pearl Inc. for iPhone Duo</title>'],
  [/<link rel="canonical" href="[^"]*">/, `<link rel="canonical" href="${ENGLISH_URL}">`],
  [/<meta property="og:url" content="[^"]*">/, `<meta property="og:url" content="${ENGLISH_URL}">`],
  [/<meta property="og:title" content="[^"]*">/, `<meta property="og:title" content="${OG_TITLE}">`],
  [/<meta property="og:description" content="[^"]*">/, '<meta property="og:description" content="Open it gently and light seeps in. Too fast, and the pearl cracks. Free on the App Store.">'],
  [/<meta property="og:locale" content="fr_FR">\n<meta property="og:locale:alternate" content="en_US">/, '<meta property="og:locale" content="en_US">\n<meta property="og:locale:alternate" content="fr_FR">'],
  [/<meta property="og:image:alt" content="[^"]*">/, '<meta property="og:image:alt" content="An open oyster in a turquoise lagoon, a shining golden pearl, and the title Pearl Inc.">'],
  [/<meta name="twitter:title" content="[^"]*">/, `<meta name="twitter:title" content="${OG_TITLE}">`],
  [/<meta name="twitter:description" content="[^"]*">/, '<meta name="twitter:description" content="Open it gently and light seeps in. Too fast, and the pearl cracks. Free on the App Store.">'],
  [/data-lang="fr" aria-pressed="true"/, 'data-lang="fr" aria-pressed="false"'],
  [/data-lang="en" aria-pressed="false"/, 'data-lang="en" aria-pressed="true"'],
];

function englishPage(french: string): string {
  return HEAD_REPLACEMENTS.reduce((html, [pattern, replacement]) => {
    const matches = html.match(new RegExp(pattern.source, 'g'))?.length ?? 0;
    expect(matches, `site/index.html : motif ${pattern} trouvé ${matches} fois au lieu d'une`).toBe(1);
    return html.replace(pattern, () => replacement);
  }, french);
}

describe('page anglaise du site (pearl-inc.app/en)', () => {
  it('générée depuis la page française et à jour', () => {
    const english = englishPage(readFileSync(FRENCH_PATH, 'utf8'));
    if (UPDATE) writeFileSync(ENGLISH_PATH, english);
    expect(existsSync(ENGLISH_PATH), 'site/en/index.html manque : lancer npm run site:en').toBe(true);
    expect(readFileSync(ENGLISH_PATH, 'utf8'), 'Page anglaise périmée : lancer npm run site:en').toBe(english);
  });
});
