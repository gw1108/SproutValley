"""Prepare game-ready assets from SourceArt into sprout-valley/assets.

Trims transparent borders, slices multi-cell sheets by alpha-gap detection,
and downscales masters to the target resolutions from design/art-todo.md.
Rerun after art regenerates. Requires Pillow + numpy.

Assets whose SourceArt masters were deleted upstream (regen churn) are NOT
regenerated here; the previously derived files in sprout-valley/assets are
kept as-is and noted in comments below.
"""
import os
import numpy as np
from PIL import Image

SRC = r"C:\GameDev\SproutValley\SourceArt"
DST = r"C:\GameDev\SproutValley\sprout-valley\assets"

def load(rel):
    return Image.open(os.path.join(SRC, rel)).convert("RGBA")

def trim(img, thresh=8):
    a = np.array(img)[:, :, 3]
    ys, xs = np.where(a > thresh)
    if len(xs) == 0:
        return img
    return img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

def fit(img, max_w, max_h):
    scale = min(max_w / img.width, max_h / img.height)
    if scale >= 1.0:
        return img
    return img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)

def save(img, rel):
    path = os.path.join(DST, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"{rel}  {img.width}x{img.height}")

def key_dominant_colors(img, n_colors=2, tol=38):
    """Key out the n most common flat colors (outer background + card squares)."""
    data = np.array(img)
    rgb = data[:, :, :3].astype(int)
    flat = rgb.reshape(-1, 3)
    # dominant colors via coarse quantization
    q = (flat // 16).astype(np.int32)
    keys = q[:, 0] * 10000 + q[:, 1] * 100 + q[:, 2]
    uniq, counts = np.unique(keys, return_counts=True)
    mask = np.zeros(rgb.shape[:2], dtype=bool)
    for k in uniq[np.argsort(counts)[::-1][:n_colors]]:
        sel = keys == k
        color = flat[sel].mean(axis=0)
        mask |= np.linalg.norm(rgb - color, axis=2) < tol
    data[:, :, 3] = np.where(mask, 0, data[:, :, 3])
    return Image.fromarray(data)

def slice_cells(img, n, thresh=8):
    """Split a horizontal strip into n cells: equal split when the width divides
    evenly (generator strips have equal cells), else by widest alpha gaps."""
    if img.width % n == 0:
        cw = img.width // n
        return [trim(img.crop((i * cw, 0, (i + 1) * cw, img.height))) for i in range(n)]
    a = np.array(img)[:, :, 3]
    col_has = (a > thresh).any(axis=0)
    # find runs of empty columns
    gaps = []
    start = None
    for x, filled in enumerate(col_has):
        if not filled and start is None:
            start = x
        elif filled and start is not None:
            gaps.append((start, x))
            start = None
    if start is not None:
        gaps.append((start, len(col_has)))
    # interior gaps only
    interior = [g for g in gaps if g[0] > 0 and g[1] < len(col_has)]
    interior.sort(key=lambda g: g[1] - g[0], reverse=True)
    cuts = sorted((g[0] + g[1]) // 2 for g in interior[: n - 1])
    if len(cuts) != n - 1:
        # fall back to equal split
        cuts = [round(img.width * i / n) for i in range(1, n)]
    edges = [0] + cuts + [img.width]
    return [trim(img.crop((edges[i], 0, edges[i + 1], img.height))) for i in range(n)]

def single(rel_src, rel_dst, w, h):
    save(fit(trim(load(rel_src)), w, h), rel_dst)

def sheet(rel_src, names, w, h, subdir):
    img = load(rel_src)
    cells = slice_cells(img, len(names))
    for name, cell in zip(names, cells):
        save(fit(cell, w, h), os.path.join(subdir, name + ".png"))

# --- World objects ---
single("generated/world/tree-small.png", r"world\tree_small.png", 160, 160)
# tree_stump, farm_plot, delivery_box: masters deleted; derived kept.
# (large tree + saw were removed from the game entirely.)

# --- Buildings ---
single("house_2.png", r"buildings\player_home.png", 256, 256)
single("barn.png", r"buildings\barn.png", 256, 256)
single("bakery.png", r"buildings\bakery.png", 256, 256)
single("chicken_coop.png", r"buildings\chicken_coop.png", 256, 256)
# silo, cow_pasture, dairy_barn, feed_mill: masters deleted; derived kept.

# --- Animals ---
single("generated/animals/chicken-idle-keyed-ffmpeg.png", r"animals\chicken_idle.png", 96, 96)
single("generated/animals/chicken-eat-keyed-ffmpeg.png", r"animals\chicken_eat.png", 96, 96)
single("generated/animals/cow-idle-keyed-ffmpeg.png", r"animals\cow_idle.png", 128, 128)
single("generated/animals/cow-eat-keyed-ffmpeg.png", r"animals\cow_eat.png", 128, 128)

# --- Crops ---
# One shared "planted" look with 2 variations (picked randomly on planting),
# then one mature sprite per crop. No intermediate stage.
single("planted_crops_1.png", r"crops\planted_1.png", 96, 96)
single("planted_crops_2.png", r"crops\planted_2.png", 96, 96)
# mature_corn.png is a golden grain block — it is the wheat mature sprite.
single("mature_corn.png", r"crops\wheat_mature.png", 96, 96)
single("mature_beets.png", r"crops\beets_mature.png", 96, 96)
single("mature_cabbage.png", r"crops\cabbage_mature.png", 96, 96)

# --- Icons ---
single("beets_icon.png", r"icons\icon_beets.png", 96, 96)
# no dedicated cabbage icon: center-crop one head from the mature cluster
_cab = trim(load("mature_cabbage.png"))
_side = min(_cab.width, _cab.height)
_cx = _cab.width // 2
save(fit(trim(_cab.crop((_cx - _side // 2, 0, _cx + _side // 2, _cab.height))), 96, 96),
     r"icons\icon_cabbage.png")
# icon_beets_seed / icon_cabbage_seed are PLACEHOLDER copies of the old corn /
# soybean seed pouches (masters deleted) — replace when seed-pouch art lands.
sheet("generated/icons/icons-goods-keyed-ffmpeg.png",
      ["icon_egg", "icon_milk", "icon_butter", "icon_bread"], 96, 96, r"icons")
sheet("generated/icons/icons-feed-keyed-ffmpeg.png",
      ["icon_chicken_feed", "icon_cow_feed"], 96, 96, r"icons")
# tools sheet only exists as raw (tan bg + khaki card squares) — key both shades.
# The sheet's 3rd cell (saw) is skipped: the saw was removed from the game.
tools_img = key_dominant_colors(load("generated/icons/icons-tools-raw.png"))
for name, cell in zip(["icon_scythe", "icon_axe"], slice_cells(tools_img, 3)):
    save(fit(cell, 96, 96), os.path.join(r"icons", name + ".png"))
# icon_wheat, seed pouches, icon_coin: masters deleted; derived kept.

# --- UI ---
single("generated/ui/ui-shop-glyph.png", r"ui\shop_glyph.png", 96, 96)
single("generated/ui/ui-settings-icon.png", r"ui\settings_icon.png", 96, 96)
single("generated/ui/ui-shop-panel-keyed-ffmpeg.png", r"ui\shop_panel.png", 1440, 1440)
sheet("generated/ui/ui-tabs-keyed-ffmpeg.png", ["tab_active", "tab_inactive"], 192, 96, r"ui")
single("generated/ui/ui-lock-badge-keyed-ffmpeg.png", r"ui\lock_badge.png", 96, 96)
single("generated/ui/ui-level-widget-keyed-ffmpeg.png", r"ui\level_widget.png", 480, 320)
single("generated/ui/ui-delivery-panel-keyed-ffmpeg.png", r"ui\delivery_panel.png", 1280, 720)
# item_card, money_widget, progress_bar, bubbles: masters deleted; derived kept.

# --- Backgrounds ---
# Single full-scene painting; roads and edge decor are baked in (no separate
# skyline / ground / road layers anymore).
save(load("empty_farm_landscape.png"), r"background\farm_landscape.png")

print("\nDone.")
