#!/usr/bin/env python3
"""Art catalog builder — index game art assets so agents navigate by text, not vision.

Portable: stdlib + Pillow only. State lives under <root>/_catalog/:
  catalog.jsonl          one JSON line per current asset (grep this)
  pending_updates.jsonl  event log of changed/deleted source files (agents must surface unresolved ones)
  sheets/sheet_NNNN.png  labeled contact sheets, ~48 thumbnails each (stale ones are gc'd)
  <root>/ART_CATALOG.md  generated table of contents + usage instructions

Subcommands:
  scan                   incremental index: new/changed/deleted files, build sheets, regen TOC
                         (sheets that lost cells are repacked; unreferenced sheet files are deleted)
  repack                 rebuild ALL contact sheets from the current catalog (descriptions kept)
  todo                   JSON of not-yet-described entries, grouped by sheet (feed to vision agents)
  annotate FILE...       merge {path: {description, tags}} JSON files into the catalog, regen TOC
  resolve PATH --note N  mark a pending update as handled
  status                 one-line summary
"""

import argparse
import datetime
import hashlib
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Pillow is required: pip install pillow")

RASTER_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tga"}
EXCLUDE_DIRS = {"_catalog"}          # matched case-insensitively; ARCHIVE also skipped
COLS, ROWS = 8, 6                    # 48 thumbnails per sheet
CELL, CAPTION_H, PAD = 150, 26, 5    # sheet stays ~1240px wide — legible in one vision read
CHECKER = 12
WORKERS = os.cpu_count() or 4        # hashing + thumbnail render parallelism (Pillow/hash release the GIL)


def rel(path, repo):
    return Path(path).resolve().relative_to(Path(repo).resolve()).as_posix()


def catalog_dir(root):
    return Path(root) / "_catalog"


def load_catalog(root):
    """Return {path: entry}. File holds one line per current asset."""
    f = catalog_dir(root) / "catalog.jsonl"
    entries = {}
    if f.exists():
        for line in f.read_text(encoding="utf-8").splitlines():
            if line.strip():
                e = json.loads(line)
                entries[e["path"]] = e
    return entries


def save_catalog(root, entries):
    f = catalog_dir(root) / "catalog.jsonl"
    tmp = f.with_suffix(".tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        for path in sorted(entries):
            fh.write(json.dumps(entries[path], ensure_ascii=False) + "\n")
    tmp.replace(f)


def log_event(root, event):
    with (catalog_dir(root) / "pending_updates.jsonl").open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(event, ensure_ascii=False) + "\n")


def load_events(root):
    f = catalog_dir(root) / "pending_updates.jsonl"
    if not f.exists():
        return []
    return [json.loads(l) for l in f.read_text(encoding="utf-8").splitlines() if l.strip()]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def walk_assets(root):
    skipped = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames
                       if d.lower() not in EXCLUDE_DIRS and d.upper() != "ARCHIVE"]
        for name in filenames:
            ext = Path(name).suffix.lower()
            if ext in RASTER_EXTS:
                yield Path(dirpath) / name
            elif ext:
                skipped[ext] = skipped.get(ext, 0) + 1
    walk_assets.skipped = skipped


def caption_font():
    for name in ("arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, 12)
        except OSError:
            continue
    return ImageFont.load_default()


def make_thumb(img_path):
    """Thumbnail on a checkerboard. NEAREST both ways — pixel art must stay crisp."""
    box = CELL - 2 * PAD
    cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    d = ImageDraw.Draw(cell)
    for y in range(0, CELL, CHECKER):
        for x in range(0, CELL, CHECKER):
            c = (88, 90, 104, 255) if (x // CHECKER + y // CHECKER) % 2 else (74, 76, 90, 255)
            d.rectangle([x, y, x + CHECKER - 1, y + CHECKER - 1], fill=c)
    try:
        with Image.open(img_path) as src:
            im = src.convert("RGBA")
    except Exception:
        d.line([(PAD, PAD), (CELL - PAD, CELL - PAD)], fill=(220, 80, 80, 255), width=3)
        d.line([(CELL - PAD, PAD), (PAD, CELL - PAD)], fill=(220, 80, 80, 255), width=3)
        return cell
    if max(im.size) <= box:
        factor = max(1, box // max(im.size))
        im = im.resize((im.width * factor, im.height * factor), Image.NEAREST)
    else:
        im.thumbnail((box, box), Image.NEAREST)
    cell.alpha_composite(im, ((CELL - im.width) // 2, (CELL - im.height) // 2))
    return cell


def build_sheets(root, repo, placements, start_num):
    """placements: list of entries needing a (sheet, cell). Mutates them; returns sheet count.

    entry["path"] is repo-relative, so thumbnails are resolved against `repo` (not root's parent,
    which only coincided with repo when root sat exactly one level below it)."""
    font = caption_font()
    sheets_dir = catalog_dir(root) / "sheets"
    sheets_dir.mkdir(parents=True, exist_ok=True)
    per_sheet = COLS * ROWS
    n_sheets = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        for s in range(0, len(placements), per_sheet):
            batch = placements[s:s + per_sheet]
            num = start_num + n_sheets
            name = f"sheet_{num:04d}.png"
            rows = (len(batch) + COLS - 1) // COLS
            sheet = Image.new("RGBA", (COLS * CELL, rows * (CELL + CAPTION_H)), (44, 46, 58, 255))
            d = ImageDraw.Draw(sheet)
            thumbs = list(ex.map(lambda e: make_thumb(Path(repo) / e["path"]), batch))
            for i, entry in enumerate(batch):
                r, c = divmod(i, COLS)
                x, y = c * CELL, r * (CELL + CAPTION_H)
                sheet.alpha_composite(thumbs[i], (x, y))
                cell_id = f"r{r + 1}c{c + 1}"
                fname = Path(entry["path"]).name
                label = f"{cell_id} {fname}"
                if d.textlength(label, font=font) > CELL - 4:
                    while d.textlength(label + "…", font=font) > CELL - 4 and len(label) > len(cell_id) + 2:
                        label = label[:-1]
                    label += "…"
                d.text((x + 3, y + CELL + 2), label, font=font, fill=(235, 236, 244, 255))
                entry["sheet"], entry["cell"] = name, cell_id
            sheet.save(sheets_dir / name)
            n_sheets += 1
    return n_sheets


def next_sheet_num(root):
    sheets_dir = catalog_dir(root) / "sheets"
    if not sheets_dir.exists():
        return 1
    nums = [int(p.stem.split("_")[1]) for p in sheets_dir.glob("sheet_*.png")]
    return max(nums, default=0) + 1


def gc_sheets(root, entries):
    """Delete sheet files no catalog entry references. Returns count deleted."""
    sheets_dir = catalog_dir(root) / "sheets"
    if not sheets_dir.exists():
        return 0
    referenced = {e["sheet"] for e in entries.values() if e.get("sheet")}
    n = 0
    for f in sheets_dir.glob("sheet_*.png"):
        if f.name not in referenced:
            f.unlink()
            n += 1
    return n


def write_toc(root, repo):
    entries = load_catalog(root)
    unresolved = [e for e in load_events(root) if not e.get("resolved")]
    by_dir = {}
    for e in entries.values():
        by_dir.setdefault(str(Path(e["path"]).parent.as_posix()), []).append(e)
    root_rel = rel(root, repo)  # repo-relative, matching the paths stored in catalog.jsonl
    lines = [
        f"# Art Catalog — `{root_rel}/`",
        "",
        "Generated by the art-catalog skill. **Do not hand-edit** — regenerate with `scan`/`annotate`.",
        "",
        "## How agents should use this",
        "",
        f"1. **Find assets by grepping** `{root_rel}/_catalog/catalog.jsonl` (case-insensitive) for subject words —",
        "   descriptions and tags include synonyms. Each line: `path`, `w`/`h` (px), `description`, `tags`,",
        "   `sheet`+`cell` (where it appears on a contact sheet), `used_by` (game assets derived from it).",
        "2. **Only if text can't disambiguate candidates**, Read the referenced contact sheet in",
        f"   `{root_rel}/_catalog/sheets/` — one Read shows ~48 labeled thumbnails. Avoid opening",
        "   individual image files.",
        "3. When you import a source asset into the game project, append the game-side path to that",
        "   entry's `used_by` (via the annotate subcommand).",
        "",
    ]
    if unresolved:
        lines += [f"## ⚠ {len(unresolved)} unresolved source-art change(s)", "",
                  "Source files changed after being catalogued — derived game assets may be stale.",
                  f"See `{root_rel}/_catalog/pending_updates.jsonl`; surface these to the developer.", ""]
        for ev in unresolved[:20]:
            lines.append(f"- `{ev['path']}` ({ev['kind']}, detected {ev.get('detected', '?')})")
        lines.append("")
    described = sum(1 for e in entries.values() if e.get("description"))
    lines += ["## Contents", "",
              f"{len(entries)} raster assets, {described} described, "
              f"{len(list((catalog_dir(root) / 'sheets').glob('sheet_*.png')) if (catalog_dir(root) / 'sheets').exists() else [])} contact sheets.",
              ""]
    skipped_f = catalog_dir(root) / "skipped.json"
    skipped = json.loads(skipped_f.read_text(encoding="utf-8")) if skipped_f.exists() else None
    if skipped:
        lines += ["Skipped (not raster art): " +
                  ", ".join(f"{v}× {k}" for k, v in sorted(skipped.items(), key=lambda kv: -kv[1])), ""]
    lines += ["| Directory | Files | Described | Sheets |", "|---|---|---|---|"]
    for d in sorted(by_dir):
        es = by_dir[d]
        sheets = sorted({e["sheet"] for e in es if e.get("sheet")})
        srange = f"{sheets[0]}–{sheets[-1]}" if len(sheets) > 1 else (sheets[0] if sheets else "—")
        lines.append(f"| `{d}` | {len(es)} | {sum(1 for e in es if e.get('description'))} | {srange} |")
    (Path(root) / "ART_CATALOG.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def cmd_scan(root, repo):
    preexisting = Path(root).exists()
    catalog_dir(root).mkdir(parents=True, exist_ok=True)
    entries = load_catalog(root)
    seen, new, changed, dirty_sheets = set(), [], [], set()
    # Fast path (mtime_ns + size) filters unchanged files; survivors get hashed in parallel below.
    candidates = []  # (path, file, stat)
    for f in walk_assets(root):
        path = rel(f, repo)
        seen.add(path)
        st = f.stat()
        old = entries.get(path)
        if old and old.get("mtime") == st.st_mtime_ns and old["bytes"] == st.st_size:
            continue
        candidates.append((path, f, st))
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        digests = list(ex.map(lambda c: sha256(c[1]), candidates))
    for (path, f, st), digest in zip(candidates, digests):
        old = entries.get(path)
        if old and old["sha256"] == digest:               # touched but identical
            old["mtime"] = st.st_mtime_ns
            continue
        try:
            with Image.open(f) as im:
                w, h = im.size
        except Exception:
            w = h = 0
        entry = {"path": path, "w": w, "h": h, "bytes": st.st_size, "mtime": st.st_mtime_ns,
                 "sha256": digest, "sheet": None, "cell": None,
                 "version": (old["version"] + 1) if old else 1,
                 "description": "", "tags": [],
                 "used_by": old["used_by"] if old else []}
        if old:
            changed.append(entry)
            dirty_sheets.add(old.get("sheet"))
            log_event(root, {"kind": "updated", "path": path, "old_sha256": old["sha256"],
                             "sha256": digest, "used_by": old["used_by"],
                             "detected": datetime.date.today().isoformat(), "resolved": False})
        else:
            new.append(entry)
        entries[path] = entry
    (catalog_dir(root) / "skipped.json").write_text(
        json.dumps(getattr(walk_assets, "skipped", {})), encoding="utf-8")
    deleted = [p for p in entries if p not in seen]
    for p in deleted:
        log_event(root, {"kind": "deleted", "path": p, "used_by": entries[p]["used_by"],
                         "detected": datetime.date.today().isoformat(), "resolved": False})
        dirty_sheets.add(entries[p].get("sheet"))
        del entries[p]
    # Sheets that lost a cell (deleted/updated asset) go stale: repack their surviving
    # entries onto fresh sheets, then gc_sheets removes any sheet file nothing references.
    dirty_sheets.discard(None)
    displaced = [e for e in entries.values() if e.get("sheet") in dirty_sheets]
    placements = new + changed + displaced
    n_sheets = build_sheets(root, repo, placements, next_sheet_num(root)) if placements else 0
    save_catalog(root, entries)
    sheets_deleted = gc_sheets(root, entries)
    write_toc(root, repo)
    if not seen:
        print("warning: no raster art found under %s%s" % (
            root, "" if preexisting else " (folder did not exist and was created — check --root?)"),
            file=sys.stderr)
    print(json.dumps({"new": len(new), "updated": len(changed), "deleted": len(deleted),
                      "total": len(entries), "sheets_created": n_sheets,
                      "sheets_deleted": sheets_deleted,
                      "needs_description": sum(1 for e in entries.values() if not e["description"])}))


def cmd_repack(root, repo):
    """Rebuild every contact sheet from the current catalog. Descriptions/tags live in
    catalog.jsonl keyed by path, so nothing is lost — only sheet/cell references change."""
    entries = load_catalog(root)
    placements = [entries[p] for p in sorted(entries)]
    n_sheets = build_sheets(root, repo, placements, next_sheet_num(root)) if placements else 0
    save_catalog(root, entries)
    sheets_deleted = gc_sheets(root, entries)
    write_toc(root, repo)
    print(json.dumps({"total": len(entries), "sheets_created": n_sheets,
                      "sheets_deleted": sheets_deleted}))


def cmd_todo(root):
    by_sheet = {}
    for e in load_catalog(root).values():
        if not e.get("description") and e.get("sheet"):
            by_sheet.setdefault(e["sheet"], []).append(
                {"cell": e["cell"], "path": e["path"], "w": e["w"], "h": e["h"]})
    for cells in by_sheet.values():
        cells.sort(key=lambda c: (int(c["cell"][1:c["cell"].index("c")]), int(c["cell"][c["cell"].index("c") + 1:])))
    print(json.dumps(by_sheet, indent=1))


def cmd_annotate(root, repo, files):
    entries = load_catalog(root)
    applied, unknown = 0, []
    for f in files:
        mapping = json.loads(Path(f).read_text(encoding="utf-8"))
        for path, ann in mapping.items():
            e = entries.get(path)
            if not e:
                unknown.append(path)
                continue
            if ann.get("description"):
                e["description"] = ann["description"]
            if ann.get("tags"):
                e["tags"] = sorted(set(e["tags"]) | set(ann["tags"]))
            for u in ann.get("used_by", []):
                if u not in e["used_by"]:
                    e["used_by"].append(u)
            applied += 1
    save_catalog(root, entries)
    write_toc(root, repo)
    print(json.dumps({"annotated": applied, "unknown_paths": unknown}))


def cmd_resolve(root, repo, path, note):
    events, hit = load_events(root), False
    for ev in events:
        if ev["path"] == path and not ev.get("resolved"):
            ev["resolved"], ev["note"] = True, note
            hit = True
    f = catalog_dir(root) / "pending_updates.jsonl"
    f.write_text("".join(json.dumps(ev, ensure_ascii=False) + "\n" for ev in events), encoding="utf-8")
    write_toc(root, repo)
    print("resolved" if hit else f"no unresolved event for {path}", file=sys.stderr)


def cmd_status(root):
    entries = load_catalog(root)
    unresolved = [e for e in load_events(root) if not e.get("resolved")]
    print(json.dumps({"assets": len(entries),
                      "described": sum(1 for e in entries.values() if e.get("description")),
                      "unresolved_updates": len(unresolved)}))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", default="SourceArt", help="art folder (default: SourceArt)")
    ap.add_argument("--repo", default=".", help="repo root; catalog paths are relative to this")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("scan")
    sub.add_parser("repack")
    sub.add_parser("todo")
    p = sub.add_parser("annotate")
    p.add_argument("files", nargs="+")
    p = sub.add_parser("resolve")
    p.add_argument("path")
    p.add_argument("--note", default="")
    sub.add_parser("status")
    a = ap.parse_args()
    root = Path(a.repo) / a.root if not Path(a.root).is_absolute() else Path(a.root)
    {"scan": lambda: cmd_scan(root, a.repo), "repack": lambda: cmd_repack(root, a.repo),
     "todo": lambda: cmd_todo(root),
     "annotate": lambda: cmd_annotate(root, a.repo, a.files),
     "resolve": lambda: cmd_resolve(root, a.repo, a.path, a.note),
     "status": lambda: cmd_status(root)}[a.cmd]()


if __name__ == "__main__":
    main()
