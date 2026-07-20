# Lessons

### Chroma keying green subjects
ffmpeg's `despill=green` desaturates green across the WHOLE subject (not just edges) — force a BLUE screen for any plant/grass-heavy sprite; the engine's 25% green-dominance test misses soft storybook greens, so decide by subject, not by measured fraction.

### Art catalog staleness
The catalog can list files that no longer exist on disk (regeneration churn deletes them) — verify each needed source file with Glob/dir listing before building an asset pipeline around catalog entries.

### Simulated input in Godot probes
Synthetic events via `Input.parse_input_event` don't move `get_global_mouse_position()` (use `Input.warp_mouse` too) and drag motions get merged unless `Input.use_accumulated_input = false`; game code should read positions from the event, not the Input singleton.

### Godot class_name of brand-new scripts
A `class_name` added this session isn't in the global class cache until an editor scan — running the game directly fails with "Could not find base class"; use `extends "res://path.gd"` (path-based) for new base classes, or run `godot --headless --editor --quit` first.

### BootProbe click coordinates
FarmGrid has origin (48, 120), not (0, 0) — when computing world/cell positions for probe clicks, apply the origin offset or placement clicks silently land on road/out-of-bounds cells.

### BootProbe run mode
Run BootProbe WITHOUT `--headless` — it needs a render context to save screenshots; with `--headless` it hangs and writes no image.

### PowerShell script encoding
Save `.ps1` files as UTF-8 **with BOM** — Windows PowerShell 5.1 reads BOM-less files as ANSI, so an em dash (`—`) misdecodes to `â€”` whose last char is a smart quote that PowerShell parses as a string delimiter, causing bogus "missing terminator" errors.

### Godot CSVs read via FileAccess
Godot auto-imports `.csv` as translations, so exports pack the generated `.translation` files but NOT the raw CSV — any `FileAccess.open("res://*.csv")` works in-editor but fails in builds. Set the file's `.import` to `importer="keep"` (and delete stray `*.translation` siblings) for every data CSV.

### agy target paths
agy's shell tool runs from its own scratch dir, not the launch cwd — always give agy ABSOLUTE file paths for outputs (relative paths land in `~/.gemini/antigravity-cli/scratch/`).

