#!/usr/bin/env python3
"""Exporte la documentation de Pearl Inc. vers le vault Obsidian (~/Archipel-Cerveau/projets/pearl-inc).

Réexécutable : les notes générées sont réécrites, les images recopiées ; les notes que
Jules ajoute lui-même dans le dossier ne sont pas touchées (rien n'est supprimé).
Usage : python3 scripts/obsidian-export.py [chemin-du-vault]
"""
import re, shutil, sys, datetime, pathlib

REPO = pathlib.Path(__file__).resolve().parent.parent
VAULT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "~/Archipel-Cerveau").expanduser()
OUT = VAULT / "projets" / "pearl-inc"
TODAY = datetime.date.today().isoformat()

# Nom de note dans le vault pour chaque fichier du dépôt (sert aussi à réécrire les liens).
NOTE_OF = {
    "AGENTS.md": "01-regles-du-projet",
    "docs/cahier-des-charges.md": "04-cahier-des-charges",
    "docs/JOURNAL.md": "05-journal",
    "docs/duo-gadget.md": "06-duo-gadget",
    "docs/ios-feuille-de-route.md": "07-ios-feuille-de-route",
    "docs/audit-app-ios.md": "08-audit-app-ios",
    "docs/app-store-juridique.md": "09-app-store-juridique",
    "docs/app-store/fiche.md": "10-fiche-app-store",
    "docs/tally-formulaire.md": "11-tally-formulaire",
    "docs/lancement/posts.md": "12-posts-lancement",
}
# titre, statut, sensibilite par note
META = {
    "01-regles-du-projet": ("Pearl Inc. — Règles du projet (AGENTS.md)", "canon", "perso"),
    "02-architecture": ("Pearl Inc. — Architecture et réglages", "canon", "perso"),
    "03-decisions": ("Pearl Inc. — Décisions prises", "canon", "perso"),
    "04-cahier-des-charges": ("Pearl Inc. — Cahier des charges", "canon", "perso"),
    "05-journal": ("Pearl Inc. — Journal des passes", "verifie", "perso"),
    "06-duo-gadget": ("Pearl Inc. — Le premier jeu App Store pour iPhone Duo (proposition)", "hypothese", "perso"),
    "07-ios-feuille-de-route": ("Pearl Inc. — App iOS : feuille de route", "canon", "perso"),
    "08-audit-app-ios": ("Pearl Inc. — Audit de l'app iOS (2026-10-21)", "verifie", "perso"),
    "09-app-store-juridique": ("Pearl Inc. — Juridique et App Store", "hypothese", "confidentiel"),
    "10-fiche-app-store": ("Pearl Inc. — Fiche App Store 1.1", "canon", "public"),
    "11-tally-formulaire": ("Pearl Inc. — Formulaire Tally (inscriptions)", "verifie", "perso"),
    "12-posts-lancement": ("Pearl Inc. — Posts de lancement 1.1", "canon", "public"),
}
# « AGENTS.md §n » dans la prose → la note qui contient ce paragraphe
SECTION_NOTE = {"3": "02-architecture", "7": "02-architecture", "6": "03-decisions"}

def frontmatter(note, source):
    titre, statut, sens = META[note]
    return (f"---\ntitre: {titre}\nstatut: {statut}\nauteur: jules\nsensibilite: {sens}\n"
            f"projet: pearl-inc\nsource: {source}\nexporte: {TODAY}\n---\n\n")

def rewrite_links(text):
    # [texte](docs/x.md) → [[note|texte]]
    def md_link(m):
        label, target = m.group(1), m.group(2)
        key = target.lstrip("./")
        return f"[[{NOTE_OF[key]}|{label}]]" if key in NOTE_OF else m.group(0)
    text = re.sub(r"\[([^\]]+)\]\(((?:\./)?(?:docs/[\w./-]+\.md|AGENTS\.md))\)", md_link, text)
    # AGENTS.md §6 → [[03-decisions|AGENTS.md §6]] (hors backticks)
    text = re.sub(r"(?<!`)AGENTS\.md §(\d)",
                  lambda m: f"[[{SECTION_NOTE.get(m.group(1), '01-regles-du-projet')}|AGENTS.md §{m.group(1)}]]", text)
    return text

def write(note, source, body, h1=None):
    if h1 and not re.search(r"^# ", body, re.M):
        body = f"# {h1}\n\n" + body
    (OUT / f"{note}.md").write_text(frontmatter(note, source) + rewrite_links(body).rstrip() + "\n")

OUT.mkdir(parents=True, exist_ok=True)

# AGENTS.md découpé en trois notes : règles (§1 2 4 5 8), architecture (§3 7), décisions (§6).
agents = (REPO / "AGENTS.md").read_text()
parts = re.split(r"^(?=## \d+\. )", agents, flags=re.M)
intro, sections = parts[0], {p[3]: p for p in parts[1:]}
note_intro = ("> Copie de `AGENTS.md`, la source de vérité du dépôt. **On modifie dans le dépôt, pas ici.**\n"
              "> Découpé en trois notes : [[01-regles-du-projet]] (§1, 2, 4, 5, 8), [[02-architecture]] (§3, 7), [[03-decisions]] (§6).\n\n")
write("01-regles-du-projet", "AGENTS.md", intro + note_intro + "".join(sections[k] for k in "12458"))
write("02-architecture", "AGENTS.md §3, §7", "# Pearl Inc. — Architecture et réglages\n\n" + note_intro + sections["3"] + sections["7"])
write("03-decisions", "AGENTS.md §6", "# Pearl Inc. — Décisions prises\n\n" + note_intro + sections["6"])

for src, note in NOTE_OF.items():
    if src == "AGENTS.md":
        continue
    write(note, src, (REPO / src).read_text(), h1=META[note][0])

# Images et annexes (les visuels App Store 52 Mo et les vidéos 221 Mo restent dans le dépôt).
ASSETS = {
    "docs/audit-app-ios": "audit-app-ios",          # captures citées par 08-audit-app-ios
    "docs/app-store/captures": "app-store/captures",
    "docs/icone": "annexes/icone",
    "docs/skins.png": "annexes/skins.png",
    "docs/reference/prototype-duo.html": "annexes/prototype-duo.html",
}
for src, dst in ASSETS.items():
    s, d = REPO / src, OUT / dst
    d.parent.mkdir(parents=True, exist_ok=True)
    if s.is_dir():
        shutil.copytree(s, d, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".DS_Store"))
    else:
        shutil.copy2(s, d)

# Le carrefour (00-index) et le renvoi dans decisions/ sont écrits une fois : Jules peut les retoucher.
INDEX = OUT / "00-index.md"
if not INDEX.exists():
    INDEX.write_text(f"""---
titre: Pearl Inc. — Carrefour du projet
statut: canon
auteur: jules
sensibilite: perso
projet: pearl-inc
exporte: {TODAY}
---

# Pearl Inc. — Carrefour du projet

> Jeu où l'on ouvre des huîtres pour révéler des perles : **le geste d'ouverture est le jeu**. Sur iPhone Duo (pliable) la charnière pilote l'ouverture, sur iPhone classique c'est le pouce. Prototype web (TypeScript + Vite) puis app iOS native (SwiftUI), version 1.1 sur l'App Store.
> Associés : Jules (code, avec Claude Code), Mathys (notes dans le cahier des charges), Hugo.

## Où est quoi

- **Code** : dépôt `~/Pearl-Inc` ([github.com/JijiDufs/perle](https://github.com/JijiDufs/perle)). La doc ci-dessous en est une **copie exportée** (`scripts/obsidian-export.py`) : on corrige dans le dépôt, puis on réexporte.
- **App Store** : https://apps.apple.com/app/pearl-inc/id6822782842 · **Site** : https://pearl-inc.app
- Restés dans le dépôt (trop lourds) : visuels App Store (`docs/app-store/visuels/`), vidéos de lancement (`docs/lancement/*.mp4`).

## Les règles (source de vérité)

- [[01-regles-du-projet]] : le projet en 30 s, périmètre V1, conventions, protocole de passe, suivi des notes de Mathys.
- [[02-architecture]] : arborescence `src/`, les 8 invariants, machine à états de l'ouverture, **table de tous les réglages**, limites du prototype web.
- [[03-decisions]] : toutes les décisions datées (on n'y revient pas sans en discuter entre associés).

## Le jeu

- [[04-cahier-des-charges]] : vision long terme (pas le périmètre actuel).
- [[05-journal]] : journal des passes, entrée la plus récente en haut.

## L'app iOS

- [[06-duo-gadget]] : pourquoi et comment le premier jeu App Store pour iPhone Duo (proposition).
- [[07-ios-feuille-de-route]] : les lots après la 1.0 (1.1 niveaux … 1.8+ lagons).
- [[08-audit-app-ios]] : audit du 2026-10-21 (économie, confiance, accessibilité), captures dans `audit-app-ios/`.
- [[09-app-store-juridique]] : pages légales, RGPD, Belgique, achats intégrés.

## Lancement et communication

- [[10-fiche-app-store]] : textes FR / EN de la fiche 1.1 ; captures dans `app-store/captures/`.
- [[11-tally-formulaire]] : inscriptions sur pearl-inc.app, promesse du skin « Première marée ».
- [[12-posts-lancement]] : posts X / LinkedIn / Instagram du lancement 1.1.

## Annexes

- `annexes/icone/` : icône 1024 ; `annexes/skins.png` : planche des coquilles ; `annexes/prototype-duo.html` : le prototype Duo d'origine (direction visuelle de départ).
""")

pointer = VAULT / "decisions" / "pearl-inc.md"
if not pointer.exists():
    pointer.write_text(f"""---
titre: Pearl Inc. — décisions
statut: canon
auteur: jules
sensibilite: perso
projet: pearl-inc
---
# Pearl Inc. — décisions

Les décisions de Pearl Inc. sont tenues dans le dépôt (`AGENTS.md` §6) et exportées ici : [[projets/pearl-inc/03-decisions]]. Carrefour du projet : [[projets/pearl-inc/00-index]].
""")

print(f"Exporté vers {OUT}")
