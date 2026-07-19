@tool
extends Node2D
class_name GridMarker
## Base for editor-placed farm-grid markers (blockers, structure/tree spawns).
## Drag in the editor — the node snaps to the isometric placement grid. The
## node's position is the CENTRE of its anchor cell's diamond.
##
## EDITOR_* mirror FarmGrid's defaults for in-editor preview only (autoloads
## aren't available in the editor); runtime cell lookup always goes through
## FarmGrid.world_to_cell. Keep them in sync with FarmGrid / balance.csv
## (grid_half_w, grid_half_h).

const EDITOR_HALF := Vector2(48.0, 24.0)
const EDITOR_RECT := Rect2(-816, -264, 2592, 1152)

## Subclasses that are placed freely (e.g. rotated road blockers) turn this off.
var snap_to_grid := true

static func editor_origin() -> Vector2:
	return EDITOR_RECT.get_center()

static func editor_cell_center(cell: Vector2i) -> Vector2:
	return FarmGrid.lattice_center(Vector2(cell), editor_origin(), EDITOR_HALF)

static func editor_cell_poly(cell: Vector2i) -> PackedVector2Array:
	return FarmGrid.lattice_poly(cell, editor_origin(), EDITOR_HALF)

static func editor_footprint_poly(fp: Vector2i) -> PackedVector2Array:
	## Outline of an fp.x x fp.y footprint region in LOCAL coords, with the
	## anchor cell's centre at the local origin. Corners clockwise from the top.
	var hx := EDITOR_HALF.x
	var hy := EDITOR_HALF.y
	return PackedVector2Array([
		Vector2(0, -hy),                                          # top of anchor cell
		Vector2(fp.x * hx, (fp.x - 1) * hy),                      # right vertex
		Vector2((fp.x - fp.y) * hx, (fp.x + fp.y - 1) * hy),      # bottom vertex
		Vector2(-fp.y * hx, (fp.y - 1) * hy),                     # left vertex
	])

func _process(_dt: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if not snap_to_grid:
		return
	var f := FarmGrid.lattice_frac(position, editor_origin(), EDITOR_HALF)
	var target := editor_cell_center(Vector2i(roundi(f.x), roundi(f.y)))
	if not position.is_equal_approx(target):
		position = target
		queue_redraw()

func grid_cell(grid: FarmGrid) -> Vector2i:
	## Cell whose diamond centre this marker sits on.
	return grid.world_to_cell(position)
