#!/usr/bin/env bash
# Build the full X-Wing Revival VR APK with the X-Wing Revival 0.6.1 game data inside.
# On first start the app unpacks the data to /sdcard/XWingRevival (only missing/changed files).
#
# Usage: tools/build_full_apk.sh ["<'X-Wing Revival' folder or release .zip>"]
# Without an argument the official 0.6.1 zip is downloaded once into build-full-data/.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
WORK="$ROOT/build-full-data"
ASSETS="$WORK/assets"
ZIP_URL="https://github.com/Raptor007/X-Wing-Revival/releases/download/v0.6.1-alpha/X-Wing.Revival.0.6.1.Alpha.zip"
FOLDERS="Fonts Missions Models Music Shaders Ships Sounds Textures"
mkdir -p "$WORK"

SRC="${1:-}"
if [ -z "$SRC" ]; then
	SRC="$WORK/X-Wing.Revival.0.6.1.Alpha.zip"
	[ -f "$SRC" ] || { echo "Downloading X-Wing Revival 0.6.1 ..."; curl -fL -o "$SRC.part" "$ZIP_URL" && mv "$SRC.part" "$SRC"; }
fi
if [ -f "$SRC" ]; then
	rm -rf "$WORK/unzipped"
	unzip -q "$SRC" -d "$WORK/unzipped"
	SRC="$WORK/unzipped/X-Wing Revival"
fi
for f in $FOLDERS; do
	[ -d "$SRC/$f" ] || { echo "Missing folder: $SRC/$f" >&2; exit 1; }
done

echo "Staging game data ..."
rm -rf "$ASSETS"
mkdir -p "$ASSETS/gamedata"
for f in $FOLDERS README.txt; do
	cp -al "$SRC/$f" "$ASSETS/gamedata/" 2>/dev/null || cp -r "$SRC/$f" "$ASSETS/gamedata/"
done
# Index: "<size>\t<path>" per file, read by RaptorEngine/Port/AndroidPort.cpp.
(cd "$ASSETS/gamedata" && find . -type f -printf '%s\t%P\n' | LC_ALL=C sort -t$'\t' -k2) > "$ASSETS/gamedata.idx"
echo "$(wc -l < "$ASSETS/gamedata.idx") files, $(du -shL "$ASSETS/gamedata" | cut -f1)"

echo "Building APK ..."
(cd quest && ./gradlew -q assembleRelease -PgameData="$ASSETS")
VER=$(grep -oP "versionName '\K[^']+" quest/app/build.gradle)
mkdir -p dist
OUT="dist/X-Wing-Revival-VR-v$VER-full.apk"
cp quest/app/build/outputs/apk/release/app-release.apk "$OUT"
echo "Done: $ROOT/$OUT ($(du -h "$OUT" | cut -f1))"
