extends Node2D
class_name FarmPlot
## A tilled soil plot. Empty -> growing (shared planted sprite, 2 variations
## picked randomly on planting) -> mature (per-crop sprite) -> harvest.

enum State { EMPTY, GROWING, MATURE }

var state: int = State.EMPTY
var crop_id: String = ""
var grow_elapsed: float = 0.0
var grow_total: float = 0.0
var cell: Vector2i

var _soil: Sprite2D
var _crop: Sprite2D
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _ready_bubble: Sprite2D

func _ready() -> void:
	_soil = Sprite2D.new()
	_soil.texture = ItemDB.tex("res://assets/world/farm_plot.png")
	# stretch the soil diamond to exactly fill one grid cell so adjacent plots
	# tessellate edge-to-edge on the isometric lattice
	_soil.scale = Vector2(
		_grid_half().x * 2.0 / _soil.texture.get_width(),
		_grid_half().y * 2.0 / _soil.texture.get_height())
	add_child(_soil)

	_crop = Sprite2D.new()
	_crop.visible = false
	add_child(_crop)

	var bar_w := 34.0
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.18, 0.14, 0.10, 0.75)
	_bar_bg.size = Vector2(bar_w, 5)
	_bar_bg.position = Vector2(-bar_w / 2.0, 14)
	_bar_bg.visible = false
	add_child(_bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.55, 0.85, 0.35)
	_bar_fill.size = Vector2(0, 3)
	_bar_fill.position = Vector2(1, 1)
	_bar_bg.add_child(_bar_fill)

	_ready_bubble = Sprite2D.new()
	_ready_bubble.texture = ItemDB.tex("res://assets/ui/bubble_harvest.png")
	_ready_bubble.scale = Vector2.ONE * (24.0 / _ready_bubble.texture.get_width())
	_ready_bubble.position = Vector2(14, -30)
	_ready_bubble.visible = false
	add_child(_ready_bubble)

func _process(delta: float) -> void:
	if state != State.GROWING:
		return
	grow_elapsed += delta
	var frac := clampf(grow_elapsed / grow_total, 0.0, 1.0)
	_bar_fill.size.x = (_bar_bg.size.x - 2.0) * frac
	if frac >= 1.0:
		state = State.MATURE
		_set_crop_tex(ItemDB.mature_tex(crop_id))
		_bar_bg.visible = false
		_ready_bubble.visible = true
		_pop(_crop)

func plant(id: String) -> void:
	crop_id = id
	state = State.GROWING
	grow_elapsed = 0.0
	grow_total = BalanceData.get_value(ItemDB.crops[id]["grow"], 60.0)
	_bar_bg.visible = true
	_bar_fill.size.x = 0
	_crop.visible = true
	_set_crop_tex(ItemDB.planted_tex(randi_range(1, ItemDB.PLANTED_VARIANTS)))
	_pop(_crop)

func harvest() -> void:
	crop_id = ""
	state = State.EMPTY
	_crop.visible = false
	_bar_bg.visible = false
	_ready_bubble.visible = false
	_pop(_soil)

func _set_crop_tex(t: Texture2D) -> void:
	if _crop.texture == t:
		return
	_crop.texture = t
	var w := BalanceData.get_value("disp_crop", 42.0)
	var s := w / t.get_width()
	_crop.scale = Vector2.ONE * s
	# sit the crop's base low on the soil diamond so it fills the plot instead of
	# floating north; base_y is where the sprite bottom lands below the cell centre
	var base_y := BalanceData.get_value("disp_crop_base_y", 18.0)
	_crop.position = Vector2(0, base_y - t.get_height() * s * 0.5)

func _pop(node: Node2D) -> void:
	var base := node.scale
	var tw := create_tween()
	node.scale = base * 0.7
	tw.tween_property(node, "scale", base, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _grid_half() -> Vector2:
	return Vector2(
		BalanceData.get_value("grid_half_w", 48.0),
		BalanceData.get_value("grid_half_h", 24.0))

func click_rect() -> Rect2:
	# bounding box of the cell's diamond; overlapping neighbours are resolved
	# by the front-most (largest y) tie-break in InteractionManager._object_at
	var half := _grid_half()
	return Rect2(global_position - half, half * 2.0)
