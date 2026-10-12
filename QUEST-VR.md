Beta of **X-Wing Revival VR**: [X-Wing Revival](https://github.com/Raptor007/X-Wing-Revival) 0.6.1 by Raptor007 running natively on Meta Quest 3 (OpenXR + OpenGL ES through gl4es), plus a headless dedicated server for Linux.

**The APK contains no game data.** X-Wing Revival is free: download the official game once and copy its folders to the headset (see Install).

### What works
- Head-tracked stereo 3D in flight, from the cockpit, at 72 Hz
- Menus on a big flat screen that stays in place in front of you
- Touch controllers bound as a joystick in flight, remappable in *Controls*
- Laser pointer for the menus (right controller)
- Single player, LAN and online games; the Linux dedicated server works with Quest and PC players

### Install (Quest)
1. Install `X-Wing-Revival-VR-v0.1.0-beta.apk` with SideQuest or `adb install -r X-Wing-Revival-VR-v0.1.0-beta.apk`.
2. Download the official [X-Wing Revival 0.6.1 zip](https://github.com/Raptor007/X-Wing-Revival/releases/download/v0.6.1-alpha/X-Wing.Revival.0.6.1.Alpha.zip) and unzip it on your PC.
3. From the `X-Wing Revival` folder copy `Fonts`, `Missions`, `Models`, `Music`, `Shaders`, `Ships`, `Sounds` and `Textures` to `/sdcard/XWingRevival/` on the headset (about 310 MB, with SideQuest's file manager or `adb push`).
4. Start **X-Wing Revival VR** from *Unknown Sources* and allow "access to all files" when asked.

### Controls
| Input | Flight | Menus |
|---|---|---|
| Left stick | Pitch and yaw | |
| Right stick | Roll (left/right), throttle (up/down) | Scroll |
| Right trigger | Fire | Click |
| Left trigger | Target what's in front of you | |
| Right grip | Switch weapon (lasers / ions / torpedoes) | |
| Left grip | Firing mode (single / linked) | |
| A / B | Target nearest enemy / nearest attacker | B = back |
| X / Y | Shield direction / target newest incoming | |
| Right stick click | Target objective | |
| Left stick click | Scoreboard | |
| Left Menu button | Pause menu | Back |
| Hold both stick clicks 1 s | Recenter view | Recenter view |

### Dedicated server (Linux x86_64)
Unpack `X-Wing-Revival-VR-server-v0.1.0-beta-linux-x86_64.tar.gz` and run `./start-server.sh`. It needs no graphics card or display; on the first start it downloads the official game once and keeps only the data the server needs. Players join on TCP port 7000 (on a LAN it shows up in *Custom / LAN*).

### Known limits
- Big fleet battles run at about 45-65 FPS (72 Hz display); the engine draws each eye separately.
- Graphics are set lighter than on PC (debris, lights, blast marks); raise them in *Preferences* if you like.
- Tested on Quest 3 only.

### Building
CMake for everything (`CMakeLists.txt`): `cmake -S . -B build` (Linux client), `-DXWR_SERVER_ONLY=ON` (dedicated server), and the Quest app with `cd quest && ./gradlew assembleRelease`. Submodules: `git submodule update --init --recursive`.

Credits: X-Wing Revival and RaptorEngine by [Raptor007](https://github.com/Raptor007). Quest port by SgtBilko76.
