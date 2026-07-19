extends Node2D
class_name FarmTree
## Tree blocker (1x1 cell). Comes in two sizes:
##   small - falls to the Axe (cheaper tool)
##   big   - falls to the Saw (costlier tool)
## The chopping tool is consumed on use, so big trees cost more to remove.
## Each tree picks a random art variant of its size for visual variety.

var cell: Vector2i
var footprint := Vector2i.ONE
var big := false
var variant := 1

var _sprite: Sprite2D
var _grid: FarmGrid

func setup(p_cell: Vector2i, grid: FarmGrid, p_big := false) -> void:
	cell = p_cell
	_grid = grid
	big = p_big
	var n := ItemDB.TREE_LARGE_VARIANTS if big else ItemDB.TREE_SMALL_VARIANTS
	variant = randi_range(1, n)

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = ItemDB.tree_tex(big, variant)
	var w := BalanceData.get_value("disp_tree_large" if big else "disp_tree_small", 120.0 if big else 72.0)
	var s := w / _sprite.texture.get_width()
	_sprite.scale = Vector2.ONE * s
	# baseline at bottom of trunk
	_sprite.position = Vector2(0, -_sprite.texture.get_height() * s * 0.5 + 6)
	add_child(_sprite)

func tool_needed() -> String:
	return "saw" if big else "axe"

func chop() -> void:
	## Remove the tree: free its cells and sway + fade to nothing, leaving the
	## ground clear so a structure can be built on the cleared cell.
	_grid.release(cell, footprint)

	var tw := create_tween()
	tw.tween_property(_sprite, "rotation_degrees", 12.0, 0.18)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_callback(queue_free)

func click_rect() -> Rect2:
	var size := _sprite.texture.get_size() * _sprite.scale
	# only the lower-middle of the tree is clickable: half as wide (still centred
	# on the trunk) and half as tall, reaching the trunk base (global_position.y)
	# but rising only halfway up the canopy
	var w := size.x * 0.5
	var h := size.y * 0.5
	return Rect2(global_position - Vector2(w * 0.5, h), Vector2(w, h))

func set_selected(on: bool) -> void:
	FarmTree.flash_selected(self, on)

## Yellow selection pulse shared by trees, plots and structures.
static var _sel_tweens := {}
static func flash_selected(node: Node2D, on: bool) -> void:
	var prev = _sel_tweens.get(node)
	if prev != null and prev.is_valid():
		prev.kill()
	_sel_tweens.erase(node)
	if on:
		var period := BalanceData.get_value("select_flash_period", 0.6)
		var tw := node.create_tween().set_loops()
		tw.tween_property(node, "modulate", Color(1.6, 1.6, 0.4), period * 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(node, "modulate", Color.WHITE, period * 0.5).set_trans(Tween.TRANS_SINE)
		_sel_tweens[node] = tw
	else:
		node.modulate = Color.WHITE
