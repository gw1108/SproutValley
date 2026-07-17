# Visual & Rendering Rules

Non-negotiable rendering rules for this project. These are **technical** rules (how art is rendered), from art *direction* (color, value, composition, shape language), which lives in `.agents/2d-game-art-direction/references/art-design-guide.md`. For the step-by-step procedure to turn a sprite sheet into a playable animation, use the `import_sprite_sheet_animation` skill.

---

## Aesthetic

This is a **2D game** with a **storybook-style illustration** look: soft cartoon, hand-drawn feel, smooth gradients and outlines — **not** pixel art.

- Art is authored at **high resolution** and is meant to scale smoothly. Smooth (linear) filtering is the intended look; hard nearest-neighbor edges are **not** wanted.
- Set 2D textures to filter **linearly**. Use `CanvasItem.texture_filter = TEXTURE_FILTER_LINEAR` (or `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` for textures that are minified — see below), or set the project default to Linear so nodes can inherit it.
- **Never** force textures to Nearest to "sharpen" them — that reintroduces a pixel-art look this project does not use.
- Applies to **all** 2D textures: sprites, tilesets, VFX, and UI.

## Scaling — smooth, not pixel-locked

- **Non-integer node `scale` and arbitrary window stretch are fine.** There is no requirement to keep pixels square or use integer scale factors.
- Because art scales freely, prefer authoring/importing source art at a size **at or above** its largest on-screen size, then scaling down — scaling up a small illustration will look soft.
- Enable **Mipmaps** on textures that are drawn smaller than their native size (world sprites, decor, distant elements) to avoid shimmer/aliasing when minified. Pair mipmaps with `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`.

### Resizing source art — only when necessary

- **Default: import at native (high) resolution.** Let it scale down at runtime.
- **Resize only if** the sheet is **unreasonably large** for the project (huge per-frame px / VRAM cost).
- For **sliced sprite sheets**, cell sizes should still divide evenly (`width / cols`, `height / rows` are whole numbers) so slicing is clean. Prefer **offline** resizing (slice → resize each frame → re-pack) to avoid cross-frame seam bleed; Godot's per-texture Import `Process → Size Limit` is acceptable for **single, non-sliced** textures.

## Import defaults

When importing a 2D texture:

- **Compress → Mode:** Lossless (VRAM-compressed is acceptable for large backgrounds/decor if artifacts are not visible).
- **Mipmaps → Generate:** on for textures that will be minified; off is acceptable for UI/textures always drawn at native size.
- **Filter:** Linear. In Godot 4 filtering is a node/project setting, not an import flag — set the project default to Linear, or apply `TEXTURE_FILTER_LINEAR` / `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` per node.
