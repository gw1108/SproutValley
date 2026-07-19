@tool
extends "res://scripts/world/grid_marker.gd"
class_name GridBlocker
## Editor-placed rectangle marking where art baked into the background
## painting (roads, cottage, well, fences, big trees) makes the farm
## permanently un-buildable. Move, resize (`cells`) and freely ROTATE it:
## every grid diamond the rotated rectangle covers by at least
## `blocker_min_coverage` (balance.csv) of a diamond's area is blocked. The
## editor outlines exactly those diamonds; nothing draws at runtime.

## Base size of the rectangle, in 48-px units (legacy square-cell size, kept so
## the blockers already authored over the painted roads keep their geometry).
const UNIT := 48.0

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
	return covered_cells(grid.iso_origin, grid.half, grid.play_rect, min_cov)

func covered_cells(iso_origin: Vector2, half: Vector2, play_rect: Rect2, min_cov: float) -> Array[Vector2i]:
	## Grid diamonds whose overlap with this node's (possibly rotated/scaled)
	## rectangle is at least min_cov of a diamond's area. The area threshold
	## keeps a blocker whose edge grazes a diamond from bleeding into it.
	var t := global_transform
	var size := Vector2(cells) * UNIT
	var poly := PackedVector2Array([
		t * Vector2.ZERO, t * Vector2(size.x, 0), t * size, t * Vector2(0, size.y),
	])
	# candidate cell range: lattice-coord bounds of the rect's corners, padded
	# one cell so diamonds straddling the hull edge are still tested
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in poly:
		var f := FarmGrid.lattice_frac(p, iso_origin, half)
		lo = lo.min(f)
		hi = hi.max(f)
	var min_area := min_cov * 2.0 * half.x * half.y   # diamond area = 2*hx*hy
	var out: Array[Vector2i] = []
	for cy in range(floori(lo.y) - 1, ceili(hi.y) + 2):
		for cx in range(floori(lo.x) - 1, ceili(hi.x) + 2):
			var c := Vector2i(cx, cy)
			if not play_rect.has_point(FarmGrid.lattice_center(Vector2(c), iso_origin, half)):
				continue
			var area := 0.0
			for piece in Geometry2D.intersect_polygons(poly, FarmGrid.lattice_poly(c, iso_origin, half)):
				area += _poly_area(piece)
			if area >= min_area:
				out.append(c)
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
	var r := Rect2(Vector2.ZERO, Vector2(cells) * UNIT)
	draw_rect(r, Color(0.9, 0.2, 0.15, 0.25))
	draw_rect(r, Color(0.9, 0.2, 0.15, 0.9), false, 2.0)
	# outline the actual grid diamonds this rect blocks (drawn in world space)
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	for c in covered_cells(editor_origin(), EDITOR_HALF, EDITOR_RECT, 0.02):
		var poly := FarmGrid.lattice_poly(c, editor_origin(), EDITOR_HALF)
		poly.append(poly[0])
		draw_polyline(poly, Color(0.9, 0.35, 0.1, 0.8), 1.5)
