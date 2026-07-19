# Sprout Valley — Game Design Document

**Version:** 0.1 (Vertical Slice)
**Genre:** Top-down 2D farming simulator
**Reference Games:** Hay Day, Stardew Valley
**Target Scope:** Thin, playable vertical slice demonstrating the core farming → processing → delivery → money loop.

---

## 1. Overview

Sprout Valley is a cozy 2D farming simulator viewed from a top-down camera. The player runs a farm, clears land, plants crops, raises animals, processes raw goods into refined products, and delivers goods for money. There is **no on-screen player character** — the player acts on the world directly by clicking things (Hay Day style). The goal of the slice is simple and open-ended: **run your farm and earn more and more money.**

This document scopes only the vertical slice. Systems are intentionally minimal but complete enough to demonstrate the full gameplay loop end to end.

### 1.1 Design Pillars
- **Cozy, low-pressure progression** — no fail states; the player grows at their own pace.
- **A readable core loop** — plant/raise → harvest → process → sell → reinvest.
- **Meaningful spatial choices** — land is limited and partly blocked, so placement matters.

---

## 2. Core Gameplay Loop

1. **Clear** blockers (trees) using tools to open up buildable land.
2. **Buy** seeds, farm plots, animal homes, animals, and production buildings from the shop.
3. **Grow** crops on farm plots and **raise** animals in their homes.
4. **Harvest** crops and collect animal products (→ shared inventory, viewed at the Player Home).
5. **Process** raw goods into refined products in production buildings.
6. **Deliver** goods to earn money.
7. **Reinvest** money into more land, buildings, and animals — repeat.

---

## 3. Camera & World

- **View:** Top-down 2D, orthographic.
- **World:** A single fixed farm plot (the player's land).
- **Ground & backdrop:** The farm ground is **one large grassy background image** (not a tileset), with decorative clutter (rocks, flowers, grass tufts) baked in. A **road** is a separate sprite drawn on top of the ground — it acts as a permanent placement blocker (see §4). A separate **skyline background** sits behind/around the farm ground.
- **Player Character:** None. The player interacts with the farm similar to an RTS game.
- **Navigation:** None — the camera is **fixed**; the entire farm fits on one screen. No panning or scrolling.
- **Art reference:** `SourceArt/cozy_farm_visualization.jpg` shows the intended look of the farm. Note it depicts a **mid-game** state — some trees already removed, and the cow pasture and chicken coop placed. It also shows a **greenhouse; there is no greenhouse in this game** — do not build one from the reference.
- **Starting Structures (pre-placed, free):**
  - **Player Home** — the player's residence; tapping it opens the **inventory panel** (§10).

> **Cut content (2026-07):** the Barn and Silo were originally free starting storage buildings (Silo = crops, Barn = everything else). The **Silo is cut entirely** — all goods live in one shared inventory viewed at the Player Home. The **Barn is now a purchasable animal home for cows** (replacing the Cow Pasture, which is cut).

### 3.1 Interaction Model (Click → Tool Menu)

All world interaction is done by **clicking objects directly**:

- Clicking an interactable object pops up a small **tool menu** next to it, listing the tools/actions that apply to that object. Objects with no applicable interaction show no menu.
- Only tools the player **owns** appear (or unowned ones appear disabled — implementer's choice for the slice).
- Picking a tool/action from the menu performs it immediately on the clicked object.
- **Example — Farm Plot:** clicking a farm plot offers the **Scythe** (harvest, if the crop is grown) and the **seeds** in the player's possession (plant, if the plot is empty).
- **Example — Tree:** clicking a tree offers the **Axe** (see §4).

---

## 4. Blockers & Tools

Trees are scattered across the farm and act as **placement blockers** — the player cannot place plots or buildings on tiles occupied by trees.

The **road** is also a blocker: it behaves like a very large tree that is **unremovable** — no tool applies to it, and it can never be built on.

- To remove a blocker, the player must own the appropriate **tool**, then select it from the tree's click menu (§3.1).
- **Tools:**
  - **Scythe** — harvests grown crops on farm plots. **The player starts with the Scythe** (free, not sold in the shop).
  - **Axe** — chops down trees (purchasable).
- Using the Axe on a tree destroys the blocker and frees the underlying tile for building/planting.

> **Cut content (2026-07):** the game originally had two tree sizes — small trees (Axe) and large 2×2 trees felled by a purchasable **Saw**. The large tree and the Saw were cut; there is now a single 1×1 tree type and the Axe is the only blocker-removal tool.

---

## 5. Shop System

The shop is opened via a **button in the bottom-left** of the HUD. It opens a full-screen (or large) overlay with **tabbed categories**.

### 5.1 Shop Tabs

| Tab | Contents |
|-----|----------|
| **Farm Seeds** | Corn Seed, Wheat Seed, Soybean Seed, Potato Seed, Axe (Saw: cut content, §4) |
| **Animal Homes** | Chicken Coop, Barn, Dairy Barn, Bakery, Feed Mill |
| **Animals** | Chickens, Cows |
| **Production Buildings** | Dairy Barn, Bakery, Feed Mill |

> Note: Some "buildings" straddle categories. For the slice, animal housing lives under **Animal Homes** and processors under **Production Buildings**. Tools (Axe) share the **Farm Seeds** tab to keep the shop at 4 tabs (see §13.1).

### 5.2 Purchase Limits

| Item | Max Owned |
|------|-----------|
| Farm Plot | 25 |
| Chicken Coop | 1 |
| Barn | 1 |
| Dairy Barn | 1 |
| Bakery | 1 |
| Feed Mill | 1 |
| Seeds | Unlimited (consumable) |

When a limit is reached, the item is shown as owned/disabled in the shop.

---

## 6. Farming (Crops)

- The player buys **Farm Plots** (max 25) and places them on cleared land.
- Seeds are planted by clicking an empty plot and choosing a seed from its tool menu (§3.1); crops grow over time and are harvested by clicking the plot and choosing the **Scythe**.
- Harvested crops go into the shared **inventory** (viewed at the Player Home, §10).
- **Harvest yield:** planting 1 seed returns **2 of the product** on harvest (e.g., plant 1 Corn → harvest 2 Corn). This gives the player a growing surplus to sell and reinvest.

### 6.1 Crop Types
- **Corn** (from Corn Seed)
- **Wheat** (from Wheat Seed)
- **Soybean** (from Soybean Seed)
- **Potato** (from Potato Seed)

Each crop has: seed cost, grow time, and harvest yield/value (to be tuned).

---

## 7. Animals

- Animals are housed in animal homes and produce goods over time.
- Animal products go into the shared **inventory** (§10).

| Home | Animal | Produces | Production Time |
|------|--------|----------|-----------------|
| Chicken Coop | Chicken | Eggs | ~20s |
| Barn | Cow | Milk | ~60s |

### 7.1 Feeding (Required)
Animals **require feed to produce**. The cycle is:
1. A hungry animal **eats** one unit of its feed (Chicken Feed or Cow Feed).
2. Eating starts a production cycle: **~20s for chickens**, **~60s for cows**.
3. When the cycle completes, the product (Egg / Milk) is deposited in the **inventory** and the animal becomes hungry again.

Animals **only eat when they are not currently producing** — an animal mid-cycle ignores feed until its product is ready. If no feed is available, the animal simply waits (idle, no product) until feed is supplied. This keeps the no-fail cozy feel: animals never die, they just pause.

Chickens and cows eat **different feeds** produced by the Feed Mill, with cow feed being a higher, more expensive tier (see §8).

---

## 8. Production Buildings

Production buildings convert raw goods (crops, animal products) into refined, higher-value products.

| Building | Input(s) | Output |
|----------|----------|--------|
| **Dairy Barn** | Milk | Butter |
| **Bakery** | Wheat | Bread |
| **Feed Mill** | Crops | Chicken Feed / Cow Feed |

The Feed Mill produces **two distinct feeds**; cow feed is the higher, more expensive tier:

| Feed | Recipe | Craft Time | Eaten By |
|------|--------|-----------|----------|
| Chicken Feed | 2 Wheat → 1 Chicken Feed | 20s | Chickens |
| Cow Feed | 2 Corn + 1 Soybean → 1 Cow Feed | 45s | Cows |

Feed produced by the Feed Mill sustains animal production, closing the loop between crops and animals (see §7.1).

---

## 9. Deliveries, Money & XP

- The player fulfills **orders/deliveries** to convert goods into **both money and XP**.
- For the slice: a simple delivery mechanism (e.g., a delivery box / order board) that accepts goods and pays out.
- Money is the single currency, spent in the shop. XP drives the player's **level**.

### 9.1 The Goal
The player's objective is to **earn as much money and XP as possible** — there is no win condition or fail state. Money and level are the two headline progression numbers the player is always trying to grow.

### 9.2 XP & Leveling
Fulfilling an order grants XP based on the goods delivered. XP is measured in a **corn-equivalent unit**: selling 1 Corn through an order = **1 XP**. Higher-value/processed goods grant proportionally more XP (see XP column in §13.5).

**Leveling curve (logarithmic).** The XP required to advance a level grows logarithmically, so early levels come fast and the curve progressively flattens — noticeably by ~level 10 and very flat past ~level 40:

```
xpToNextLevel(L) = round( 4 * (1 + ln(L)) )      // L = current level, starting at 1
```

| From Level | XP to Next | ≈ Corn to sell |
|-----------|-----------|-----------------|
| 1 | 4 | ~4 |
| 2 | 7 | ~7 |
| 5 | 10 | ~10 |
| 10 | 13 | ~13 |
| 20 | 16 | ~16 |
| 40 | 19 | ~19 |

- **Level 1 → 2** costs ~4 corn's worth of orders (the intended fast first level).
- Increments shrink each level (the log "leveling off"): the jump from level 5→6 is small, and by level 40 each additional level costs only a little more than the last.
- Formula and constants are first-pass and tunable during playtest.

### 9.3 Economy Goals
- Raw goods sell cheap; processed goods sell for more money **and** more XP, rewarding investment in production buildings.
- Starting money should afford: a few seeds, 1–2 farm plots, and a first tool — enough to bootstrap the loop.

---

## 10. Storage / Inventory

All goods (crops, animal products, processed goods, seeds, tools) live in one shared **inventory**. Tapping the **Player Home** opens a read-only inventory panel listing every owned item with its count.

For the slice, storage capacity may be treated as effectively unlimited, or given generous caps.

> **Cut content (2026-07):** the split Silo (crops) / Barn (everything else) storage buildings were cut in favor of the single Player-Home-viewed inventory. The Barn now serves as the cow home (§7).

---

## 11. UI / HUD

- **Bottom-left:** Shop button.
- **Money display:** Persistent, likely top of screen.
- **Shop overlay:** Tabbed (Farm Seeds, Animal Homes, Animals, Production Buildings).
- **Tool menu popup:** Small contextual menu that appears next to a clicked interactable object, listing applicable tools/actions (§3.1).
- **Placement mode:** After purchasing a placeable item, the player enters a placement state to position it on valid (cleared, unoccupied, non-road) tiles.

---

## 12. Vertical Slice Scope Checklist

**In scope:**
- Fixed top-down camera showing the whole farm (no player character, no panning)
- Click-to-interact tool menu (Scythe harvesting, seed planting, Axe)
- Tree blockers + Axe removal
- Shop overlay with 4 tabs and purchase limits
- 4 crop types with plant/grow/harvest → inventory
- Chicken Coop + Barn, 2 animal types → inventory
- Dairy Barn, Bakery, Feed Mill processing
- Delivery-for-money mechanism
- Shared inventory viewed at the Player Home
- Player Home (inventory viewer)

**Cut content:**
- Large (2×2) trees and the Saw tool (see §4)
- Silo + Barn starting storage buildings and the Cow Pasture (see §3, §10)

**Out of scope (post-slice):**
- Multiple crop tiers / seasons / weather
- NPCs, quests, relationships
- Saving/loading beyond a basic prototype save
- Tool differentiation & upgrades
- Expanded animal/building variety beyond limits listed

---

## 13. Design Decisions (Resolved)

These were previously open questions. Recommendations below are the intended slice behavior.

### 13.1 Tools in the shop UI
**Decision:** Keep the shop at **4 tabs**; the Axe lives in the **Farm Seeds** tab alongside consumable seeds. Simpler UI, no extra tab to build for the slice. (The Saw was cut, see §4.)

### 13.2 Production recipes
**Decision:** Single-input recipes where possible (simple, readable, easy to balance).

| Building | Recipe | Craft Time |
|----------|--------|-----------|
| Feed Mill (Chicken Feed) | 2 Wheat → 1 Chicken Feed | 20s |
| Feed Mill (Cow Feed) | 2 Corn + 1 Soybean → 1 Cow Feed | 45s |
| Dairy Barn | 3 Milk → 1 Butter | 60s |
| Bakery | 2 Wheat → 1 Bread | 45s |

> Cow Feed is a higher tier (multi-crop, longer craft) than Chicken Feed, matching the more valuable Milk output.

### 13.3 Feed requirement
**Decision:** Feed is **required**. Animals eat one unit of their feed to start a production cycle (~20s chickens, ~60s cows), deposit the product, then become hungry again. Animals only eat when not already producing, and simply idle (no death, no penalty) when feed is unavailable — preserving the cozy no-fail feel while making the Feed Mill essential. See §7.1.

### 13.4 Delivery UX
**Decision:** **Fixed sell prices** via a delivery box / sell panel for the slice. The player drops goods in and receives money at set rates. Rotating orders (bonus-paying requests) are a strong post-slice addition but add UI and balancing overhead not needed to prove the loop.

### 13.5 Starting money & balancing table
**Decision:** Start with **150 coins** — enough for a couple of plots, a handful of seeds, and a first tool to bootstrap the loop.

**Seeds (consumable) & crops**

Each seed yields **2 crops** on harvest (see §6). Sell/XP values are per unit.

| Crop | Seed Cost | Grow Time | Harvest Qty | Sell (raw) | XP (per unit) |
|------|-----------|-----------|-------------|-----------|----------------|
| Wheat | 5 | 30s | 2 | 12 | 0.75 |
| Corn | 8 | 45s | 2 | 18 | 1 |
| Soybean | 10 | 60s | 2 | 24 | 1.5 |
| Potato | 12 | 75s | 2 | 30 | 2 |

**Placeables & buildings**

| Item | Cost | Notes |
|------|------|-------|
| Farm Plot | 25 (scaling ok later) | Max 25 |
| Scythe | Free (starting tool) | Harvests crops; not sold in shop |
| Axe | 40 | Tool |
| ~~Saw~~ | ~~40~~ | Cut content (see §4) |
| Chicken Coop | 150 | Max 1 |
| Barn | 250 | Max 1; home for cows |
| Feed Mill | 200 | Max 1 |
| Dairy Barn | 300 | Max 1 |
| Bakery | 300 | Max 1 |
| Chicken | 30 | Housed in coop |
| Cow | 60 | Housed in barn |

**Products (processed) sell values**

| Product | Sell | XP (per unit) |
|---------|------|----------------|
| Egg | 15 | 1 |
| Milk | 20 | 1.5 |
| Chicken Feed | (used internally) | — |
| Cow Feed | (used internally) | — |
| Butter | 75 | 5 |
| Bread | 50 | 3.5 |

> All numbers are first-pass and meant for tuning during playtest. The intent: raw goods bootstrap early money and XP; processed goods (Butter, Bread) are the clear profit **and** XP tier that justifies buying production buildings. XP is corn-equivalent (1 Corn = 1 XP), so the level curve in §9.2 is expressed directly in goods sold.
