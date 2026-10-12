#!/usr/bin/env bash
# Copy the X-Wing Revival 0.6.1 game data to a Meta Quest connected over USB (adb).
#
# Usage: tools/stage_quest_data.sh "<path to extracted 'X-Wing Revival' folder or the release .zip>"
# Data goes to /sdcard/XWingRevival (kept when the app is uninstalled).
set -euo pipefail

SRC="${1:?path to the X-Wing Revival folder or zip}"
PKG=com.bilko.xwingrevivalvr
DEST=/sdcard/XWingRevival
ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
FOLDERS="Fonts Missions Models Music Shaders Ships Sounds Textures"

if [ -f "$SRC" ]; then
	TMP=$(mktemp -d)
	trap 'rm -rf "$TMP"' EXIT
	unzip -q "$SRC" -d "$TMP"
	SRC="$TMP/X-Wing Revival"
fi

for f in $FOLDERS; do
	[ -d "$SRC/$f" ] || { echo "Missing folder: $SRC/$f" >&2; exit 1; }
done

"$ADB" shell mkdir -p "$DEST"
for f in $FOLDERS; do
	echo "Pushing $f ..."
	"$ADB" push "$SRC/$f" "$DEST/" > /dev/null
done
"$ADB" push "$SRC/README.txt" "$DEST/" > /dev/null
"$ADB" shell appops set $PKG MANAGE_EXTERNAL_STORAGE allow 2>/dev/null || true
echo "Done: $("$ADB" shell du -sh "$DEST" | cut -f1) in $DEST"
