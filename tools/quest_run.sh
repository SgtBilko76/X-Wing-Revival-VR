#!/usr/bin/env bash
# Build, install and launch X-Wing Revival VR on a USB-connected Quest, record the log, take a screenshot.
# Usage: tools/quest_run.sh [seconds-to-run=30] [--no-build]
set -uo pipefail
cd "$(dirname "$0")/.."
SECS="${1:-30}"
ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
PKG=com.bilko.xwingrevivalvr
OUT="${TMPDIR:-/tmp}/xwr-quest"
mkdir -p "$OUT"

if [ "${2:-}" != "--no-build" ]; then
	(cd quest && ./gradlew --offline -q assembleDebug > "$OUT/gradle.log" 2>&1) || { grep -E "error|What went wrong" -A3 "$OUT/gradle.log" | head -30; exit 1; }
	"$ADB" install -r quest/app/build/outputs/apk/debug/app-debug.apk > /dev/null || exit 1
	"$ADB" shell appops set $PKG MANAGE_EXTERNAL_STORAGE allow
fi

# Close other VR apps, keep the headset awake and the guardian out of the way.
for p in $("$ADB" shell ps -A -o NAME | grep -E "^com\.bilko\." | grep -v "^$PKG$"); do "$ADB" shell am force-stop "$p"; done
"$ADB" shell am force-stop $PKG
"$ADB" shell setprop debug.oculus.guardian_pause 1
"$ADB" shell am broadcast -a com.oculus.vrpowermanager.prox_close > /dev/null
"$ADB" shell input keyevent KEYCODE_WAKEUP
sleep 1
"$ADB" logcat -c
"$ADB" shell am start -n $PKG/.XWingRevivalActivity ${XWR_ARGS:+--es args "\"$XWR_ARGS\""} > /dev/null
timeout "$SECS" "$ADB" logcat -v brief XWingRevival:V LIBGL:V DEBUG:V libc:F AndroidRuntime:E VrApi:I '*:S' > "$OUT/run.log"
"$ADB" shell am startservice -n com.oculus.metacam/.capture.CaptureService -a TAKE_SCREENSHOT > /dev/null
sleep 3
SHOT=$("$ADB" shell ls -t /sdcard/Oculus/Screenshots | head -1 | tr -d '\r')
"$ADB" pull "/sdcard/Oculus/Screenshots/$SHOT" "$OUT/shot.jpg" > /dev/null 2>&1 && echo "Screenshot: $OUT/shot.jpg ($SHOT)"
echo "Log: $OUT/run.log ($(wc -l < "$OUT/run.log") lines)"
