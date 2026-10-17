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

## 0.2.1 compact repair cost

Added a single repair-cost line to a hover tooltip over the existing durability segment. Current main had no durability hover tooltip, so this adds that minimal attachment without changing the footer content or controls. Actual per-item prices win over historical estimates; live repair-merchant totals are explicitly labeled bag-inclusive and never train item prices. Per-character observations are capped at 64, expire after 30 days, ignore repeated identical samples and preserve unknown future cache schemas. Missing/restricted APIs and incomplete equipped-item reads do not produce a fabricated exact price. No additional repair polling, global tooltip hooks, automatic repairs, settings, visible windows or minimap buttons were added.

Validation: 15 new repair groups, 10 existing footer groups (1,376 layout combinations), normal and saved-durability-off UI smoke runs, both minimap conflict variants, Lua 5.1 syntax and TOC ordering, and shared four-addon integration in both Nexus/Mini Map load orders. Live Forever Beta rendering, merchant/durability event delivery, vendor discounts and interaction with automatic repair addons require in-game testing. The source/ZIP consistency check is also run before delivery.

## 0.2.2 supplied reference audit

Inspected Broker_DurabilityInfo-v1.33.zip (main GetRepairData, MerchantCorrection and event registration) and ImproveAny-v1.0.23-forever.zip (ele/durabilityframe.lua and merchant auto-repair handler). Confirmed modern C_TooltipInfo repairCost and legacy SetInventoryItem third-return paths already exist with guarded reads and regression coverage. Added explicit death/resurrection invalidation, with a failing-before/passing-after live UI smoke regression. The references' automatic repair behavior and vendor discount arithmetic are not dependencies of this read-only feature. Existing cache, pricing scope, tooltip layout and settings remain unchanged.

Archive SHA-256 values (reference provenance; archives are not redistributed):

- `Broker_DurabilityInfo-v1.33.zip`: `1f6183bffdd6d387b1bb339bd6ed47435541723a3f67b708727c804d0a39edf3`
- `ImproveAny-v1.0.23-forever.zip`: `e565e58274da52b534fb3a792f680a3b75bc515ec213247ea8da00008f0933b5`

Validation: all 15 repair and 10 footer regression groups, existing startup/conflict variants, new death/resurrection UI event coverage, shared-addon load-order integration and distribution consistency checks. Real Forever Beta death/resurrection event timing and repair prices still require in-game verification.
