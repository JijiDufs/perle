#!/bin/sh
# Planche des skins d'huître (docs/skins.png), dessinée sur le Mac avec le code de dessin de l'app iOS
# et le catalogue exporté. Usage : sh scripts/make-skin-sheet.sh (après npm run ios:export)
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ART="$ROOT/ios/PearlInc/Art"
cp "$ROOT/scripts/skin-sheet.swift" "$TMP/main.swift"
swiftc -O -target arm64-apple-macos14 -o "$TMP/skin-sheet" \
  "$ART/Palette.swift" "$ART/ShellArt.swift" "$ART/PearlArt.swift" "$ART/ClamArt.swift" \
  "$ART/SkinLook.swift" "$ART/OysterArt.swift" "$ART/LagoonArt.swift" "$ART/LagoonBackground.swift" "$TMP/main.swift"
"$TMP/skin-sheet" "$ROOT/ios/PearlCore/Sources/PearlCore/Resources/catalog.json" "$ROOT/docs/skins.png"
