extends Node
class_name FarmGrid
## Placement grid over the farm. Tracks cell occupancy for blockers,
## plots and buildings.

var origin := Vector2(48, 120)
var cols := 18
var rows := 8
var cell_size := 48.0

var _occupied: Dictionary = {}   # Vector2i -> Object (owner of the cell)

func _init() -> void:
	cell_size = BalanceData.get_value("grid_cell", 48.0)

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
