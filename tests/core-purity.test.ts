// Garde-fou de l'invariant n°1 de AGENTS.md : le Core reste pur.
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

const CORE_DIR = join(__dirname, '../src/core');
const FORBIDDEN = [/(?<![.\w])document\./, /(?<![.\w])window\./, /(?<![.\w])navigator\./, /\blocalStorage\b/, /from '\.\.\/(platform|features|input)/, /Date\.now\(/, /Math\.random\(/];

describe('pureté du Core', () => {
  for (const file of readdirSync(CORE_DIR).filter((f) => f.endsWith('.ts'))) {
    it(`${file} ne touche ni au navigateur, ni au hasard ou à l'heure globale`, () => {
      const source = readFileSync(join(CORE_DIR, file), 'utf8');
      for (const pattern of FORBIDDEN) expect(source, `motif interdit ${pattern}`).not.toMatch(pattern);
    });
  }
});
