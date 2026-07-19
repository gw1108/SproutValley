@tool
extends "res://scripts/world/grid_marker.gd"
class_name TreeSpawn
## Editor-placed spawn point for one starting tree (1x1 cell). Main spawns a
## FarmTree here on load if the cell is still free. Toggle `big` in the
## inspector to author a big (saw-only) tree instead of a small (axe) one.
## The node sits on the CENTRE of its cell's diamond.

@export var big := false:
	set(value):
		big = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var poly := editor_footprint_poly(Vector2i.ONE)
	draw_colored_polygon(poly, Color(0.2, 0.7, 0.25, 0.2))
	var outline := poly.duplicate()
	outline.append(outline[0])
	draw_polyline(outline, Color(0.15, 0.55, 0.2, 0.9), 2.0)
	# canopy + trunk glyph — big trees draw a taller conifer so the designer can
	# tell the two sizes apart at a glance
	if big:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -22), Vector2(-11, 4), Vector2(11, 4)]),
			Color(0.16, 0.5, 0.22, 0.95))
		draw_rect(Rect2(-3, 4, 6, 12), Color(0.4, 0.27, 0.13, 0.95))
	else:
		draw_circle(Vector2(0, -8), 10, Color(0.2, 0.6, 0.25, 0.9))
		draw_rect(Rect2(-3, 0, 6, 14), Color(0.45, 0.3, 0.15, 0.9))
