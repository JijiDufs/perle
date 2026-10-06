// Petites illustrations vectorielles pour l'Atlas ; les formes n'interviennent pas dans le jeu.

export function atlasFindIllustration(find: { id: string; color: string; accent: string; icon: string }): string {
  const gradientId = `atlas-${find.id}`;
  const shell = `<defs><radialGradient id="${gradientId}" cx="34%" cy="28%"><stop stop-color="#fff8db"/><stop offset=".34" stop-color="${find.color}"/><stop offset="1" stop-color="#173741"/></radialGradient><linearGradient id="metal-${find.id}" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fff0bd"/><stop offset=".5" stop-color="${find.color}"/><stop offset="1" stop-color="#75593d"/></linearGradient></defs>`;
  const body = (() => {
    switch (find.icon) {
      case 'moon-pearl':
        return `<ellipse cx="31" cy="35" rx="18" ry="21" fill="url(#${gradientId})" stroke="#e7ddb9" stroke-width="1.4"/><path d="M33 21c-7 7-9 16-5 26 5-7 10-13 16-16-2-5-6-8-11-10Z" fill="${find.accent}" opacity=".8"/><ellipse cx="25" cy="24" rx="4" ry="2.2" fill="#fff" opacity=".8"/><path d="M12 47c9-5 24-6 37-2" fill="none" stroke="#87d6ca" stroke-width="1.4" opacity=".8"/>`;
      case 'bracelet':
        return `<ellipse cx="32" cy="34" rx="22" ry="13" fill="none" stroke="url(#metal-${find.id})" stroke-width="5" stroke-dasharray="3 2"/><path d="M13 29c4-7 11-11 19-11 9 0 16 5 19 12" fill="none" stroke="${find.accent}" stroke-width="2"/><path d="M48 19c4-5 9-7 13-6m-9 12c4-2 7-2 10 0" fill="none" stroke="#aad78f" stroke-width="2" stroke-linecap="round"/><circle cx="17" cy="31" r="3" fill="#ecdfad"/><circle cx="47" cy="39" r="3" fill="#d6e7b6"/>`;
      case 'scuba-button':
        return `<circle cx="32" cy="34" r="24" fill="url(#metal-${find.id})" stroke="#f0dda7" stroke-width="2.5"/><circle cx="32" cy="34" r="17" fill="#244954" stroke="#766543" stroke-width="2"/><circle cx="32" cy="34" r="8" fill="${find.accent}"/><path d="M32 8v9m0 34v7M6 34h9m34 0h9M14 16l6 6m24 24 6 6m0-36-6 6M20 46l-6 6" stroke="#eedcad" stroke-width="2"/><path d="M30 29v10m4-10v10" stroke="#244954" stroke-width="1.5"/>`;
      case 'pollen-stone':
        return `<path d="M9 39c1-13 10-26 25-27 13-1 23 9 22 22-1 12-13 21-27 20C16 53 8 48 9 39Z" fill="url(#${gradientId})" stroke="#d5dcad" stroke-width="1.5"/><circle cx="22" cy="29" r="2" fill="${find.accent}"/><circle cx="40" cy="25" r="1.8" fill="#f1d579"/><circle cx="35" cy="42" r="2.1" fill="#dce881"/><path d="M18 41c5-8 14-13 26-12" stroke="#ecf4c7" stroke-width="1.5" fill="none"/><path d="M10 15v-7m-3 3h6m35 5V9m-3 3h6" stroke="#f0db8a" stroke-width="1.4"/>`;
      case 'maze-shell':
        return `<path d="M11 41c-3-13 5-26 18-29 14-4 28 6 28 20 1 13-11 23-25 22-12 0-20-5-21-13Z" fill="url(#${gradientId})" stroke="#e8d5a6" stroke-width="1.5"/><path d="M20 41c-1-9 6-16 14-16 7 0 12 5 12 11 0 6-5 10-11 10-5 0-8-3-8-7 0-3 2-5 5-5 2 0 4 1 4 3" fill="none" stroke="${find.accent}" stroke-width="2"/><path d="M16 27c9 3 18 3 30-2M15 35c8 2 13 2 19 0" stroke="#f5eed6" stroke-width="1" fill="none" opacity=".65"/>`;
      case 'radio-shell':
        return `<path d="M10 39c4-17 18-27 31-22 9 3 14 12 11 23-3 11-15 17-27 14-11-2-18-7-15-15Z" fill="url(#${gradientId})" stroke="#ecdbb2" stroke-width="2"/><path d="M16 37c8-8 20-11 33-5M20 45c9-5 18-6 27-3M27 26c-2 8-2 16 1 25M38 25c-2 8-1 16 2 24" stroke="#487f7a" stroke-width="1.6" fill="none"/><path d="M44 20 54 9m-3 4 7 1m-8 2 1 6" stroke="${find.accent}" stroke-width="2" stroke-linecap="round"/><path d="M51 29c5-2 8-1 11 2M53 34c3-1 5 0 7 1" stroke="#f4d48a" stroke-width="1.5" fill="none"/>`;
      case 'continue-token':
        return `<circle cx="32" cy="34" r="25" fill="url(#metal-${find.id})" stroke="#f5dd99" stroke-width="2.5"/><circle cx="32" cy="34" r="19" fill="none" stroke="#785e3a" stroke-width="1.5" stroke-dasharray="2 2"/><path d="m32 15 5 11 12 2-9 8 2 12-10-6-10 6 2-12-9-8 12-2 5-11Z" fill="${find.accent}"/><path d="M25 34h14" stroke="#80633d" stroke-width="1.5"/><circle cx="13" cy="17" r="2" fill="#fff4ce"/>`;
      case 'captain-ring':
        return `<path d="M18 39c2 12 7 17 14 17s12-5 14-17" fill="none" stroke="url(#metal-${find.id})" stroke-width="7"/><path d="M19 40c-4-10 1-19 11-19 10 0 16 9 14 19" fill="none" stroke="#f0d596" stroke-width="3"/><path d="m32 10 10 9-4 13H26l-4-13 10-9Z" fill="${find.accent}" stroke="#fff0c5" stroke-width="2"/><path d="m32 14 5 5-5 8-5-8 5-5Z" fill="#fff6da" opacity=".7"/>`;
      case 'sonar-pearl':
        return `<circle cx="32" cy="35" r="15" fill="url(#${gradientId})" stroke="#e7e2c4" stroke-width="1.5"/><ellipse cx="27" cy="29" rx="4" ry="2.5" fill="#fff" opacity=".82"/><path d="M8 26c6-8 12-11 19-12m-17 25c6 7 12 10 19 11m19-36c7 2 12 7 15 13m-15 22c7-2 12-7 15-13" fill="none" stroke="${find.accent}" stroke-width="1.8" stroke-linecap="round"/><circle cx="32" cy="35" r="3" fill="#f8e9b5"/>`;
      case 'reverse-postcard':
        return `<path d="M11 15 51 10 56 49 16 54 11 15Z" fill="url(#metal-${find.id})" stroke="#f2dfb1" stroke-width="2"/><path d="m18 41 10-13 8 7 6-10 8 12" fill="none" stroke="#517d77" stroke-width="2"/><path d="M20 47c8-5 16-5 25-1" fill="none" stroke="#668a81" stroke-width="1.5"/><rect x="39" y="15" width="10" height="9" rx="1" fill="#f3e7c8" stroke="#997c55"/><path d="M41 18h6M41 21h5" stroke="#c08075" stroke-width="1"/><path d="m14 18 5-1M49 47l5-1" stroke="#fff" opacity=".7"/>`;
      case 'comet-pearl':
        return `<path d="M11 39c11-2 19-11 24-27 10 12 15 22 12 31-3 9-16 14-28 8-5-2-7-6-8-12Z" fill="url(#${gradientId})" stroke="#efe4c8" stroke-width="1.5"/><path d="M12 47c-4 3-6 6-8 10m16-11c-3 4-4 8-4 11" fill="none" stroke="${find.accent}" stroke-width="2" stroke-linecap="round"/><path d="m36 21 2-7m7 17 7-2" stroke="#fff7d8" stroke-width="1.4"/><ellipse cx="31" cy="31" rx="3.8" ry="2.2" fill="#fff" opacity=".8"/>`;
      case 'homing-compass':
        return `<circle cx="32" cy="34" r="24" fill="url(#metal-${find.id})" stroke="#f3dda7" stroke-width="2"/><circle cx="32" cy="34" r="18" fill="#183b4c" stroke="#806743" stroke-width="1.4"/><path d="m32 17 5 17-5 17-5-17 5-17Z" fill="${find.accent}"/><path d="m16 34 16-4 16 4-16 4-16-4Z" fill="#d4b467"/><circle cx="32" cy="34" r="4" fill="#fff0bd"/><path d="M30 8c8-5 17-2 20 4m-3-1 4 2-1-5" fill="none" stroke="#8bdacf" stroke-width="1.7"/>`;
      case 'coral-diadem':
        return `<path d="M10 48c3-12 6-21 10-20 3 1 4 9 6 10 3-16 6-25 9-25 4 0 5 15 7 23 4-11 7-14 10-11 3 3 3 13 4 23-14 7-32 7-46 0Z" fill="url(#metal-${find.id})" stroke="#f3e1b3" stroke-width="2"/><path d="M13 48c13 5 28 5 40 0" fill="none" stroke="#725c45" stroke-width="2"/><circle cx="20" cy="27" r="3" fill="${find.accent}"/><path d="m35 8 2 4 4 1-3 3 1 4-4-2-4 2 1-4-3-3 4-1 2-4Z" fill="${find.accent}"/>`;
      case 'tide-hourglass':
        return `<path d="M18 10h28M18 54h28M21 12c0 10 2 13 11 20-9 8-11 11-11 20m22-40c0 10-2 13-11 20 9 8 11 11 11 20" fill="none" stroke="url(#metal-${find.id})" stroke-width="4" stroke-linecap="round"/><path d="M25 17c1 6 3 9 7 12 4-3 6-6 7-12m-14 30c1-6 3-9 7-12 4 3 6 6 7 12" fill="${find.accent}" opacity=".9"/><path d="M28 34h8m-4-4v8" stroke="#f9edc7" stroke-width="1.4"/>`;
      case 'lantern-geode':
        return `<path d="M9 34 17 15l15-8 17 10 7 18-10 17-19 4-16-10-2-12Z" fill="#243c56" stroke="${find.color}" stroke-width="2.5"/><path d="m16 34 7-13 10-6 13 7 4 13-8 11-13 3-11-6-2-9Z" fill="url(#${gradientId})" stroke="#e4d4a4" stroke-width="1.5"/><path d="M32 23c5 5 6 11 0 18-6-7-5-13 0-18Z" fill="${find.accent}"/><path d="M32 19v-6m-4 3 4-4 4 4" stroke="#c9f7e7" stroke-width="1.6" fill="none"/><circle cx="32" cy="34" r="2.5" fill="#fff9d8"/>`;
      default:
        return `<circle cx="32" cy="32" r="20" fill="url(#${gradientId})" stroke="#fff0c6"/>`;
    }
  })();
  return `<svg viewBox="0 0 64 64" aria-hidden="true" focusable="false">${shell}<ellipse cx="32" cy="57" rx="20" ry="3" fill="#020d12" opacity=".42"/>${body}</svg>`;
}
