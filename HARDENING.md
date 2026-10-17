# Mini Map 0.1.11 — hardening review

Reviewed main at `2fb87ee`. Existing map size, position, lock, colors, FPS, coordinates and clock settings are retained.

Confirmed fixes:
- Market and Mini Map both registered `/vmm`. Mini Map now uses `/vmini` or `/voidmarkminimap`. The `/vmm` legacy alias remains when Market is absent. An optional dependency establishes the normal shared load order; Market owns `/vmm` when both are enabled.
- Coordinate suppression no longer mistakes quest progress such as `1 / 35` for coordinates. Comma-form coordinate duplicates are still suppressed.
- Collected addon icons and native controls use the map's background layer, rather than leaving explicitly MEDIUM-strata buttons floating above normal panels. Releasing collected buttons restores their previous attributes and handlers.
- A temporary zero icon scale no longer creates infinite anchor offsets.
- Missing clock data or non-finite FPS no longer aborts the update loop.

Validation: Lua 5.1 smoke regressions pass in normal, Leatrix-conflict and MoveAny-conflict modes. Existing tests include nine Nexus icon angles, combat deferral, late icons, native sun/calendar suppression, resize/drag, protected icons, FPS embedding and 12/24-hour clocks. New checks cover command aliases, quest fractions, zero scales and unavailable timing data. A separate Nexus CI job loads the four actual addon sources together in both Nexus/Mini Map load orders.

Installable ZIP: `dist/VoidMarkMiniMap.zip`; `python tools/package.py --check` verifies canonical source contents. Tests require `lupa==2.8`: `python tests/run.py`.

In-game: enable all four addons; verify `/vmini` opens map settings and `/vmm` opens Market; move Nexus icons around the square with collection both on/off; inspect quest objective overlays; open the world map and bags; test drag/resize, combat recovery and clock/FPS options. Mock frame strata do not establish actual rendering or secure-frame behavior. Very dense icon collections and narrow footers still need visual QA.

## 0.2.0 footer implementation

Preserved saved preferences and Interface 16001. Added a durability toggle without a database reset, weighted equipped durability with guarded reads, threshold colors, equipment/durability/merchant events and slow recovery polling. Local-only clocks have no prefix; both clocks are labeled. Replaced fixed offsets with measured full/compact layouts, predictable information priority and reversible hiding. Added a thin purple treatment, small separators and built-in icons. Existing FPS embedding and its update script are retained. No installed addons were modified.

Validation: 10 pure Lua 5.1 footer regression groups, including 1,376 layout combinations, plus all existing smoke checks and a saved-durability-off startup variant. Normal and both conflict startup variants pass. Shared real-source four-addon mocked integration passes with Nexus before/after Mini Map. Source compilation, Interface and footer-before-UI load order, and source/ZIP consistency pass. Rendering, actual repair/damage events, secure behavior and appearance under individual UI scales require in-game verification.
