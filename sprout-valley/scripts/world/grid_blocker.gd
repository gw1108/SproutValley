@tool
extends "res://scripts/world/grid_marker.gd"
class_name GridBlocker
## Editor-placed rectangle marking where art baked into the background
## painting (roads, cottage, well, fences, big trees) makes the farm
## permanently un-buildable. Move, resize (`cells`) and freely ROTATE it:
## every grid cell the rotated rectangle covers by at least
## `blocker_min_coverage` (balance.csv) of its area is blocked. The editor
## outlines exactly those cells; nothing draws at runtime.

@export var cells := Vector2i.ONE:
	set(v):
		cells = v.max(Vector2i.ONE)
		queue_redraw()

var _last_xform := Transform2D()

func _init() -> void:
	snap_to_grid = false

func _process(dt: float) -> void:
	super(dt)
	# keep the blocked-cell preview live while dragging/rotating
	if Engine.is_editor_hint() and global_transform != _last_xform:
		_last_xform = global_transform
		queue_redraw()

func blocked_cells(grid: FarmGrid) -> Array[Vector2i]:
	var min_cov := BalanceData.get_value("blocker_min_coverage", 0.02)
	return covered_cells(grid.origin, grid.cell_size, grid.cols, grid.rows, min_cov)

func covered_cells(origin: Vector2, cell: float, grid_cols: int, grid_rows: int, min_cov: float) -> Array[Vector2i]:
	## Grid cells whose overlap with this node's (possibly rotated/scaled)
	## rectangle is at least min_cov of a cell's area. The area threshold also
	## keeps an axis-aligned blocker whose edge lies exactly on a cell
	## boundary from bleeding into the neighboring row/column.
	var t := global_transform
	var size := Vector2(cells) * cell
	var poly := PackedVector2Array([
		t * Vector2.ZERO, t * Vector2(size.x, 0), t * size, t * Vector2(0, size.y),
	])
	var aabb := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		aabb = aabb.expand(p)
	var c0 := ((aabb.position - origin) / cell).floor()
	var c1 := ((aabb.end - origin) / cell).ceil()
	var min_area := min_cov * cell * cell
	var out: Array[Vector2i] = []
	for cy in range(maxi(0, int(c0.y)), mini(grid_rows, int(c1.y))):
		for cx in range(maxi(0, int(c0.x)), mini(grid_cols, int(c1.x))):
			var p := origin + Vector2(cx, cy) * cell
			var cell_poly := PackedVector2Array([
				p, p + Vector2(cell, 0), p + Vector2(cell, cell), p + Vector2(0, cell),
			])
			var area := 0.0
			for piece in Geometry2D.intersect_polygons(poly, cell_poly):
				area += _poly_area(piece)
			if area >= min_area:
				out.append(Vector2i(cx, cy))
	return out

static func _poly_area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var j := (i + 1) % p.size()
		a += p[i].x * p[j].y - p[j].x * p[i].y
	return absf(a) * 0.5

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var r := Rect2(Vector2.ZERO, Vector2(cells) * EDITOR_CELL)
	draw_rect(r, Color(0.9, 0.2, 0.15, 0.25))
	draw_rect(r, Color(0.9, 0.2, 0.15, 0.9), false, 2.0)
	# outline the actual grid cells this rect blocks (drawn in world space)
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	for c in covered_cells(EDITOR_ORIGIN, EDITOR_CELL, EDITOR_COLS, EDITOR_ROWS, 0.02):
		var p := EDITOR_ORIGIN + Vector2(c) * EDITOR_CELL
		draw_rect(Rect2(p, Vector2.ONE * EDITOR_CELL).grow(-2.0), Color(0.9, 0.35, 0.1, 0.8), false, 1.5)
