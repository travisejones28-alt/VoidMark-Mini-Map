# Forever compatibility audit - 0.3.0

Base: main `c94016e8ff0340ab0addc9b91b3d9e68a9e9ca53` (2026-10-18).

## Ownership and marker interaction

The addon already detached `Minimap` from Blizzard's cluster and put it on
BACKGROUND strata. The original mouse-enabled cluster remained above that map.
Its transparent zoom hit area was also left active. This is consistent with
moving the original HUD frame restoring hover; actual game focus was not observed
in this audit. The old custom header additionally covered the top 22 pixels of
terrain when unlocked.

The fix disables mouse input on the obsolete cluster/container/selection shell,
suppresses the zoom hit area, and moves the custom header outside the terrain.
The native Minimap renderer, children, mouseover scripts, and cursor tooltip
system remain intact. The native backdrop is no longer hidden wholesale, avoiding
collateral hiding of its children. Confirmed compass/chrome elements are hidden
individually. No custom quest-tooltip implementation was introduced.

Secure post-hooks coalesce external geometry/icon-setting changes into a deferred
layout. Combat and active HUD editing defer mutations; the next eligible update
restores VoidMark's geometry. No Blizzard method is replaced, no Edit Mode saved
layout is rewritten, and the original HUD configuration can still appear in Edit
Mode. This is ownership of the shared renderer, not a second independent map.

## Settings

`/vmini` exposes terrain size (180-600 UI units, constrained by screen), native
icon scale (50-200%), rotation, and header below/above. Defaults are 300, 100%,
rotation off, header above. Existing SavedVariables and other preferences survive.

- Size uses SetSize with map frame scale 1, independently of buttons/player arrow.
- Icon scale calls Minimap:SetIconScale when available. It controls only indicators
  supported by that client, not all arbitrary addon pins or launchers. Missing API
  is explicitly reported in settings; terrain scaling is not used as a fallback.
- Rotation uses the shared native rotateMinimap CVar. It cannot be isolated from
  Blizzard's preference; VoidMark restores its saved choice after HUD editing.
- Header positioning is owned locally, with a reserved strip between terrain and
  footer when underneath. The options button follows the header.

## Mail

The previous `Interface\\Minimap\\Minimap-Mail` path was not the native asset in
the inspected UI source. The notifier now checks for the native
`ui-hud-minimap-mail-up` atlas and preserves its aspect ratio, falling back to
`Interface\\Icons\\INV_Letter_15` when the atlas is absent. The legacy global mail
APIs are preferred, with guarded namespaced alternatives if present. Unavailable
reads preserve the last known state rather than inventing new mail.

Login/world-entry, pending-mail, inbox, mailbox-open/close events update visibility;
there is no mail polling. Hover retains up to three senders, including sparse
returns. Leave/hide only dismiss a tooltip owned by this icon. The original native
mail frames remain suppressed under a hidden parent.

## Buttons and performance

The recurring 0.2-second rim rewrite is removed. Secure anchor/scale/parent hooks
and visibility hooks mark a coalesced layout dirty. A two-second discovery pass
remains for late native/non-library frames with no registration event; unchanged
button inventories do not cause anchor writes. Existing coordinate, FPS, latency,
clock, durability and repair sampling are retained.

LibDBIcon, Nexus, VoidMark and Market launchers are recognized. Original click,
drag, mouseover and update handlers are preserved. Native drag anchors are
projected to the square perimeter; normalized positions are saved separately in
`rimPositions`. Turning collection off restores captured parents/scales/anchors.
Protected launchers are not collected. Tracking parent/child pairs are not both
scaled. Market's standalone launcher was previously omitted.

Very dense automatic button collections can still exhaust the finite perimeter
slots. This existing capacity limit is not redesigned here; drag buttons apart
or turn collection off if necessary. Other addons that continuously insist on
owning the same frames can still conflict; existing minimap replacement guards
remain in place.

## Verification and limits

Repository tests/run.py executed using an installed Lua 5.1-compatible LuaJIT DLL
via a temporary Python adapter because lupa and the bundled runtime were not
available. All top-level Lua files compiled. Ten footer groups (including 1,376
layout combinations), fifteen repair groups, four normal/saved-settings/atlas UI
variants and two conflicting-addon startup variants passed. New regressions cover
mail state/texture/senders, native hit regions, ownership restoration, icon scale,
headers, combat/Edit Mode, preserved dragging, position persistence, missing API
fallback and zero idle rim writes. ZIP rebuild and source consistency checks pass.

This is mocked execution, not live secure-frame, cursor, texture rendering or
tooltip verification. The complete peer-addon integration runner was inspected
but not executed; optional integrations were exercised through the minimap mocks.
Mainline native UI references informed the capability-guarded implementation;
the exact Forever game assets/APIs require the following in-game checks.

References:
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Minimap/Mainline/Minimap.xml
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Minimap/Mainline/Minimap.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua

## In-game acceptance checks

1. Reload with unread mail; check one envelope and sender tooltip. Read mail,
   close mailbox, receive another message, and verify disappearance/reappearance.
2. Hover quest/tracking/POI markers at center, edges and all corners, both locked
   and unlocked. Move the map onto the old HUD minimap location and repeat.
3. Change all four /vmini settings repeatedly, enter/exit HUD Edit Mode, switch
   layout, reload, and verify terrain, arrow, icons, header and footer alignment.
4. Drag Nexus, Market, VoidMark and LibDBIcon launchers; test both click buttons,
   tooltips, hidden states, collection off/on, UI scaling and resize.
5. Enter combat while a setting is queued; check for blocked-action/Lua errors,
   then confirm it applies after combat. Verify FPS/MS/coordinates/durability.

## Local deployment inspection

Beta `Interface/AddOns/VoidMarkMiniMap` is an existing junction to
`C:\WoW Forever Addons\VoidMark-Mini-Map`. The Forever AddOns directory exists but
has no corresponding minimap junction. No links or installed source were changed:
this session can read those directories but cannot write to them. Pull main in
GitHub Desktop for the development repository to update the existing beta link.
Create the missing live junction only after confirming the destination is absent.
