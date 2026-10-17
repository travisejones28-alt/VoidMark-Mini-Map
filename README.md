# VoidMark Mini Map

Current release: **0.2.4** (Forever Interface **16001**).

Current hardening release: see [HARDENING.md](HARDENING.md) for confirmed fixes, validation and in-game checks. Download the rebuilt addon from `dist/`.


Standalone square minimap for WoW Forever (interface 16001). No VoidMark or ElvUI dependency.

## Install

Copy the addon into `Interface/AddOns/VoidMarkMiniMap`. The TOC, `Footer.lua`, `Repair.lua`, and `VoidMarkMiniMap.lua` must sit directly inside that folder. Restart WoW after first installation.

## Controls

- `/vmini` or `/voidmarkminimap`: settings window.
- `/vmini unlock`: drag the zone-name bar to move the map.
- While unlocked, drag the bottom-right `//` handle horizontally to resize. Locking also hides this handle.
- `/vmini lock`: lock it again.
- `/vmini size 350`: set map width/height (180-600 UI units, capped to your screen).
- `/vmini reset`: restore the default 300-unit map and top-right position.
- Mouse wheel over the map: zoom. Normal map clicks remain Blizzard's.
- Gear button: settings. Settings include size, lock, clock, and purple border.
- Supported addon icons stay around the perimeter. Disable collection in settings to restore each button's original parent, position, scale and drag handlers. Protected buttons are not collected.
- Optional player coordinates update twice a second and show `--, --` when unavailable (such as some instances). No world-map selection is changed.
- Border presets: purple, cyan, and amber, with an option for a neutral gray border.

Position and settings are saved separately for each character. Layout changes requested in combat are applied after combat, with a status message in settings. Tracking, mail and queue controls are retained where available, placed around the perimeter, and sized to fit. Native zoom, sun and calendar controls are hidden; mouse-wheel zoom remains available. Controls loaded by other Blizzard modules are collected after those modules load. LibDBIcon addons are notified of the square shape. Other minimap replacements (such as SexyMap or ElvUI's minimap) should be disabled; VoidMark Mini Map pauses when one is detected.

The drawer supports LibDBIcon buttons plus the named VoidMark and VoidMark Nexus buttons. It does not indiscriminately move every minimap child. Addon visibility preferences are respected, and layout changes wait until combat ends. Disable Leatrix Plus **Enhance minimap** and MoveAny **Minimap** movement before testing; other features in those addons can remain enabled. Either active minimap feature is detected at startup and causes VoidMark Mini Map to pause its styling. These combinations still need in-game testing. Saved positions are clamped to the current screen on layout changes.

This enlarges the actual minimap frame, not the underlying terrain visibility range. Legacy addon buttons that hardcode circular positions may still need adjustment in their own addon settings.

## Validation

Run `python tests/run.py` with `lupa==2.8` installed. It compiles addon Lua under stock Lua 5.1, checks the Interface 16001 TOC/load order, tests footer calculations/layout, and runs normal, saved-durability-off, Leatrix and MoveAny startup variants. The existing icon collection, nine-angle Nexus positioning, combat deferral, dragging, sizing, zoom, native chrome suppression and FPS embedding tests remain active. `python tools/package.py --check` verifies the distribution ZIP against source.

The shared four-addon mocked-client integration also passed locally in both Nexus/Mini Map load orders. These tests inspect handlers, calculated bounds and frame attributes; they do not establish actual Forever rendering, protected execution, repair-event delivery or third-party font appearance.

## 0.2.4 independent performance options

`/vmini` now has separate **Show FPS** and **Show server latency (MS)** checkboxes. Show either, both, or neither; each preference is saved separately. On the first upgrade, a character's old combined FPS preference initializes latency to the same value, preserving the previous visible/hidden choice. An explicitly saved latency choice is never overwritten by the FPS setting.

The responsive performance area only reserves space for enabled metrics. Built-in and TaliaaFPS displays respect the FPS option independently; disabling latency stops its five-second network sampling. Other footer preferences and repair behavior are unchanged.

Tests exercise every toggle combination with built-in/embedded FPS, saved latency-off startup, migration of old combined-off preferences, and disabled-latency sampling. In game, verify the four combinations, resize the map, then `/reload` to confirm persistence.

## 0.2.3 server latency

The performance footer now shows **FPS: 56 MS: 38**. `MS` is the world/server latency (fourth return from Forever's `GetNetStats`), not local/home latency. The existing FPS preference now reads **Show FPS / server latency** and controls both without changing its saved value. Latency updates every five seconds; missing, restricted or invalid readings show `MS: --`. The combined performance group participates in the same responsive layout and hides together when space is tight. Existing TaliaaFPS frame integration is retained.

Regression coverage verifies distinct home/server values, invalid and restricted results, five-second sampling, toggle behavior and overlap-free bounds at 180/300/400/600 units. Actual connection readings and appearance still need verification in the Forever Beta client.

## 0.2.2 working-addon reference review

Inspected the supplied Broker_DurabilityInfo v1.33 and ImproveAny v1.0.23 Forever archives. Their modern tooltip repair-cost field and Classic third-return-value scanner match our existing API paths. Added explicit death (`PLAYER_DEAD`) and resurrection (`PLAYER_UNGHOST`) refreshes, as used by Broker, so cached tooltip costs do not depend solely on an accompanying durability event. Regression tests verify repeated death-event coalescing and refreshed durability/cost after resurrection.

The reference addons were inspected as source/API examples, not installed or bundled. No automatic repair actions, reputation tables, extra windows, broker dependencies or periodic repair polling were imported. Broker's reputation-normalization model differs from our live vendor-total display and clearly marked vendor-observed estimates; current actual API quotes still take precedence.

## 0.2.1 repair cost

Hover the existing durability footer segment to see its percentage and one compact line, for example **Repair cost: 2g 61s 57c**. There are no new visible windows, buttons, settings or equipment tables. Disabling or responsively hiding durability also removes its hover area.

- Live equipment prices use `C_TooltipInfo.GetInventoryItem` when it supplies a readable repair cost, with a private hidden tooltip scanner for Classic return values as a fallback. The visible shared GameTooltip is never used for scanning. Fully repaired equipment costs zero; missing, restricted or incomplete prices produce **Repair cost: Unavailable** unless the exact item has a usable saved estimate.
- Equipment changes, durability events, death and resurrection invalidate the result. Merchant opening captures the quote immediately; merchant update bursts are coalesced to one scan per frame. Hover also refreshes it. Repair pricing adds no periodic polling and never performs a repair or intercepts another addon's repair function.
- At a repair merchant, the live `GetRepairAllCost` result takes precedence and is marked **(vendor total)** because it can include damaged equipment in bags. That aggregate is never used to train equipment estimates. Closing the merchant returns to equipped-item pricing.
- Valid per-item vendor observations are saved under the existing per-character `VoidMarkMiniMapDB.repairObservations`. The cache stores at most 64 item-identity/durability records, expires them after 30 days, and refines the observed cost per lost durability point. Repeated identical quotes do not add weight. New or changed gear without observations is not assigned a guessed price.
- Historical estimates are marked `~` and rounded to silver: **Repair cost: ~2g 62s 0c**. Vendor discounts and client rules can change actual prices, so live API prices always override history. There is no history log or bag-price cache. Existing settings and other footer information remain unchanged.

Validation includes 15 repair regression groups for live/fallback APIs, vendor totals, partial data, restricted values, saved cache reload/refinement/limits/expiry, and money formatting. The actual hover/event wiring also verifies no timer polling, merchant-event coalescing, responsive hiding and protection of other tooltip owners. The Interface 16001 TOC loads `Repair.lua` before the main UI.

In game, damage equipment and hover durability; open a repair merchant (also with damaged gear in bags), compare the labeled vendor total, repair, close the vendor and check zero; swap gear and `/reload`; check estimate refinement when live prices are unavailable. Test with ElvUI/Leatrix non-minimap features and any automatic repair addon. Automatic repair can run before this addon's merchant handler, so a pre-repair learning sample is not guaranteed; repair behavior is never delayed or changed. API availability, real merchant events and visual appearance require the actual Classic Forever Beta client.

API references: [Forever tooltip API declaration](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua), [Forever merchant UI](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/MerchantFrame.lua), and [ElvUI's API usage](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Modules/DataTexts/Durability.lua). These are API references; no ElvUI UI or dependency was imported.

## 0.2.0 footer

The footer presents **Time | Coordinates | Durability | FPS**, with a translucent black background, one-pixel purple border, quiet highlight, small diamond separators, and clock/location/shield icons. Text uses an outlined 12–14 point font with a subtle shadow, adjusted for map size.

- Local-only time has no prefix: `3:11 PM`. Server-only time also stands alone. Both clocks use `Server` and `Local` labels; at narrow widths the clock segment uses two lines. The saved 12/24-hour preference is unchanged.
- Enable **Show equipment durability** in `/vmini`. It defaults on for an existing character without this new setting. Durability is the sum of current equipped-item durability divided by the sum of maximum durability for equipment that reports valid durability. It is not the lowest single item's percentage. Non-durable/empty slots are ignored; unavailable readings show `--` when no valid equipment can be measured.
- Durability is green above 70%, yellow from 30% through 70%, and red below 30%. It refreshes on equipment changes, durability updates, merchant close, login/entering world, and a five-second recovery poll while enabled. No equipment history is stored.
- The layout measures natural text widths. It first shortens `Durability: 92%` to `92%`, stacks dual clocks if needed, then removes icons if needed. If space still runs out it hides FPS first, then coordinates, then durability, keeping time. Expanding restores enabled information automatically. Actual text areas stay within minimap width; hidden information does not change its saved toggle.
- Existing TaliaaFPS live-frame integration retains its update script and standalone saved settings. Footer layout is recalculated only when its displayed inputs change or layout is reapplied.

In-game checks: compare map sizes 180/300/400/600 with every footer toggle; test local/server/both clocks in 12/24-hour format; resize down and back up; damage and repair equipment, swap gear, and `/reload`; check clock/map/shield textures and text alignment at your UI scale; test with and without TaliaaFPS and during combat. Existing map behavior still needs its usual visual and click checks.

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

1. Open `/vmini`, unlock, move and resize the map, then lock it.
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

- Added a saved **Show FPS** checkbox in `/vmini`; it controls both embedded TaliaaFPS and the fallback counter.
- Increased footer text to 14 pixels with a white fill, black outline and shadow for better readability. Widened the FPS slot and suppress center coordinates on maps below 260 units to avoid crowding.
- Tests cover toggling both FPS paths and periodic layout respecting the saved setting.

## 0.1.8

- Removed the black header strip; the outlined zone name now sits directly over the terrain, with the settings button at the upper right. The zone area still supports dragging while unlocked.
- Added independent server and local clock toggles in `/vmini`. Enable either, both, or neither; `S` identifies server time and `L` identifies the computer's local time. Existing server-clock preference is preserved.
- Clock labels refresh each second. Footer coordinates move into available space and hide if both clocks plus FPS would crowd them on smaller maps.

## 0.1.9

- Put the minimap and its holder in the background UI layer so quest objectives and normal panels render above the terrain. The settings dialog keeps its own higher layer.

## 0.1.10

- Added a saved 24-hour/12-hour AM/PM checkbox in `/vmini` that applies to both server and local clocks. Existing settings default to 24-hour time. Footer spacing accounts for the longer AM/PM labels.
- Regression tests cover both clock sources, midnight, noon, and changing formats.
