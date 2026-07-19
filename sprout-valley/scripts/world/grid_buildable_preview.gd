@tool
extends "res://scripts/world/grid_marker.gd"
class_name GridBuildablePreview
## Editor-only overlay that fills every farm-grid diamond you CAN build on
## with a translucent green tint. It is the complement of the red/orange
## diamonds the GridBlocker nodes outline: a cell is shown here iff no blocker
## covers it. Purely a design aid — nothing draws at runtime, and this node
## feeds no occupancy (blockers remain the source of truth via
## main.gd._apply_blockers).

func _init() -> void:
	snap_to_grid = false

func _process(_dt: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	# Blockers move/rotate independently of this node, so redraw every frame in
	# the editor so the buildable set stays in sync while a designer drags them.
	queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var blocked := _blocked_cells()
	# draw in world space so the tint sits on the true grid regardless of where
	# this node is parked in the scene (mirrors GridBlocker's cell outlines)
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	var fill := Color(0.55, 0.8, 0.2, 0.22)
	var line := Color(0.6, 0.85, 0.25, 0.7)
	for c in FarmGrid.lattice_cells_in_rect(editor_origin(), EDITOR_HALF, EDITOR_RECT):
		if blocked.has(c):
			continue
		var poly := editor_cell_poly(c)
		# shrink the diamond slightly toward its centre so neighbours don't merge
		var center := editor_cell_center(c)
		var inset := PackedVector2Array()
		for p in poly:
			inset.append(center + (p - center) * 0.94)
		draw_colored_polygon(inset, fill)
		inset.append(inset[0])
		draw_polyline(inset, line, 1.5)

func _blocked_cells() -> Dictionary:
	## Union of the cells every GridBlocker in the edited scene covers.
	var out: Dictionary = {}
	for b in _find_blockers():
		for c in b.covered_cells(editor_origin(), EDITOR_HALF, EDITOR_RECT, 0.02):
			out[c] = true
	return out

func _find_blockers() -> Array:
	var root := get_tree().edited_scene_root if get_tree() != null else null
	if root == null:
		root = get_tree().current_scene if get_tree() != null else self
	var out: Array = []
	_collect_blockers(root, out)
	return out

func _collect_blockers(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is GridBlocker:
		out.append(node)
	for child in node.get_children():
		_collect_blockers(child, out)
