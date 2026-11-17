#!/bin/zsh
# Construit l'app iOS et l'envoie sur TestFlight avec la clé d'API d'équipe (voir scripts/asc.mjs).
# Les groupes MJH et Amis sont internes et reçoivent tous les builds : rien à affecter ensuite.
# Usage : scripts/testflight.sh           (archive + envoi)
#         scripts/testflight.sh --local   (archive + .ipa dans build/, sans envoi)
#         VERSION=1.2 scripts/testflight.sh (autre version que MARKETING_VERSION du projet)
set -euo pipefail
cd "$(dirname "$0")/.."

KEY_ID=2BH29LC72C
ISSUER_ID=79d2e436-8678-4f0d-87cb-49c6bd379f70
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_$KEY_ID.p8"
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY_PATH" -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER_ID")

DESTINATION=upload
[[ "${1:-}" == "--local" ]] && DESTINATION=export

VERSION=${VERSION:-$(grep -m1 -oE 'MARKETING_VERSION = [^;]+' ios/PearlInc.xcodeproj/project.pbxproj | cut -d' ' -f3)}

# Numéro de build = le plus haut déjà envoyé + 1 (Apple refuse un numéro déjà pris, toutes versions confondues).
# Une version déjà validée par Apple n'accepte plus de build : on s'arrête avant de compiler.
BUILD=$(VERSION="$VERSION" node --input-type=module -e "
import { asc } from './scripts/asc.mjs';
const v = await asc('/v1/apps/6822782842/appStoreVersions?filter[versionString]=' + process.env.VERSION);
const state = v.data[0]?.attributes.appVersionState;
if (['READY_FOR_DISTRIBUTION', 'PROCESSING_FOR_DISTRIBUTION', 'REPLACED_WITH_NEW_VERSION'].includes(state)) {
  console.error('La version ' + process.env.VERSION + ' est déjà validée (' + state + ') : relance avec VERSION=<suivante> scripts/testflight.sh');
  process.exit(1);
}
const b = await asc('/v1/builds?filter[app]=6822782842&sort=-version&limit=1&fields[builds]=version');
console.log(Number(b.data[0]?.attributes.version ?? 0) + 1);")

echo "Branche $(git branch --show-current) @ $(git rev-parse --short HEAD), version $VERSION, build $BUILD, destination $DESTINATION"
[[ -n "$(git status --porcelain ios src)" ]] && echo "⚠️  Des modifications non commitées dans ios/ ou src/ partent dans ce build."

OUT=build/testflight
rm -rf "$OUT" && mkdir -p "$OUT"
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$DESTINATION</string>
  <key>teamID</key><string>9332DHG7DM</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

xcodebuild archive -project ios/PearlInc.xcodeproj -scheme PearlInc -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/PearlInc.xcarchive" \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" "${AUTH[@]}" -quiet

xcodebuild -exportArchive -archivePath "$OUT/PearlInc.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT" "${AUTH[@]}" -quiet

if [[ "$DESTINATION" == upload ]]; then
  echo "✅ Build $BUILD envoyé. Apple le traite (10 à 30 min), puis il arrive seul aux groupes MJH et Amis."
else
  echo "✅ Build $BUILD exporté dans $OUT (rien n'est envoyé)."
fi
