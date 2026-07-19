extends Node2D
class_name FarmTree
## Tree blocker (1x1 cell). Falls to the Axe, which is consumed on use.

var cell: Vector2i
var footprint := Vector2i.ONE

var _sprite: Sprite2D
var _grid: FarmGrid

func setup(p_cell: Vector2i, grid: FarmGrid) -> void:
	cell = p_cell
	_grid = grid

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = ItemDB.tex("res://assets/world/tree_small.png")
	var w := BalanceData.get_value("disp_tree_small", 72.0)
	var s := w / _sprite.texture.get_width()
	_sprite.scale = Vector2.ONE * s
	# baseline at bottom of trunk
	_sprite.position = Vector2(0, -_sprite.texture.get_height() * s * 0.5 + 6)
	add_child(_sprite)

func tool_needed() -> String:
	return "axe"

func chop() -> void:
	## Remove the tree: free its cells, sway + fade, leave a fading stump.
	_grid.release(cell, footprint)
	var stump := Sprite2D.new()
	stump.texture = ItemDB.tex("res://assets/world/tree_stump.png")
	var sw := BalanceData.get_value("disp_tree_stump", 44.0)
	var ss := sw / stump.texture.get_width()
	stump.scale = Vector2.ONE * ss
	stump.global_position = global_position + Vector2(0, -stump.texture.get_height() * ss * 0.4)
	get_parent().add_child(stump)
	var stw := stump.create_tween()
	stw.tween_interval(2.0)
	stw.tween_property(stump, "modulate:a", 0.0, 1.5)
	stw.tween_callback(stump.queue_free)

	var tw := create_tween()
	tw.tween_property(_sprite, "rotation_degrees", 12.0, 0.18)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_callback(queue_free)

func click_rect() -> Rect2:
	var size := _sprite.texture.get_size() * _sprite.scale
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), Vector2(size.x, size.y))
