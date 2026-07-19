---
name: art-catalog
description: Build or refresh the searchable catalog of art assets under SourceArt/ (or another art folder) — index images, generate labeled contact sheets, write vision descriptions, and wire the catalog into CLAUDE.md. Use when new art is added, when asked to catalog/index art assets, or when pending source-art updates need review.
---

# Art Catalog

Purpose: agents should find and understand art assets by **grepping text**, not by opening image files. This skill maintains that text layer: `<root>/_catalog/catalog.jsonl` (one JSON line per asset: path, pixel size, detailed description, synonym tags, contact-sheet location, `used_by` game assets), labeled contact sheets (~48 thumbnails each, kept free of stale cells), a generated `<root>/ART_CATALOG.md` TOC, and a `pending_updates.jsonl` event log for source files that changed after being catalogued.

The script is `scripts/art_catalog.py` (stdlib + Pillow; `pip install pillow` if missing). Default root is `SourceArt/`, override with `--root`. Only raster formats (png/jpg/jpeg/gif/webp/bmp/tga) are catalogued; editor sources (psd/pdn/svg/…) are skipped and counted in the TOC. Folders named `ARCHIVE` and `_catalog` are excluded.

## Workflow

1. **Scan** (incremental — safe to run any time):
   `python .claude/skills/art-catalog/scripts/art_catalog.py scan`
   Fast path is mtime+size; only mismatches get hashed, so thousands of unchanged files scan in seconds. New/changed files are placed on **new** sheets. Deletions and updates are gc'd automatically: any sheet that lost a cell has its surviving entries repacked onto fresh sheets (descriptions are preserved — they live in the catalog, not the sheet), and sheet files no entry references are deleted. Output JSON reports `new`, `updated`, `deleted`, `sheets_created`, `sheets_deleted`, `needs_description`. If sheets ever drift out of sync anyway (e.g. from an older version of this script), `... repack` rebuilds every sheet from the current catalog without losing any descriptions.

2. **Describe** (only if `needs_description > 0`):
   Run `... todo` — JSON of `{sheet: [{cell, path, w, h}, ...]}` for undescribed entries.
   **Fan out one subagent per sheet, in parallel.** Each subagent gets: its sheet path (`<root>/_catalog/sheets/<sheet>`), its cell→path manifest inline, and these instructions:
   - Read the sheet image once. Cells are labeled `rNcN` matching the manifest; trust the manifest for exact paths (captions are truncated).
   - For each cell, write a **detailed** description (2–3 sentences: what it depicts, art style, colors, shape/orientation, notable variants or state, and a plausible game use) and 4–8 lowercase tags **including synonyms** an agent might grep for (e.g. a chest gets `chest, crate, box, container, loot`).
   - Write the result to a JSON file `{path: {"description": ..., "tags": [...]}, ...}` at a scratchpad path you assign, and return only that file path.
   Then merge everything in one call:
   `... annotate <file1.json> <file2.json> ...`

3. **Wire into CLAUDE.md** (idempotent): grep the repo's `CLAUDE.md` for `ART_CATALOG`. If absent, append this section (adjust the root path if not `SourceArt`):

   ```markdown
   ## Art assets (SourceArt/)
   - To find or understand art assets, do NOT browse or open files under `SourceArt/` directly. Grep `SourceArt/_catalog/catalog.jsonl` (case-insensitive, descriptions+tags include synonyms) and see `SourceArt/ART_CATALOG.md` for how to read it. Only Read a contact sheet from `SourceArt/_catalog/sheets/` when text can't disambiguate candidates; never Read individual art files.
   - If `SourceArt/_catalog/pending_updates.jsonl` contains entries with `"resolved": false`, source art changed after game assets may have been derived from it — surface this to the developer before art-related work, and mark handled ones with the `resolve` subcommand.
   - After adding/changing files under `SourceArt/`, run the `art-catalog` skill.
   ```

4. **Verify completeness**: after annotating, run `... status` and confirm `described == assets`. Subagents sometimes drop entries while claiming full coverage — if there's a gap, list the undescribed paths (grep `"description": ""` in catalog.jsonl) and fill them (re-describe, or derive from an identical-artwork sibling entry).

5. **Report**: state counts (total assets, newly described, unresolved updates) and list any unresolved `pending_updates` entries prominently.

## Maintaining links and updates

- When an asset from the art folder is imported into the game project, record the derived file: annotate with `{"<source path>": {"used_by": ["<game asset path>"]}}`.
- `resolve <path> --note "reimported"` marks a pending update handled.
- Descriptions survive rescans; a *changed* file gets a fresh entry (empty description, new sheet cell) plus a pending-update event — so step 2 naturally re-describes it.

## Notes

- Sheets use NEAREST scaling on a checkerboard — pixel art stays crisp and transparency is visible. Keep sheets under ~1300px wide if you change the grid; larger montages get downscaled by vision into illegibility.
- Don't hand-edit `catalog.jsonl` or `ART_CATALOG.md`; go through `annotate` so the TOC stays in sync.
- Aesthetic choices are the developer's: agents pick assets by catalog facts and any style rules in CLAUDE.md, not by taste.
