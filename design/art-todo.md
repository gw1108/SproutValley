# Art Asset TODO — Sprout Valley (Vertical Slice)

Derived from `design/GDD.md`. Status values: **TODO** | **Created**.
"Created" = asset already exists under `SourceArt/` (see `SourceArt/_catalog/catalog.jsonl`).
Reminder: this is a storybook-style illustration game (soft cartoon, not pixel art) — see `VISUAL_RULES.md` before importing/rendering anything. `SourceArt/cozy_farm_visualization.jpg` is the look reference (note: it shows a greenhouse — there is no greenhouse in this game).

**Game size:** the Godot base viewport is **960×540**. The *Target res* column below is the intended in-game source size (~2× the largest on-screen size so art stays crisp under window stretch, per `VISUAL_RULES.md`).
**Generation note:** agy/Gemini masters come out ~1024px regardless of request; keep the master in `SourceArt/generated/` and downscale to the target on import (offline resize for sliced sheets). Bundle related images into one sprite-sheet request (equal square cells, no divider lines) to save quota — e.g. all 3 growth stages of a crop are ONE request.
Generated assets live in `SourceArt/generated/<category>/`; `<name>-keyed-ffmpeg.png` is the transparent deliverable (ffmpeg keying is the project standard; green subjects are keyed on a BLUE screen).

---

## 1. Sprites — Animals

No player character — the game is click-driven (GDD §3/§3.1).

| Asset | Notes (GDD ref) | Target res | Status |
|---|---|---|---|
| Chicken (idle / eat) | Lives in Chicken Coop (§7). Future redo: bundle idle+eat as one 2-cell sheet | 96×96 per pose | Created |
| Cow (idle / eat) | Lives in Cow Pasture (§7). Future redo: bundle idle+eat as one 2-cell sheet | 128×128 per pose | Created |

## 2. Sprites — World Objects & Buildings

| Asset | Notes (GDD ref) | Target res | Status |
|---|---|---|---|
| Road (sprite drawn on top of ground background) | Permanent blocker (§3/§4) | 256×128 per segment | Created |
| Small tree (blocker, removed by Axe) | §4 | 160×160 | Created |
| Large tree (blocker, removed by Saw) | §4 | 224×224 | Created |
| Tree removal effect (stump) | §4 | 96×96 | Created |
| Player Home | Pre-placed flavor structure (§3) | 256×256 | Created |
| Barn (storage) | Stores animal/processed goods (§10) | 256×256 | Created |
| Silo (storage) | Stores crops (§10) | 160×256 | Created |
| Farm Plot (empty tilled soil) | Placeable, max 25 (§6) | 128×128 | Created |
| Chicken Coop | Animal home (§7). Using hand-made `chicken_coop_illustrated` / `chicken_coop-keyed` | 256×256 | Created |
| Cow Pasture (fence/enclosure) | Animal home (§7) | 384×256 | Created |
| Dairy Barn | Production building (§8) | 256×256 | Created |
| Bakery | Production building (§8) | 256×256 | Created |
| Feed Mill | Production building (§8) | 256×256 | Created |
| Delivery box / order drop-off | Sell point (§9, §13.4) | 160×160 | Created |
| Placement-mode tile highlight (valid green / invalid red) | No asset needed — runtime modulate/tint of the building sprite (§11) | — | Created (runtime) |

## 3. Sprites — Crops (per crop: growth stages + harvestable state)

3 growth stages each (sprout → mid → mature/harvestable). **One 3-cell sheet request per crop**, sliced on import.

| Asset | Target res | Status |
|---|---|---|
| Corn — growth stages (3-cell sheet) | 96×96 per stage | Created |
| Wheat — growth stages (3-cell sheet) | 96×96 per stage | Created |
| Soybean — growth stages (3-cell sheet) | 96×96 per stage | Created |
| Potato — growth stages (3-cell sheet) | 96×96 per stage | Created |

## 4. Sprites — Items / Goods Icons

Needed for shop entries, storage views, and delivery/sell panel (§5, §9, §13.5). **Bundled into sheet requests**: crop icons (4-cell), seed pouches (4-cell), goods (egg/milk/butter/bread, 4-cell), feed sacks (2-cell), tools (3-cell), coin (single).

| Asset | Target res | Status |
|---|---|---|
| Corn, Wheat, Soybean, Potato — harvested crop icons (4-cell sheet `icons-crops`) | 96×96 each | Created |
| Corn, Wheat, Soybean, Potato — seed icons (4-cell sheet `icons-seeds`) | 96×96 each | Created |
| Egg / Milk / Butter / Bread icons (4-cell sheet `icons-goods`) | 96×96 each | Created |
| Chicken Feed / Cow Feed icons (2-cell sheet `icons-feed`) | 96×96 each | Created |
| Scythe / Axe / Saw icons (3-cell sheet `icons-tools`) | 96×96 each | Created |
| Coin / money icon | 96×96 | Created |
| XP / star icon (progression) | Kenney `star.png` / `star_outline.png` usable as placeholder | Created (placeholder) |

## 5. Background / Environment

No tileset — the ground is a single large hand-authored image.

| Asset | Notes | Target res | Status |
|---|---|---|---|
| Farm ground background (one big image) | Whole playable farm as one grassy image with baked-in decorative clutter (§3). **Source PNG missing on disk (regen churn)** — game currently ships a procedural placeholder from `tools/prepare_assets.py`; replace when the Gemini 3.1 Pro regeneration lands | 1920×1080 | TODO (placeholder in game) |
| Skyline background | Backdrop layer behind/around the farm ground | 1920×540 | Created |

## 6. UI

Kenney UI Pack exists at `SourceArt/kenney_ui-pack/` (buttons, checkboxes, sliders, arrows, input fields, dividers, star, small icons) — those rows stay Created below.

| Asset | Notes | Target res | Status |
|---|---|---|---|
| Generic buttons (shop entries, tab buttons, close, confirm/cancel) | Kenney `button_*` set | native | Created |
| Checkboxes / toggles | Kenney `check_*` set | native | Created |
| Sliders (e.g., future settings) | Kenney `slide_*` set | native | Created |
| Directional arrows (scrolling, pagination) | Kenney `arrow_*`, `icon_arrow_*` | native | Created |
| Text input fields | Kenney `input_*` set | native | Created |
| Dividers | Kenney `divider*` | native | Created |
| Confirm/cancel glyphs (checkmark, cross) | Kenney `icon_checkmark` / `icon_cross` | native | Created |
| Shop button glyph (bottom-left HUD, §11) | Basket glyph to sit on a Kenney button | 96×96 | Created |
| Tool menu popup (background + slot frames, §3.1/§11) | Contextual menu next to clicked object | 480×192 | Created |
| Shop overlay panel background (large tabbed window, §5/§11) | | 1440×840 | Created |
| Shop tab strip styling (active/inactive, 2-cell sheet `ui-tabs`) | 4 tabs reuse the two states | 192×64 each | Created |
| Item card/slot frame (shop entries, storage lists) | | 160×160 | Created |
| "Owned / limit reached" state treatment (§5.2) | Lock badge over greyed (runtime) card | 96×96 | Created |
| Money display widget (top HUD, §11) | Frame + coin icon | 320×96 | Created |
| Level/XP display widget (level number + progress bar, §9.2) | | 480×96 | Created |
| Progress bars (crop growth, production timers, XP) | Frame + fill, sliced at runtime | 384×48 | Created |
| Delivery/sell panel background (§13.4) | | 1280×720 | Created |
| World-space bubbles (hungry / product ready / harvest ready, 3-cell sheet `ui-bubbles`) | Speech-bubble indicators | 96×96 each | Created |

---

## Notes

- Kenney UI pack is a clean vector-style UI kit; verify it reads well next to the storybook-style game art (see `VISUAL_RULES.md`) before committing to it as the final UI skin. It is at minimum a solid mockup/placeholder base.
- ffmpeg `despill=green` desaturates green across the whole subject — any plant/grass-heavy sprite must be keyed on a **blue** screen (see `tasks/lessons.md`).
- Quality flags (2026-07-17): `icons-crops`, `icons-goods`, `icons-tools` (flat style) and `farm-ground` (grass tufts too large/busy) were generated on Gemini 3.5 Flash during a quota outage; a regeneration on Gemini 3.1 Pro is scheduled — review these four after it lands.
