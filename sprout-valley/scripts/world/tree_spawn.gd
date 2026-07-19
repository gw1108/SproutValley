@tool
extends "res://scripts/world/grid_marker.gd"
class_name TreeSpawn
## Editor-placed spawn point for one starting tree (1x1 cell). Main spawns a
## FarmTree here on load if the cell is still free.

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var r := Rect2(Vector2.ZERO, Vector2.ONE * EDITOR_CELL)
	draw_rect(r, Color(0.2, 0.7, 0.25, 0.2))
	draw_rect(r, Color(0.15, 0.55, 0.2, 0.9), false, 2.0)
	# canopy + trunk glyph
	draw_circle(Vector2(24, 18), 10, Color(0.2, 0.6, 0.25, 0.9))
	draw_rect(Rect2(21, 26, 6, 14), Color(0.45, 0.3, 0.15, 0.9))
