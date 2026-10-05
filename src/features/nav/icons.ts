// Icônes de navigation dessinées en SVG (trait, couleur du texte). Provisoires : phase 2 (design).
const svg = (body: string) =>
  `<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${body}</svg>`;

export const ICONS = {
  oyster: svg('<path d="M3.5 15.5C3.5 10 7.3 5.5 12 5.5s8.5 4.5 8.5 10c-2.7 2-5.5 3-8.5 3s-5.8-1-8.5-3z"/><path d="M12 18.5V8.5M8.6 18 7.2 9.6M15.4 18l1.4-8.4"/>'),
  ecrin: svg('<path d="M4.5 11h15v7.5a1.5 1.5 0 0 1-1.5 1.5H6a1.5 1.5 0 0 1-1.5-1.5z"/><path d="M4.5 11 6 6.5h12l1.5 4.5"/><path d="M11 14.5h2"/>'),
  collection: svg('<rect x="8" y="3.5" width="11.5" height="15" rx="2"/><path d="M5.5 7v11.5a2 2 0 0 0 2 2h8.5"/>'),
  lock: svg('<rect x="6" y="11" width="12" height="9" rx="2"/><path d="M9 11V8a3 3 0 0 1 6 0v3"/>'),
  gear: svg('<circle cx="12" cy="12" r="3"/><path d="M12 3.5v2.2M12 18.3v2.2M3.5 12h2.2M18.3 12h2.2M6 6l1.6 1.6M16.4 16.4 18 18M6 18l1.6-1.6M16.4 7.6 18 6"/>'),
};
