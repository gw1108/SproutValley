import os
import numpy as np
from PIL import Image, ImageChops

image_path = r"C:\Users\georg\.gemini\antigravity\brain\ceb37d7c-95dd-477a-b281-537d710ffba4\rts_cozy_farm_clean_placement_1784327411767.jpg"
output_dir = r"c:\GameDev\SproutValley\sprites"
os.makedirs(output_dir, exist_ok=True)

img = Image.open(image_path).convert("RGBA")
w, h = img.size

def make_transparent_ui(crop_img, bg_color_sample=None, tolerance=35):
    """Makes background transparent for UI elements based on corner sampling."""
    data = np.array(crop_img)
    # Extract RGB and Alpha
    rgb = data[:, :, :3].astype(int)
    
    if bg_color_sample is None:
        # Sample average of 4 corners
        corners = [data[0, 0, :3], data[0, -1, :3], data[-1, 0, :3], data[-1, -1, :3]]
        bg_color = np.mean(corners, axis=0)
    else:
        bg_color = np.array(bg_color_sample)

    # Compute Euclidean distance to background color
    dist = np.linalg.norm(rgb - bg_color, axis=2)
    alpha = np.where(dist < tolerance, 0, 255).astype(np.uint8)
    
    # Smooth edges slightly
    data[:, :, 3] = alpha
    return Image.fromarray(data)

def autocrop(im, bg_color=(0, 0, 0, 0)):
    """Auto-crops empty transparent pixels."""
    bg = Image.new(im.mode, im.size, bg_color)
    diff = ImageChops.difference(im, bg)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

# High-precision bounding boxes tailored to 1376x768
sprites_def = {
    # UI Elements
    "ui_settings_cog.png": {"box": (w - 110, 15, w - 15, 110), "transparent_ui": True},
    "ui_shop_button.png": {"box": (15, h - 120, 120, h - 15), "transparent_ui": True},

    # Main Buildings & Placement Ghost
    "building_greenhouse_placement_ghost.png": {"box": (int(w * 0.44), int(h * 0.22), int(w * 0.63), int(h * 0.52)), "transparent_ui": False},
    "building_red_barn.png": {"box": (int(w * 0.15), int(h * 0.18), int(w * 0.36), int(h * 0.48)), "transparent_ui": False},
    "building_windmill.png": {"box": (int(w * 0.70), int(h * 0.12), int(w * 0.86), int(h * 0.45)), "transparent_ui": False},

    # Trees & Nature Assets
    "tree_pine_large.png": {"box": (int(w * 0.03), int(h * 0.38), int(w * 0.14), int(h * 0.68)), "transparent_ui": False},
    "tree_deciduous_right.png": {"box": (int(w * 0.86), int(h * 0.32), int(w * 0.97), int(h * 0.62)), "transparent_ui": False},
    "tree_autumn_orange.png": {"box": (int(w * 0.76), int(h * 0.52), int(w * 0.89), int(h * 0.80)), "transparent_ui": False},

    # Ground, Fence & Crops
    "farmland_tilled_plot.png": {"box": (int(w * 0.36), int(h * 0.54), int(w * 0.60), int(h * 0.80)), "transparent_ui": False},
    "wheat_crops_patch.png": {"box": (int(w * 0.17), int(h * 0.56), int(w * 0.36), int(h * 0.82)), "transparent_ui": False},
    "wooden_fence_segment.png": {"box": (int(w * 0.32), int(h * 0.49), int(w * 0.40), int(h * 0.60)), "transparent_ui": False},
    "grass_terrain_background_seamless.png": {"box": (int(w * 0.62), int(h * 0.65), int(w * 0.74), int(h * 0.77)), "transparent_ui": False}
}

manifest = []
for filename, info in sprites_def.items():
    box = info["box"]
    crop = img.crop(box)
    
    if info.get("transparent_ui", False):
        crop = make_transparent_ui(crop)
        crop = autocrop(crop)
    
    save_path = os.path.join(output_dir, filename)
    crop.save(save_path, "PNG")
    manifest.append({
        "name": filename,
        "path": save_path,
        "width": crop.width,
        "height": crop.height
    })
    print(f"Saved {filename} ({crop.width}x{crop.height} px)")

print(f"\nAll {len(manifest)} sprites extracted successfully to {output_dir}!")
