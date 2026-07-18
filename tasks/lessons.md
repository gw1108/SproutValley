# Lessons

### Chroma keying green subjects
ffmpeg's `despill=green` desaturates green across the WHOLE subject (not just edges) — force a BLUE screen for any plant/grass-heavy sprite; the engine's 25% green-dominance test misses soft storybook greens, so decide by subject, not by measured fraction.

### Art catalog staleness
The catalog can list files that no longer exist on disk (regeneration churn deletes them) — verify each needed source file with Glob/dir listing before building an asset pipeline around catalog entries.

### Simulated input in Godot probes
Synthetic events via `Input.parse_input_event` don't move `get_global_mouse_position()` (use `Input.warp_mouse` too) and drag motions get merged unless `Input.use_accumulated_input = false`; game code should read positions from the event, not the Input singleton.

### agy target paths
agy's shell tool runs from its own scratch dir, not the launch cwd — always give agy ABSOLUTE file paths for outputs (relative paths land in `~/.gemini/antigravity-cli/scratch/`).

