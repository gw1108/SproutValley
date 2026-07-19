@tool
extends "res://scripts/world/grid_marker.gd"
class_name StructureSpawn
## Editor-placed spawn point for a pre-built structure. `building_id` must be
## a key of ItemDB.buildings; Main spawns that structure here on load. The
## node sits on the CENTRE of the structure's anchor cell.

## Editor preview only (autoloads are unavailable in the editor) — the runtime
## footprint comes from ItemDB.buildings. Keep in sync when buildings change.
const PREVIEW_FOOTPRINTS := {
	"player_home": Vector2i(2, 1), "barn": Vector2i(2, 1),
	"delivery_box": Vector2i(1, 1), "chicken_coop": Vector2i(1, 1),
	"dairy_barn": Vector2i(2, 1), "bakery": Vector2i(1, 1),
}

@export var building_id := "":
	set(v):
		building_id = v
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var fp: Vector2i = PREVIEW_FOOTPRINTS.get(building_id, Vector2i(1, 1))
	var poly := editor_footprint_poly(fp)
	draw_colored_polygon(poly, Color(0.2, 0.5, 0.95, 0.22))
	var outline := poly.duplicate()
	outline.append(outline[0])
	draw_polyline(outline, Color(0.2, 0.5, 0.95, 0.9), 2.0)
	var label := building_id if building_id != "" else "<no id>"
	draw_string(ThemeDB.fallback_font, Vector2(-EDITOR_HALF.x * 0.5, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.08, 0.2, 0.5))
