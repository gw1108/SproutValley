extends Node2D
class_name Structure
## A placed building: pre-placed flavor/storage, animal home, production
## building, or the delivery box. Production buildings craft one recipe at a
## time; output is deposited straight into storage (the shared inventory).

var building_id: String
var cell: Vector2i
var footprint: Vector2i

var crafting_recipe: String = ""
var craft_elapsed: float = 0.0
var craft_total: float = 0.0

var _sprite: Sprite2D
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _bar_icon: TextureRect

signal craft_finished(structure: Structure, recipe_id: String)

func setup(id: String, p_cell: Vector2i) -> void:
	building_id = id
	cell = p_cell
	footprint = ItemDB.buildings[id]["footprint"]

func _ready() -> void:
	var b: Dictionary = ItemDB.buildings[building_id]
	_sprite = Sprite2D.new()
	_sprite.texture = ItemDB.building_tex(building_id)
	var w := BalanceData.get_value(b["disp"], 120.0)
	var s := w / _sprite.texture.get_width()
	_sprite.scale = Vector2.ONE * s
	_sprite.position = Vector2(0, -_sprite.texture.get_height() * s * 0.5 + 4)
	add_child(_sprite)

	var bar_w := 46.0
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.18, 0.14, 0.10, 0.8)
	_bar_bg.size = Vector2(bar_w, 7)
	_bar_bg.position = Vector2(-bar_w / 2.0, -_sprite.texture.get_height() * s - 4)
	_bar_bg.visible = false
	add_child(_bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.95, 0.75, 0.3)
	_bar_fill.size = Vector2(0, 5)
	_bar_fill.position = Vector2(1, 1)
	_bar_bg.add_child(_bar_fill)
	_bar_icon = TextureRect.new()
	_bar_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bar_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bar_icon.size = Vector2(16, 16)
	_bar_icon.position = Vector2(bar_w / 2.0 - 8.0, -18)
	_bar_bg.add_child(_bar_icon)

func _process(delta: float) -> void:
	if crafting_recipe == "":
		return
	craft_elapsed += delta
	var frac := clampf(craft_elapsed / craft_total, 0.0, 1.0)
	_bar_fill.size.x = (_bar_bg.size.x - 2.0) * frac
	if frac >= 1.0:
		var recipe_id := crafting_recipe
		crafting_recipe = ""
		_bar_bg.visible = false
		var r: Dictionary = ItemDB.recipes[recipe_id]
		Game.add_item(r["out"], int(r["qty"]))
		craft_finished.emit(self, recipe_id)

func is_busy() -> bool:
	return crafting_recipe != ""

func my_recipes() -> Array:
	var out: Array = []
	for rid in ItemDB.recipes:
		if ItemDB.recipes[rid]["building"] == building_id:
			out.append(rid)
	return out

func start_craft(recipe_id: String) -> bool:
	if is_busy():
		return false
	var r: Dictionary = ItemDB.recipes[recipe_id]
	if not Game.take_items(r["inputs"]):
		return false
	crafting_recipe = recipe_id
	craft_elapsed = 0.0
	craft_total = BalanceData.get_value(r["time"], 30.0)
	_bar_bg.visible = true
	_bar_fill.size.x = 0
	_bar_icon.texture = ItemDB.icon(r["out"])
	return true

func home_rect() -> Rect2:
	## Area animals wander in: a strip in front of their home building
	## (barn for cows, coop for chickens).
	# width of the footprint's diamond region on the isometric lattice
	var hw := BalanceData.get_value("grid_half_w", 48.0)
	var w := (footprint.x + footprint.y) * hw
	return Rect2(global_position.x - w * 0.5 - 16.0, global_position.y - 14.0, w + 32.0, 52.0)

func click_rect() -> Rect2:
	var size := _sprite.texture.get_size() * _sprite.scale
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), Vector2(size.x, size.y))

func set_selected(on: bool) -> void:
	FarmTree.flash_selected(self, on)
