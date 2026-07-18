"""Prepare game-ready assets from SourceArt/generated into sprout-valley/assets.

Trims transparent borders, slices multi-cell sheets by alpha-gap detection,
and downscales masters to the target resolutions from design/art-todo.md.
Rerun after art regenerates. Requires Pillow + numpy.
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

def key_background(img, tol=30):
    """Remove a flat background by flood-filling from the image borders.

    Only background connected to the border is removed, so subject pixels of a
    similar color (e.g. wooden handles on a tan backdrop) survive.
    """
    from collections import deque
    data = np.array(img)
    rgb = data[:, :, :3].astype(int)
    corners = [rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]]
    bg = np.mean(corners, axis=0)
    near = np.linalg.norm(rgb - bg, axis=2) < tol
    h, w = near.shape
    visited = np.zeros_like(near, dtype=bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if near[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if near[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y-1, x), (y+1, x), (y, x-1), (y, x+1)):
            if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))
    data[:, :, 3] = np.where(visited, 0, data[:, :, 3])
    return Image.fromarray(data)

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
single("generated/world/tree-small-keyed-ffmpeg.png", r"world\tree_small.png", 160, 160)
single("generated/world/tree-large-keyed-ffmpeg.png", r"world\tree_large.png", 224, 224)
single("generated/world/tree-stump-keyed-ffmpeg.png", r"world\tree_stump.png", 96, 96)
single("generated/world/farm-plot-keyed-ffmpeg.png", r"world\farm_plot.png", 128, 128)
single("generated/world/road-keyed-ffmpeg.png", r"world\road.png", 512, 256)
single("generated/world/delivery-box-keyed-ffmpeg.png", r"world\delivery_box.png", 160, 160)

# --- Buildings ---
single("generated/buildings/player-home-keyed-ffmpeg.png", r"buildings\player_home.png", 256, 256)
single("generated/buildings/barn-keyed-ffmpeg.png", r"buildings\barn.png", 256, 256)
single("generated/buildings/silo-keyed-ffmpeg.png", r"buildings\silo.png", 160, 256)
single("generated/buildings/chicken_coop-keyed.png", r"buildings\chicken_coop.png", 256, 256)
single("generated/buildings/cow-pasture-keyed-ffmpeg.png", r"buildings\cow_pasture.png", 384, 256)
single("generated/buildings/dairy-barn-keyed.png", r"buildings\dairy_barn.png", 256, 256)
single("generated/buildings/bakery-keyed-ffmpeg.png", r"buildings\bakery.png", 256, 256)
single("generated/buildings/feed-mill-keyed-ffmpeg.png", r"buildings\feed_mill.png", 256, 256)

# --- Animals ---
single("generated/animals/chicken-idle-keyed-ffmpeg.png", r"animals\chicken_idle.png", 96, 96)
single("generated/animals/chicken-eat-keyed-ffmpeg.png", r"animals\chicken_eat.png", 96, 96)
single("generated/animals/cow-idle-keyed-ffmpeg.png", r"animals\cow_idle.png", 128, 128)
single("generated/animals/cow-eat-keyed-ffmpeg.png", r"animals\cow_eat.png", 128, 128)

# --- Crops (3 growth stages each) ---
for crop in ["corn", "wheat", "soybean", "potato"]:
    sheet(f"generated/crops/{crop}-stages-keyed-ffmpeg.png",
          [f"{crop}_stage1", f"{crop}_stage2", f"{crop}_stage3"], 96, 96, r"crops")

# --- Icons ---
# crops icon sheet: keyed-ffmpeg is broken; raw is a 2x2 grid on teal with card squares
crops_img = key_dominant_colors(load("generated/icons/icons-crops-raw.png"))
cw, ch = crops_img.width // 2, crops_img.height // 2
for name, (cx, cy) in zip(["icon_corn", "icon_wheat", "icon_soybean", "icon_potato"],
                          [(0, 0), (1, 0), (0, 1), (1, 1)]):
    cell = trim(crops_img.crop((cx * cw, cy * ch, (cx + 1) * cw, (cy + 1) * ch)))
    save(fit(cell, 96, 96), os.path.join(r"icons", name + ".png"))
sheet("generated/icons/icons-seeds-keyed-ffmpeg.png",
      ["icon_corn_seed", "icon_wheat_seed", "icon_soybean_seed", "icon_potato_seed"], 96, 96, r"icons")
sheet("generated/icons/icons-goods-keyed-ffmpeg.png",
      ["icon_egg", "icon_milk", "icon_butter", "icon_bread"], 96, 96, r"icons")
sheet("generated/icons/icons-feed-keyed-ffmpeg.png",
      ["icon_chicken_feed", "icon_cow_feed"], 96, 96, r"icons")
# tools sheet only exists as raw (tan bg + khaki card squares) — key both shades
tools_img = key_dominant_colors(load("generated/icons/icons-tools-raw.png"))
for name, cell in zip(["icon_scythe", "icon_axe", "icon_saw"], slice_cells(tools_img, 3)):
    save(fit(cell, 96, 96), os.path.join(r"icons", name + ".png"))
single("generated/icons/icon-coin-keyed-ffmpeg.png", r"icons\icon_coin.png", 96, 96)

# --- UI ---
single("generated/ui/ui-shop-glyph-keyed-ffmpeg.png", r"ui\shop_glyph.png", 96, 96)
single("generated/ui/ui-shop-panel-keyed-ffmpeg.png", r"ui\shop_panel.png", 1440, 1440)
sheet("generated/ui/ui-tabs-keyed-ffmpeg.png", ["tab_active", "tab_inactive"], 192, 96, r"ui")
single("generated/ui/ui-item-card-keyed-ffmpeg.png", r"ui\item_card.png", 160, 160)
single("generated/ui/ui-lock-badge-keyed-ffmpeg.png", r"ui\lock_badge.png", 96, 96)
single("generated/ui/ui-money-widget-keyed-ffmpeg.png", r"ui\money_widget.png", 320, 214)
single("generated/ui/ui-level-widget-keyed-ffmpeg.png", r"ui\level_widget.png", 480, 320)
single("generated/ui/ui-progress-bar-keyed-ffmpeg.png", r"ui\progress_bar.png", 384, 216)
single("generated/ui/ui-delivery-panel-keyed-ffmpeg.png", r"ui\delivery_panel.png", 1280, 720)
sheet("generated/ui/ui-bubbles-keyed-ffmpeg.png",
      ["bubble_hungry", "bubble_ready", "bubble_harvest"], 96, 96, r"ui")

# --- Backgrounds ---
# farm-ground.png source is missing (quality-flagged, awaiting regeneration on
# Gemini 3.1 Pro — see design/art-todo.md Notes). Until it lands, synthesize a
# soft storybook-ish grass placeholder so the game is playable.
def make_grass_placeholder(w=1920, h=1080, seed=7):
    rng = np.random.default_rng(seed)
    yy = np.linspace(0, 1, h)[:, None]
    base_top = np.array([124, 186, 98], dtype=float)
    base_bot = np.array([98, 158, 76], dtype=float)
    grad = base_top[None, :] * (1 - yy) + base_bot[None, :] * yy  # (h, 3)
    img = np.repeat(grad[:, None, :], w, axis=1)
    # large soft blotches for hand-painted feel: sum of a few low-freq noise layers
    noise = np.zeros((h, w))
    for cells in (6, 12, 24):
        small = rng.normal(0, 1, (cells, round(cells * w / h)))
        layer = np.array(Image.fromarray(((small - small.min()) / (np.ptp(small) + 1e-9) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), dtype=float)
        noise += (layer / 255 - 0.5) / cells * 6
    img += noise[..., None] * np.array([18, 26, 14])
    img = np.clip(img, 0, 255).astype(np.uint8)
    out = np.dstack([img, np.full((h, w), 255, np.uint8)])
    return Image.fromarray(out)

save(make_grass_placeholder(), r"background\farm_ground.png")
save(load("generated/background/skyline.png"), r"background\skyline.png")

print("\nDone.")
