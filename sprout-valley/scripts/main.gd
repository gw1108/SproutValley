extends Node2D
## Main scene: builds the farm world, HUD and UI, and wires interactions.

const VIEW := Vector2(960, 540)

var grid: FarmGrid
var hud: Hud
var shop: ShopOverlay
var sell_panel: SellPanel
var radial: RadialMenu
var interaction: InteractionManager

var world: Node2D          # y-sorted objects (trees, buildings, animals)
var plot_layer: Node2D     # flat plots, under everything
var overlay_layer: Node2D  # placement ghost etc.
var structures: Dictionary = {}   # building_id -> Structure

var _sfx: Dictionary = {}

func _ready() -> void:
	add_to_group("main")
	grid = FarmGrid.new()
	add_child(grid)
	_build_sfx()
	_build_background()
	_build_layers()
	_build_ui()
	_place_starting_structures()
	_scatter_trees()

func _build_background() -> void:
	var sky := Sprite2D.new()
	sky.texture = ItemDB.tex("res://assets/background/skyline.png")
	sky.centered = false
	sky.scale = VIEW / Vector2(sky.texture.get_size())
	sky.z_index = -10
	add_child(sky)

	var ground := Sprite2D.new()
	ground.texture = ItemDB.tex("res://assets/background/farm_ground.png")
	ground.centered = false
	ground.scale = VIEW / Vector2(ground.texture.get_size())
	ground.z_index = -9
	add_child(ground)

	# road: permanent unremovable blocker crossing the farm above the bottom row
	var road_y := grid.origin.y + 7.0 * grid.cell_size
	var road_h := BalanceData.get_value("disp_road_h", 70.0)
	var road_tex := ItemDB.tex("res://assets/world/road.png")
	var seg_w := road_tex.get_width() * (road_h / road_tex.get_height())
	var x := -10.0
	while x < VIEW.x + 10.0:
		var seg := Sprite2D.new()
		seg.texture = road_tex
		seg.centered = false
		seg.scale = Vector2.ONE * (road_h / road_tex.get_height())
		seg.position = Vector2(x, road_y - 8.0)
		seg.z_index = -8
		add_child(seg)
		x += seg_w
	for cx in range(grid.cols):
		grid.occupy(Vector2i(cx, 7), Vector2i.ONE, self)   # road cells: never free

func _build_layers() -> void:
	plot_layer = Node2D.new()
	plot_layer.z_index = -5
	add_child(plot_layer)
	world = Node2D.new()
	world.y_sort_enabled = true
	world.z_index = 0
	add_child(world)
	overlay_layer = Node2D.new()
	overlay_layer.z_index = 5
	add_child(overlay_layer)

func _build_ui() -> void:
	hud = Hud.new()
	add_child(hud)

	var radial_layer := CanvasLayer.new()
	radial_layer.layer = 15
	add_child(radial_layer)
	radial = RadialMenu.new()
	radial_layer.add_child(radial)

	shop = ShopOverlay.new()
	add_child(shop)
	sell_panel = SellPanel.new()
	add_child(sell_panel)

	interaction = InteractionManager.new()
	interaction.main = self
	interaction.grid = grid
	interaction.radial = radial
	add_child(interaction)

	hud.shop_pressed.connect(_on_shop_pressed)
	hud.cancel_pressed.connect(interaction.cancel_mode)
	shop.request_place.connect(interaction.start_placing)
	shop.request_animal.connect(spawn_animal)

func _on_shop_pressed() -> void:
	interaction.cancel_mode()
	shop.open_shop()

func _place_starting_structures() -> void:
	_spawn_preplaced("player_home", Vector2i(0, 0))
	_spawn_preplaced("silo", Vector2i(12, 0))
	_spawn_preplaced("barn", Vector2i(15, 0))
	_spawn_preplaced("delivery_box", Vector2i(16, 6))

func _spawn_preplaced(id: String, cell: Vector2i) -> void:
	# delivery box may sit on road-adjacent cells that are still free
	spawn_structure(id, cell)

func spawn_structure(id: String, cell: Vector2i) -> Structure:
	var s := Structure.new()
	s.setup(id, cell)
	var fp: Vector2i = ItemDB.buildings[id]["footprint"]
	s.position = grid.footprint_bottom(cell, fp)
	grid.occupy(cell, fp, s)
	world.add_child(s)
	s.add_to_group("interactable")
	structures[id] = s
	return s

func spawn_plot(cell: Vector2i) -> FarmPlot:
	var p := FarmPlot.new()
	p.cell = cell
	p.position = grid.cell_to_world(cell)
	grid.occupy(cell, Vector2i.ONE, p)
	plot_layer.add_child(p)
	p.add_to_group("interactable")
	return p

func spawn_animal(kind: String) -> void:
	var home_id := "chicken_coop" if kind == "chicken" else "cow_pasture"
	var home: Structure = structures.get(home_id)
	if home == null:
		return
	var a := Animal.new()
	a.setup(kind, home)
	world.add_child(a)

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260718
	var n_small := int(BalanceData.get_value("tree_small_count", 7.0))
	var n_large := int(BalanceData.get_value("tree_large_count", 5.0))
	var placed := 0
	var guard := 0
	while placed < n_large and guard < 500:
		guard += 1
		var cell := Vector2i(rng.randi_range(1, grid.cols - 3), rng.randi_range(1, grid.rows - 3))
		if grid.is_free(cell, Vector2i(2, 2)):
			_spawn_tree(true, cell)
			placed += 1
	placed = 0
	while placed < n_small and guard < 1000:
		guard += 1
		var cell := Vector2i(rng.randi_range(0, grid.cols - 1), rng.randi_range(0, grid.rows - 2))
		if grid.is_free(cell, Vector2i.ONE):
			_spawn_tree(false, cell)
			placed += 1

func _spawn_tree(large: bool, cell: Vector2i) -> void:
	var t := FarmTree.new()
	t.setup(large, cell, grid)
	t.position = grid.footprint_bottom(cell, t.footprint)
	grid.occupy(cell, t.footprint, t)
	world.add_child(t)
	t.add_to_group("interactable")

# ---------- feedback helpers ----------

func _build_sfx() -> void:
	for n in ["click-a", "click-b", "switch-a", "switch-b", "tap-a", "tap-b"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/%s.ogg" % n)
		p.volume_db = -6.0
		add_child(p)
		_sfx[n] = p

func play_sfx(n: String) -> void:
	if _sfx.has(n):
		_sfx[n].play()

func open_sell_panel() -> void:
	sell_panel.open_panel()

func on_tree_chopped() -> void:
	var cam_shake := create_tween()
	cam_shake.tween_property(self, "position", Vector2(3, 0), 0.04)
	cam_shake.tween_property(self, "position", Vector2(-3, 1), 0.04)
	cam_shake.tween_property(self, "position", Vector2.ZERO, 0.06)

func notify_deposit(item_id: String, n: int, from_pos: Vector2) -> void:
	floating_icon(ItemDB.icon(item_id), from_pos, "+%d" % n)

func floating_icon(icon: Texture2D, pos: Vector2, text: String = "") -> void:
	var node := Node2D.new()
	node.position = pos
	node.z_index = 6
	overlay_layer.add_child(node)
	var spr := Sprite2D.new()
	spr.texture = icon
	if icon != null:
		spr.scale = Vector2.ONE * (28.0 / icon.get_width())
	node.add_child(spr)
	if text != "":
		var lbl := Label.new()
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0.25, 0.16, 0.08))
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.position = Vector2(12, -12)
		node.add_child(lbl)
	var tw := node.create_tween()
	tw.tween_property(node, "position", pos + Vector2(0, -46), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.tween_callback(node.queue_free)
