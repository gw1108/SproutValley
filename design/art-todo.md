# Art Asset TODO — Sprout Valley (Vertical Slice)

Derived from `design/GDD.md`. Status values: **TODO** | **Created**.
"Created" = asset already exists under `SourceArt/` (see `SourceArt/_catalog/catalog.jsonl`).
Reminder: this is a storybook-style illustration game (soft cartoon, not pixel art) — see `VISUAL_RULES.md` before importing/rendering anything. `SourceArt/cozy_farm_visualization.jpg` is the look reference (note: it shows a greenhouse — there is no greenhouse in this game).

---

## 1. Sprites — Animals

No player character — the game is click-driven (GDD §3/§3.1).

| Asset | Notes (GDD ref) | Status |
|---|---|---|
| Chicken (idle / eat ) | Lives in Chicken Coop (§7) | TODO |
| Cow (idle / eat ) | Lives in Cow Pasture (§7) | TODO |

## 2. Sprites — World Objects & Buildings

| Asset | Notes (GDD ref) | Status |
|---|---|---|
| Road (sprite drawn on top of ground background) | Permanent blocker — unremovable, can't be built on; works like a very large tree (§3/§4) | TODO |
| Small tree (blocker, removed by Axe) | §4 | TODO |
| Large tree (blocker, removed by Saw) | §4 | TODO |
| Tree removal effect (stump ) | §4 | TODO |
| Player Home | Pre-placed flavor structure (§3) | TODO |
| Barn (storage) | Stores animal/processed goods (§10) | TODO |
| Silo (storage) | Stores crops (§10) | TODO |
| Farm Plot (empty tilled soil) | Placeable, max 25 (§6) | TODO |
| Chicken Coop | Animal home (§7) | TODO |
| Cow Pasture (fence/enclosure) | Animal home (§7) | TODO |
| Dairy Barn | Production building (§8) | TODO |
| Bakery | Production building (§8) | TODO |
| Feed Mill | Production building (§8) | TODO |
| Delivery box / order drop-off | Sell point (§9, §13.4) | TODO |
| Placement-mode tile highlight (valid green / invalid red) | Placement state 2d coloring effect. Reuse the building sprite but color green or red (§11) | TODO |

## 3. Sprites — Crops (per crop: growth stages + harvestable state)

Suggest 3 growth stages each (sprout → mid → mature and harvestable).

| Asset | Status |
|---|---|
| Corn — growth stages | TODO |
| Wheat — growth stages | TODO |
| Soybean — growth stages | TODO |
| Potato — growth stages | TODO |

## 4. Sprites — Items / Goods Icons

Needed for shop entries, storage views, and delivery/sell panel (§5, §9, §13.5).

| Asset | Status |
|---|---|
| Corn, Wheat, Soybean, Potato — harvested crop icons and the seed icon that gets planted(4) | TODO |
| Egg icon | TODO |
| Milk icon | TODO |
| Butter icon | TODO |
| Bread icon | TODO |
| Chicken Feed icon | TODO |
| Cow Feed icon | TODO |
| Scythe icon (starting tool, harvest action in tool menu) | TODO |
| Axe icon | TODO |
| Saw icon | TODO |
| Coin / money icon | TODO |
| XP / star icon (progression) | Kenney `star.png` / `star_outline.png` usable as placeholder | Created (placeholder) |

## 5. Background / Environment

No tileset — the ground is a single large hand-authored image.

| Asset | Notes | Status |
|---|---|---|
| Farm ground background (one big image) | Whole playable farm as one grassy image with baked-in decorative clutter (rocks, flowers, grass tufts) (§3) | TODO |
| Skyline background | Backdrop layer behind/around the farm ground | TODO |

## 6. UI

Kenney UI Pack exists at `SourceArt/kenney_ui-pack/` (Blue/Green/Grey/Red/Yellow × Default/Double): buttons (rect/round/square, many styles), checkboxes, sliders, arrows, input fields, dividers, star, and a few small icons (check/cross/play/repeat/up/down).

| Asset | Notes | Status |
|---|---|---|
| Generic buttons (shop entries, tab buttons, close, confirm/cancel) | Kenney `button_*` set | Created |
| Checkboxes / toggles | Kenney `check_*` set | Created |
| Sliders (e.g., future settings) | Kenney `slide_*` set | Created |
| Directional arrows (scrolling, pagination) | Kenney `arrow_*`, `icon_arrow_*` | Created |
| Text input fields | Kenney `input_*` set | Created |
| Dividers | Kenney `divider*` | Created |
| Confirm/cancel glyphs (checkmark, cross) | Kenney `icon_checkmark` / `icon_cross` | Created |
| Shop button glyph (bottom-left HUD, §11) | Cart/coin glyph to sit on a Kenney button | TODO |
| Tool menu popup (background + slot frames, §3.1/§11) | Contextual menu next to clicked object; Kenney round buttons can placeholder the slots | TODO |
| Shop overlay panel background (large tabbed window, §5/§11) | No large panels in Kenney pack | TODO |
| Shop tab strip styling (4 tabs; active/inactive states) | Can compose from Kenney buttons, may need custom | TODO |
| Item card/slot frame (shop entries, storage lists) | | TODO |
| "Owned / limit reached" state treatment (§5.2) | Greyed variant or lock badge | TODO |
| Money display widget (top HUD, §11) | Frame + coin icon | TODO |
| Level/XP display widget (level number + progress bar, §9.2) | | TODO |
| Progress bars (crop growth, production timers, XP) | Kenney sliders can placeholder; likely want custom | TODO |
| Delivery/sell panel background (§13.4) | | TODO |
| World-space bubbles (animal hungry / product ready / harvest ready) | Speech-bubble style indicators | TODO |

---

## Notes

- Kenney UI pack is a clean vector-style UI kit; verify it reads well next to the storybook-style game art (see `VISUAL_RULES.md`) before committing to it as the final UI skin. It is at minimum a solid mockup/placeholder base.
