extends Node2D
## Main scene: builds the farm world, HUD and UI, and wires interactions.
## The background painting, road/decor blockers, pre-placed structures and
## starting trees are authored as nodes in Main.tscn (Background, Blockers,
## StartingStructures, TreeSpawns) so a designer can move them in the editor.

@onready var blockers: Node2D = $Blockers
@onready var starting_structures: Node2D = $StartingStructures
@onready var tree_spawns: Node2D = $TreeSpawns

var grid: FarmGrid
var hud: Hud
var shop: ShopOverlay
var sell_panel: SellPanel
var inventory_panel: InventoryPanel
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
	_apply_blockers()
	_build_layers()
	_build_ui()
	_place_starting_structures()
	_spawn_starting_trees()

func _apply_blockers() -> void:
	# cells the painted roads/decor pass through (GridBlocker nodes in the
	# scene, freely rotatable): never free
	for b in blockers.get_children():
		for cell in b.blocked_cells(grid):
			grid.occupy(cell, Vector2i.ONE, self)
	if "dump_blocked" in OS.get_cmdline_user_args():
		_dump_blocked()

func _dump_blocked() -> void:
	# dev tooling: ASCII map of lattice cells ('#' blocked, '.' free, ' ' out of
	# bounds), rows/cols are lattice cy/cx (diagonals on screen), for probes
	var inb := {}
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := -lo
	for c in grid.all_cells():
		inb[c] = true
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	for cy in range(lo.y, hi.y + 1):
		var row := ""
		for cx in range(lo.x, hi.x + 1):
			var c := Vector2i(cx, cy)
			row += (("#" if grid.occupant(c) != null else ".") if inb.has(c) else " ")
		print("BLOCKED cy=%d %s" % [cy, row])

func _build_layers() -> void:
	plot_layer = Node2D.new()
	plot_layer.z_index = -5
	# sort plots/crops by their cell's south point so the furthest-south plot
	# draws last (over its northern neighbours), matching the world layer's rule
	plot_layer.y_sort_enabled = true
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
	inventory_panel = InventoryPanel.new()
	add_child(inventory_panel)

	interaction = InteractionManager.new()
	interaction.main = self
	interaction.grid = grid
	interaction.radial = radial
	add_child(interaction)

	hud.shop_pressed.connect(_on_shop_pressed)
	hud.settings_pressed.connect(interaction.cancel_mode)
	hud.cancel_pressed.connect(interaction.cancel_mode)
	shop.request_place.connect(interaction.start_placing)
	shop.request_animal.connect(spawn_animal)

func _on_shop_pressed() -> void:
	interaction.cancel_mode()
	shop.open_shop()

func _place_starting_structures() -> void:
	# StructureSpawn nodes in the scene, sitting on open grass pockets of the
	# painted landscape
	for s in starting_structures.get_children():
		spawn_structure(s.building_id, s.grid_cell(grid))

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
	var home_id := "chicken_coop" if kind == "chicken" else "barn"
	var home: Structure = structures.get(home_id)
	if home == null:
		return
	var a := Animal.new()
	a.setup(kind, home, grid)
	world.add_child(a)

func _spawn_starting_trees() -> void:
	# one FarmTree per TreeSpawn node in the scene
	for m in tree_spawns.get_children():
		var cell: Vector2i = m.grid_cell(grid)
		if grid.is_free(cell, Vector2i.ONE):
			_spawn_tree(cell, m.big)

func _spawn_tree(cell: Vector2i, big := false) -> void:
	var t := FarmTree.new()
	t.setup(cell, grid, big)
	# nudge each tree by a small random offset so trees placed in rows/columns
	# don't look perfectly aligned (grid occupancy still uses the exact cell)
	var jitter := BalanceData.get_value("tree_jitter", 8.0)
	var offset := Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
	t.position = grid.footprint_bottom(cell, t.footprint) + offset
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

func open_inventory_panel() -> void:
	inventory_panel.open_panel()

func on_tree_chopped() -> void:
	var cam_shake := create_tween()
	cam_shake.tween_property(self, "position", Vector2(3, 0), 0.04)
	cam_shake.tween_property(self, "position", Vector2(-3, 1), 0.04)
	cam_shake.tween_property(self, "position", Vector2.ZERO, 0.06)

func notify_deposit(item_id: String, n: int, from_pos: Vector2) -> void:
	var home: Structure = structures.get("player_home")
	if home == null:
		floating_icon(ItemDB.icon(item_id), from_pos, "+%d" % n)
		return
	fly_to_home(ItemDB.icon(item_id), from_pos, home.global_position, "+%d" % n)

func fly_to_home(icon: Texture2D, from_pos: Vector2, home_pos: Vector2, text: String = "") -> void:
	## Spawn the produce icon, pop it up, then sail it over to the player's home
	## before fading out.
	var node := Node2D.new()
	node.position = from_pos
	node.z_index = 6
	overlay_layer.add_child(node)
	var spr := Sprite2D.new()
	spr.texture = icon
	if icon != null:
		spr.scale = Vector2.ONE * (BalanceData.get_value("deposit_icon_size", 28.0) / icon.get_width())
	node.add_child(spr)
	var lbl: Label = null
	if text != "":
		lbl = Label.new()
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0.25, 0.16, 0.08))
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.position = Vector2(12, -12)
		node.add_child(lbl)

	var rise := BalanceData.get_value("deposit_rise", 40.0)
	var rise_time := BalanceData.get_value("deposit_rise_time", 0.35)
	var fly_time := BalanceData.get_value("deposit_fly_time", 0.7)
	var top := from_pos + Vector2(0, -rise)

	var tw := node.create_tween()
	# 1) pop up out of the plot
	tw.tween_property(node, "position", top, rise_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if lbl != null:
		# the "+n" label has done its job; drop it before the icon flies off
		tw.tween_callback(lbl.queue_free)
	# 2) sail over to the home, shrinking as it "lands" in storage
	tw.tween_property(node, "position", home_pos, fly_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(spr, "scale", spr.scale * 0.35, fly_time).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node, "modulate:a", 0.0, fly_time).set_delay(fly_time * 0.45)
	tw.tween_callback(node.queue_free)

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
