@tool
extends Node2D
class_name GridMarker
## Base for editor-placed farm-grid markers (blockers, structure/tree spawns).
## Drag in the editor — the node snaps to the placement grid. The node's
## position is the TOP-LEFT corner of its anchor cell.
##
## EDITOR_ORIGIN/EDITOR_CELL mirror FarmGrid's defaults for in-editor preview
## only (autoloads aren't available in the editor); runtime cell lookup always
## goes through FarmGrid.world_to_cell.

const EDITOR_ORIGIN := Vector2(48, 120)
const EDITOR_CELL := 48.0
const EDITOR_COLS := 18
const EDITOR_ROWS := 8

## Subclasses that are placed freely (e.g. rotated road blockers) turn this off.
var snap_to_grid := true

func _process(_dt: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if not snap_to_grid:
		return
	var target := ((position - EDITOR_ORIGIN) / EDITOR_CELL).round() * EDITOR_CELL + EDITOR_ORIGIN
	if not position.is_equal_approx(target):
		position = target
		queue_redraw()

func grid_cell(grid: FarmGrid) -> Vector2i:
	## Cell whose top-left corner this marker sits on (sampled at cell center
	## so float error can't push it into a neighbor).
	return grid.world_to_cell(position + Vector2.ONE * grid.cell_size * 0.5)
