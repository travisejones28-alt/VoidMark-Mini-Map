# VoidMark Mini Map

Standalone square minimap for WoW Forever (interface 16001). No VoidMark or ElvUI dependency.

## Install

Copy the addon into `Interface/AddOns/VoidMarkMiniMap`. The TOC and Lua file must sit directly inside that folder. Restart WoW after first installation.

## Controls

- `/vmm` or `/voidmarkminimap`: settings window.
- `/vmm unlock`: drag the zone-name bar to move the map.
- While unlocked, drag the bottom-right `//` handle horizontally to resize. Locking also hides this handle.
- `/vmm lock`: lock it again.
- `/vmm size 350`: set map width/height (180-600 UI units, capped to your screen).
- `/vmm reset`: restore the default 300-unit map and top-right position.
- Mouse wheel over the map: zoom. Normal map clicks remain Blizzard's.
- Gear button: settings. Settings include size, lock, clock, and purple border.
- Supported addon icons stay around the perimeter. Disable collection in settings to restore each button's original parent, position, scale and drag handlers. Protected buttons are not collected.
- Optional player coordinates update twice a second and show `--, --` when unavailable (such as some instances). No world-map selection is changed.
- Border presets: purple, cyan, and amber, with an option for a neutral gray border.

Position and settings are saved separately for each character. Layout changes requested in combat are applied after combat, with a status message in settings. Tracking, mail and queue controls are retained where available, placed around the perimeter, and sized to fit. Native zoom, sun and calendar controls are hidden; mouse-wheel zoom remains available. Controls loaded by other Blizzard modules are collected after those modules load. LibDBIcon addons are notified of the square shape. Other minimap replacements (such as SexyMap or ElvUI's minimap) should be disabled; VoidMark Mini Map pauses when one is detected.

The drawer supports LibDBIcon buttons plus the named VoidMark and VoidMark Nexus buttons. It does not indiscriminately move every minimap child. Addon visibility preferences are respected, and layout changes wait until combat ends. Disable Leatrix Plus **Enhance minimap** and MoveAny **Minimap** movement before testing; other features in those addons can remain enabled. Either active minimap feature is detected at startup and causes VoidMark Mini Map to pause its styling. These combinations still need in-game testing. Saved positions are clamped to the current screen on layout changes.

This enlarges the actual minimap frame, not the underlying terrain visibility range. Legacy addon buttons that hardcode circular positions may still need adjustment in their own addon settings.

## Validation

Lua 5.1 syntax validation passed with luaparse. The mocked-frame test passed using Fengari's Lua runtime: startup, invalid saved values, combat deferral, sparse and late Blizzard controls, commands, dragging, resizing at nondefault UI scale, options, zoom limits, reset, and screen-size limits including the button dock.

Run `lua tests/smoke.lua` from this directory to repeat the behavior test. These checks cannot replace an in-game check of the Forever client, its textures or other addons. This initial build has not been tested in-game.

## 0.1.1

- Added a resize handle with UI-scale-aware cursor tracking.
- Moved Blizzard controls below the map instead of covering terrain.
- Added late-loading control discovery, tooltips, and combat-pending status.
- Accounted for dock height when limiting map size to the screen.
- Added regression tests for these behaviors.

## 0.1.2

- Added a reversible supported-addon button drawer with hidden/protected-button handling.
- Added optional coordinates, an engineering-icon settings button, and border-color presets.
- Added saved-position recovery after display/UI-scale changes.
- Added Leatrix minimap conflict detection and MoveAny compatibility guidance.
- Expanded tests for drawer restoration/combat deferral and unavailable coordinate data.

### In-game test

1. Open `/vmm`, unlock, move and resize the map, then lock it.
2. Test left/right clicks on supported perimeter icons. Toggle collection off and back on.
3. Enable coordinates and walk around. Enter an instance if convenient.
4. Change size during combat and confirm it applies afterward.
5. `/reload` and confirm size, position and settings persist.

## 0.1.3

- Suppress global, nested and anonymous native zoom controls, including controls created after login. Match anonymous buttons by normal zoom texture, never the highlight texture shared by LibDBIcon addons.
- Keep native sun/calendar controls under a hidden parent and recheck after loading modules and periodically outside combat/Edit Mode.
- Find duplicate coordinates through nested minimap/cluster/backdrop frames, including colorized text and integer coordinates. Preserve the VoidMark header coordinates and unrelated labels/windows.
- Added screenshot regression coverage for late controls, re-show attempts, nested coordinates, unrelated icons and combat deferral. Lua 5.1 syntax and all mocked behavior/conflict scenarios pass. Live Forever rendering still requires an in-game check.

Reference inspection: the available GatherLite and TomTom LibDBIcon copies use the native zoom highlight for addon icons, so highlight-based button detection is deliberately excluded. TomTom's standalone coordinate block belongs to UIParent and is left to its own settings. No changes to those addons are required.

## 0.1.4

- Stop Nexus's mouse-down/OnUpdate circular drag loop while perimeter collection is enabled. Preserve click actions and restore all original mouse/update scripts when collection is disabled.
- Hide the default addon compartment and the native daylight texture as well as its parent. Confirmed native chrome is handled outside combat even if protected; protected addon icons remain excluded from collection.
- Regression tests cover Nexus's actual drag mechanism, restoration, clicks, protected native sun/addon controls and combat deferral.

## 0.1.5

- Nexus square positioning now also works with the saved addon-collection option turned off. Its native drag and click handlers stay intact; circular anchors are projected onto the square perimeter with combat/Edit Mode deferral.
- Hide Forever's actual day/night indicator, `MinimapCluster.DielFrame`. It is separate from `GameTimeFrame` (the calendar), as confirmed in the Forever client UI source: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Minimap/Camelot/Diel.lua
- Tests reproduce collection disabled, nine Nexus angles, combat recovery, and daylight-frame re-show attempts.

## 0.1.6

- Simplified the top bar to a lavender zone title and discreet settings button.
- Added an ElvUI-inspired dark footer: server time left, optional coordinates center, FPS right, with a subtle purple divider. The footer reserves its own space below the terrain.
- Embeds TaliaaFPS's actual live frame when available, preserving its update script and saved standalone settings. Uses the same rounded FPS calculation at quarter-second intervals when that optional addon is absent.

## 0.1.7

- Added a saved **Show FPS** checkbox in `/vmm`; it controls both embedded TaliaaFPS and the fallback counter.
- Increased footer text to 14 pixels with a white fill, black outline and shadow for better readability. Widened the FPS slot and suppress center coordinates on maps below 260 units to avoid crowding.
- Tests cover toggling both FPS paths and periodic layout respecting the saved setting.

## 0.1.8

- Removed the black header strip; the outlined zone name now sits directly over the terrain, with the settings button at the upper right. The zone area still supports dragging while unlocked.
- Added independent server and local clock toggles in `/vmm`. Enable either, both, or neither; `S` identifies server time and `L` identifies the computer's local time. Existing server-clock preference is preserved.
- Clock labels refresh each second. Footer coordinates move into available space and hide if both clocks plus FPS would crowd them on smaller maps.

## 0.1.9

- Put the minimap and its holder in the background UI layer so quest objectives and normal panels render above the terrain. The settings dialog keeps its own higher layer.

## 0.1.10

- Added a saved 24-hour/12-hour AM/PM checkbox in `/vmm` that applies to both server and local clocks. Existing settings default to 24-hour time. Footer spacing accounts for the longer AM/PM labels.
- Regression tests cover both clock sources, midnight, noon, and changing formats.
