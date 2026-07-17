# Visual & Rendering Rules

Non-negotiable rendering rules for this project. These are **technical** rules (how art is rendered), from art *direction* (color, value, composition, shape language), which lives in `.agents/2d-game-art-direction/references/art-design-guide.md`. For the step-by-step procedure to turn a sprite sheet into a playable animation, use the `import_sprite_sheet_animation` skill.

---

## Aesthetic

This is a **2D game**.

- **Never** override a node's `CanvasItem.texture_filter` to `TEXTURE_FILTER_LINEAR`,
  `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`, or any other linear/mipmap mode. Leave sprite nodes at the inherited default (`TEXTURE_FILTER_PARENT_NODE` → resolves to Nearest).
- **No mipmaps.** Do not enable *Mipmaps → Generate* on texture imports.
- Applies to **all** 2D textures: sprites, tilesets, VFX, and UI.

## Scaling — keep it pixel-consistent

- Prefer **integer** scale factors and a fixed base resolution with integer window stretch
  (Project Settings → Display → Window → Stretch) so pixels stay square and uniform.
- Avoid arbitrary **runtime** scaling of pixel art (non-integer node `scale`) — it produces uneven pixels and shimmer.

### Resizing source art — only when necessary

- **Default: do not resize.** Import art at its native size and let the grid slice it as-is.
- **Resize only if** one of these is true:
  - the sheet has **non-integer cell sizes** — `width / cols` or `height / rows` is not a whole number (e.g. `Poof.png` 512×512 at 3×3 → 170.67; `Sparkle.png` 4096×3277 at 5×4 → 819.2×819.25), or
  - the sheet is **unreasonably large** for the project (huge per-frame px / VRAM cost).
- **When you do resize, the goal is to** (a) make every cell a whole-pixel size — fixing the
  non-integer grid — and/or (b) bring the sheet down to a reasonable size in the Godot project.
- Prefer **offline** resizing (slice the sheet, resize each frame, re-pack) — it yields clean integer cells and avoids cross-frame seam bleed. Godot's per-texture Import `Process → Size Limit` is acceptable only for **single, non-sliced** textures where the exact grid doesn't matter; it scales the whole image proportionally and won't guarantee integer cells.

## Import defaults for pixel art

When importing a 2D texture:

- **Compress → Mode:** Lossless.
- **Mipmaps → Generate:** off.
- **Filter:** do not set a per-node override. In Godot 4 filtering is a node/project setting, not an import flag — leave the project Nearest default in effect.
