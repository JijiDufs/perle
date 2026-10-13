#!/bin/sh
# Icône de Pearl Inc. (la perle dans le lagon, dessin de la page pearl-inc.app) pour l'app iOS, le site et les réseaux.
# Usage : sh scripts/make-app-icon.sh (macOS). Le favicon SVG du site (site/favicon.svg) est le SVG de la page.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cp "$ROOT/scripts/app-icon.swift" "$TMP/main.swift"
swiftc -O -target arm64-apple-macos14 -o "$TMP/app-icon" "$TMP/main.swift"
"$TMP/app-icon" "$ROOT"
# favicon.ico (navigateurs qui le demandent d'office) depuis la version 32 px.
sips -s format ico "$ROOT/site/favicon-32.png" --out "$ROOT/site/favicon.ico" >/dev/null
