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

Position and settings are saved separately for each character. Layout changes requested in combat are applied after combat, with a status message in settings. Tracking, mail, calendar and queue controls are retained where available, placed in a compact dock below the terrain, and sized to fit. Controls loaded by other Blizzard modules are collected after those modules load. LibDBIcon addons are notified of the square shape. Other minimap replacements (such as SexyMap or ElvUI's minimap) should be disabled; VoidMark Mini Map pauses when one is detected.

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
