import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Les tests à graine fixe sont déterministes, mais certains font des milliers de tirages.
    // Sur une machine chargée (build Xcode, simulateurs iOS), ils prennent jusqu'à des centaines
    // de fois leur durée normale : le délai par défaut de Vitest (5 s) les faisait échouer par intermittence.
    testTimeout: 60_000,
    // Seulement les tests du dépôt : sinon Vitest ramasse aussi ceux des worktrees de sessions (.claude/worktrees).
    include: ['tests/**/*.test.ts'],
  },
});
