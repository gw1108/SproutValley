import os
from PIL import Image

image_path = r"C:\Users\georg\.gemini\antigravity\brain\ceb37d7c-95dd-477a-b281-537d710ffba4\rts_cozy_farm_clean_placement_1784327411767.jpg"
output_dir = r"c:\GameDev\SproutValley\sprites"

os.makedirs(output_dir, exist_ok=True)
img = Image.open(image_path).convert("RGBA")
w, h = img.size

# Let's define bounding boxes (xmin, ymin, xmax, ymax) based on 1376x768 layout:
crops = {
    # UI Elements
    "ui_settings_cog.png": (w - 120, 10, w - 10, 120),
    "ui_shop_button.png": (10, h - 130, 130, h - 10),

    # Main Buildings
    "building_greenhouse_ghost.png": (int(w * 0.42), int(h * 0.20), int(w * 0.65), int(h * 0.55)),
    "building_red_barn.png": (int(w * 0.12), int(h * 0.15), int(w * 0.38), int(h * 0.52)),
    "building_windmill.png": (int(w * 0.68), int(h * 0.10), int(w * 0.88), int(h * 0.48)),

    # Trees
    "tree_pine_large.png": (int(w * 0.02), int(h * 0.35), int(w * 0.15), int(h * 0.70)),
    "tree_deciduous_1.png": (int(w * 0.85), int(h * 0.30), int(w * 0.98), int(h * 0.65)),
    "tree_deciduous_2.png": (int(w * 0.75), int(h * 0.50), int(w * 0.90), int(h * 0.85)),

    # Ground & Crop Plots
    "farmland_tilled_patch.png": (int(w * 0.35), int(h * 0.52), int(w * 0.62), int(h * 0.82)),
    "wheat_crops_patch.png": (int(w * 0.15), int(h * 0.55), int(w * 0.38), int(h * 0.85)),
    "grass_terrain_tile.png": (int(w * 0.45), int(h * 0.82), int(w * 0.58), int(h * 0.95)),
    "fence_wooden_segment.png": (int(w * 0.30), int(h * 0.48), int(w * 0.42), int(h * 0.62))
}

exported_files = []
for name, box in crops.items():
    cropped = img.crop(box)
    out_path = os.path.join(output_dir, name)
    cropped.save(out_path)
    exported_files.append((name, box, cropped.size))
    print(f"Extracted {name}: {cropped.size} at box {box}")
