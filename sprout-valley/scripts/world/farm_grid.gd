extends Node
class_name FarmGrid
## Isometric placement grid over the farm. Cells are 2:1 diamonds (edges run
## atan(half.y/half.x) ~= 26.6 deg from horizontal, matching the painted
## perspective) on a single diamond lattice shared by plots, trees, buildings
## and blockers. Cell indices can be negative: cell (0,0) is the diamond at the
## centre of the buildable play area.
##
## The static lattice_* helpers hold the maths so editor tools (GridMarker and
## friends) can reuse it with their mirrored constants — autoloads such as
## BalanceData are unavailable in the editor.

var half := Vector2(48.0, 24.0)             # half diamond (width, height) px
# Buildable area: the original painted-farm rect (48, 120, 864, 384) tripled in
# both axes about its centre (480, 312), so cell (0,0) and all existing cell
# indices are unchanged. Un-buildable painted areas are carved out by blockers.
var play_rect := Rect2(-816, -264, 2592, 1152)
var iso_origin: Vector2                     # world centre of cell (0,0)

var _occupied: Dictionary = {}   # Vector2i -> Object (owner of the cell)

func _init() -> void:
	half = Vector2(
		BalanceData.get_value("grid_half_w", 48.0),
		BalanceData.get_value("grid_half_h", 24.0))
	iso_origin = play_rect.get_center()

# --- lattice maths (static so editor tools can share it) ---

static func lattice_center(cell: Vector2, origin: Vector2, p_half: Vector2) -> Vector2:
	## World centre of a (possibly fractional) lattice cell.
	return origin + Vector2((cell.x - cell.y) * p_half.x, (cell.x + cell.y) * p_half.y)

static func lattice_frac(pos: Vector2, origin: Vector2, p_half: Vector2) -> Vector2:
	## Fractional lattice coordinates of a world position (inverse of lattice_center).
	var d := pos - origin
	var u := d.x / p_half.x   # cx - cy
	var v := d.y / p_half.y   # cx + cy
	return Vector2((u + v) * 0.5, (v - u) * 0.5)

static func lattice_poly(cell: Vector2i, origin: Vector2, p_half: Vector2) -> PackedVector2Array:
	## The four corners of a cell's diamond, clockwise from the top.
	var c := lattice_center(Vector2(cell), origin, p_half)
	return PackedVector2Array([
		c + Vector2(0, -p_half.y), c + Vector2(p_half.x, 0),
		c + Vector2(0, p_half.y), c + Vector2(-p_half.x, 0),
	])

static func lattice_cells_in_rect(origin: Vector2, p_half: Vector2, rect: Rect2) -> Array[Vector2i]:
	## Every lattice cell whose diamond centre lies inside rect.
	var lo := Vector2(INF, INF)
	var hi := -lo
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var f := lattice_frac(corner, origin, p_half)
		lo = lo.min(f)
		hi = hi.max(f)
	var out: Array[Vector2i] = []
	for cy in range(floori(lo.y), ceili(hi.y) + 1):
		for cx in range(floori(lo.x), ceili(hi.x) + 1):
			if rect.has_point(lattice_center(Vector2(cx, cy), origin, p_half)):
				out.append(Vector2i(cx, cy))
	return out

# --- instance API ---

func cell_to_world(cell: Vector2i) -> Vector2:
	## Centre of a cell's diamond.
	return lattice_center(Vector2(cell), iso_origin, half)

func world_to_cell_f(pos: Vector2) -> Vector2:
	return lattice_frac(pos, iso_origin, half)

func world_to_cell(pos: Vector2) -> Vector2i:
	## Cell whose diamond contains pos (nearest lattice point).
	var f := world_to_cell_f(pos)
	return Vector2i(roundi(f.x), roundi(f.y))

func cell_polygon(cell: Vector2i) -> PackedVector2Array:
	return lattice_poly(cell, iso_origin, half)

func footprint_center(cell: Vector2i, footprint: Vector2i) -> Vector2:
	## Centre of a footprint's diamond region.
	return lattice_center(Vector2(cell) + Vector2(footprint - Vector2i.ONE) * 0.5, iso_origin, half)

func footprint_bottom(cell: Vector2i, footprint: Vector2i) -> Vector2:
	## Bottom-centre of a footprint's region: x of the region centre, y of its
	## lowest diamond vertex (baseline for y-sorted sprites).
	var bottom_cell := cell + footprint - Vector2i.ONE
	return Vector2(footprint_center(cell, footprint).x, cell_to_world(bottom_cell).y + half.y)

func in_bounds(cell: Vector2i, footprint := Vector2i.ONE) -> bool:
	for x in range(cell.x, cell.x + footprint.x):
		for y in range(cell.y, cell.y + footprint.y):
			if not play_rect.has_point(cell_to_world(Vector2i(x, y))):
				return false
	return true

func all_cells() -> Array[Vector2i]:
	## Every in-bounds cell of the play area.
	return lattice_cells_in_rect(iso_origin, half, play_rect)

func is_free(cell: Vector2i, footprint := Vector2i.ONE) -> bool:
	if not in_bounds(cell, footprint):
		return false
	for x in range(cell.x, cell.x + footprint.x):
		for y in range(cell.y, cell.y + footprint.y):
			if _occupied.has(Vector2i(x, y)):
				return false
	return true

func occupy(cell: Vector2i, footprint: Vector2i, who: Object) -> void:
	for x in range(cell.x, cell.x + footprint.x):
		for y in range(cell.y, cell.y + footprint.y):
			_occupied[Vector2i(x, y)] = who

func release(cell: Vector2i, footprint: Vector2i) -> void:
	for x in range(cell.x, cell.x + footprint.x):
		for y in range(cell.y, cell.y + footprint.y):
			_occupied.erase(Vector2i(x, y))

func occupant(cell: Vector2i) -> Object:
	return _occupied.get(cell)
