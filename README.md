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
- `Addons` button: opens the supported addon-icon drawer; Escape closes it. Disable collection in settings to restore each button's original parent, position, scale and drag handlers. Protected buttons are not collected.
- Optional player coordinates update twice a second and show `--, --` when unavailable (such as some instances). No world-map selection is changed.
- Border presets: purple, cyan, and amber, with an option for a neutral gray border.

Position and settings are saved separately for each character. Layout changes requested in combat are applied after combat, with a status message in settings. Tracking, mail, calendar and queue controls are retained where available, placed in a compact dock below the terrain, and sized to fit. Controls loaded by other Blizzard modules are collected after those modules load. LibDBIcon addons are notified of the square shape. Other minimap replacements (such as SexyMap or ElvUI's minimap) should be disabled; VoidMark Mini Map pauses when one is detected.

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
2. Open `Addons`; test left/right clicks on your supported icons. Toggle collection off and back on.
3. Enable coordinates and walk around. Enter an instance if convenient.
4. Change size during combat and confirm it applies afterward.
5. `/reload` and confirm size, position and settings persist.
