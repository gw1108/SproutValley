extends Node
class_name FarmGrid
## Placement grid over the farm. Tracks cell occupancy for blockers,
## plots and buildings.

var origin := Vector2(48, 120)
var cols := 18
var rows := 8
var cell_size := 48.0

var _occupied: Dictionary = {}   # Vector2i -> Object (owner of the cell)

# --- isometric plot projection ---
# Farm plots render as 2:1 diamonds that tessellate edge-to-edge on their own
# isometric lattice, laid over the square logical grid used for occupancy.
# Buildings and trees keep the square projection (cell_to_world/world_to_cell).
var plot_iso_origin: Vector2
var plot_iso_half := Vector2(48.0, 25.0)   # half diamond (width, height) px

func _init() -> void:
	cell_size = BalanceData.get_value("grid_cell", 48.0)

func _ready() -> void:
	_setup_plot_iso()

func _setup_plot_iso() -> void:
	var w := BalanceData.get_value("disp_farm_plot", 96.0)
	var tex := ItemDB.tex("res://assets/world/farm_plot.png")
	var aspect := (float(tex.get_height()) / float(tex.get_width())) if tex != null else 0.527
	plot_iso_half = Vector2(w * 0.5, w * aspect * 0.5)
	# anchor the iso field so the middle of the square play area maps to its centre
	var mid := Vector2i(cols / 2, rows / 2)
	plot_iso_origin = cell_to_world(mid) - Vector2(
		(mid.x - mid.y) * plot_iso_half.x, (mid.x + mid.y) * plot_iso_half.y)

func plot_cell_to_world(cell: Vector2i) -> Vector2:
	## Centre of a plot's diamond on the isometric lattice.
	return plot_iso_origin + Vector2(
		(cell.x - cell.y) * plot_iso_half.x, (cell.x + cell.y) * plot_iso_half.y)

func plot_world_to_cell(pos: Vector2) -> Vector2i:
	## Nearest plot cell under a screen position (inverse of plot_cell_to_world).
	var d := pos - plot_iso_origin
	var u := d.x / plot_iso_half.x   # cx - cy
	var v := d.y / plot_iso_half.y   # cx + cy
	return Vector2i(roundi((u + v) * 0.5), roundi((v - u) * 0.5))

func cell_to_world(cell: Vector2i) -> Vector2:
	## Center of a cell.
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size

func footprint_center(cell: Vector2i, footprint: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2(footprint) * 0.5) * cell_size

func footprint_bottom(cell: Vector2i, footprint: Vector2i) -> Vector2:
	## Bottom-center of a footprint (baseline for y-sorted sprites).
	return origin + Vector2((float(cell.x) + footprint.x * 0.5) * cell_size, (float(cell.y) + footprint.y) * cell_size)

func world_to_cell(pos: Vector2) -> Vector2i:
	var local := (pos - origin) / cell_size
	return Vector2i(floori(local.x), floori(local.y))

func in_bounds(cell: Vector2i, footprint := Vector2i.ONE) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x + footprint.x <= cols and cell.y + footprint.y <= rows

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
