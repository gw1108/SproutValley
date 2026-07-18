extends Node
class_name InteractionManager
## Owns the click-driven interaction flow:
##   IDLE     - click an object -> radial menu of applicable actions
##   PLANT    - hold & drag over empty plots to scatter seeds
##   HARVEST  - hold & drag over mature plots to scythe them
##   PLACE    - ghost follows mouse, click to place purchase

enum Mode { IDLE, PLANT, HARVEST, PLACE }

var mode: int = Mode.IDLE
var plant_crop: String = ""
var place_id: String = ""          # "farm_plot" or a building id
var _mouse_down := false

var main: Node2D                   # Main scene root
var grid: FarmGrid
var radial: RadialMenu

var _ghost: Sprite2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = event.pressed
		if event.pressed:
			_on_press(main.make_input_local(event).position)
	elif event is InputEventMouseMotion and _mouse_down:
		if mode == Mode.PLANT or mode == Mode.HARVEST:
			_apply_drag(main.make_input_local(event).position)
	elif event.is_action_pressed("ui_cancel"):
		cancel_mode()

func _process(_delta: float) -> void:
	if mode == Mode.PLACE and is_instance_valid(_ghost):
		var pos := main.get_global_mouse_position()
		var cell := _cell_for_place_pos(pos)
		var fp := _place_footprint()
		_ghost.global_position = grid.footprint_bottom(cell, fp) if place_id != "farm_plot" else grid.footprint_center(cell, fp)
		var ok := grid.is_free(cell, fp)
		_ghost.modulate = Color(0.5, 1.0, 0.5, 0.75) if ok else Color(1.0, 0.4, 0.4, 0.6)

func _cell_for_place_pos(pos: Vector2) -> Vector2i:
	## Cell whose footprint is centered under the cursor.
	var fp := _place_footprint()
	return grid.world_to_cell(pos - Vector2(fp.x, fp.y) * grid.cell_size * 0.5 + Vector2(grid.cell_size, grid.cell_size) * 0.5)

func _on_press(pos: Vector2) -> void:
	match mode:
		Mode.IDLE:
			var obj: Node2D = _object_at(pos)
			if obj != null:
				_open_menu_for(obj, pos)
		Mode.PLANT, Mode.HARVEST:
			_apply_drag(pos)
		Mode.PLACE:
			_try_place(pos)

# ---------- object picking ----------

func _object_at(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_y := -INF
	for obj in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(obj):
			continue
		if obj.click_rect().has_point(pos):
			# front-most (largest baseline y) wins, matching y-sort
			if obj.global_position.y > best_y:
				best_y = obj.global_position.y
				best = obj
	return best

# ---------- radial menus ----------

func _open_menu_for(obj: Node2D, pos: Vector2) -> void:
	var options: Array = []
	if obj is FarmPlot:
		options = _plot_options(obj)
	elif obj is FarmTree:
		options = _tree_options(obj)
	elif obj is Structure:
		options = _structure_options(obj)
	if options.is_empty():
		return
	main.play_sfx("click-a")
	radial.open(pos, options)

func _plot_options(plot: FarmPlot) -> Array:
	var options: Array = []
	if plot.state == FarmPlot.State.EMPTY:
		for crop_id in ItemDB.crops:
			var seed_id: String = ItemDB.crops[crop_id]["seed"]
			var owned := Game.count(seed_id)
			options.append({
				"id": crop_id,
				"icon": ItemDB.icon(seed_id),
				"label": "Plant %s (%d seeds)" % [ItemDB.items[crop_id]["name"], owned],
				"count": owned,
				"disabled": owned <= 0,
				"callback": start_planting.bind(crop_id),
			})
	elif plot.state == FarmPlot.State.MATURE:
		options.append({
			"id": "scythe",
			"icon": ItemDB.tex("res://assets/icons/icon_scythe.png"),
			"label": "Harvest (Scythe)",
			"callback": _on_scythe_pressed.bind(plot),
		})
	return options

func _on_scythe_pressed(plot: FarmPlot) -> void:
	start_harvesting()
	_harvest_plot(plot)

func _tree_options(tree: FarmTree) -> Array:
	var tool_id := tree.tool_needed()
	var owned := Game.count(tool_id)
	return [{
		"id": tool_id,
		"icon": ItemDB.icon(tool_id),
		"label": "%s (%d owned, consumed on use)" % [ItemDB.items[tool_id]["name"], owned],
		"count": owned,
		"disabled": owned <= 0,
		"callback": _on_chop_pressed.bind(tree, tool_id),
	}]

func _on_chop_pressed(tree: FarmTree, tool_id: String) -> void:
	if Game.remove_item(tool_id, 1):
		tree.chop()
		main.play_sfx("click-b")
		main.on_tree_chopped()

func _structure_options(s: Structure) -> Array:
	if s.building_id == "delivery_box":
		return [{
			"id": "sell",
			"icon": ItemDB.tex("res://assets/icons/icon_coin.png"),
			"label": "Sell goods",
			"callback": Callable(main, "open_sell_panel"),
		}]
	var recipes := s.my_recipes()
	if recipes.is_empty():
		return []
	var options: Array = []
	for rid in recipes:
		var r: Dictionary = ItemDB.recipes[rid]
		var can := Game.has_items(r["inputs"]) and not s.is_busy()
		var label: String = "Craft %s (" % ItemDB.items[r["out"]]["name"]
		var parts: Array = []
		for input_id in r["inputs"]:
			parts.append("%d %s" % [r["inputs"][input_id], ItemDB.items[input_id]["name"]])
		label += ", ".join(parts) + ")"
		if s.is_busy():
			label = "Busy…"
		options.append({
			"id": rid,
			"icon": ItemDB.icon(r["out"]),
			"label": label,
			"disabled": not can,
			"callback": _on_craft_pressed.bind(s, rid),
		})
	return options

func _on_craft_pressed(s: Structure, rid: String) -> void:
	s.start_craft(rid)

# ---------- plant / harvest drag modes ----------

func start_planting(crop_id: String) -> void:
	plant_crop = crop_id
	mode = Mode.PLANT
	_update_banner()

func start_harvesting() -> void:
	mode = Mode.HARVEST
	main.hud.set_mode_banner("Harvesting — click & drag across grown crops", true)

func _apply_drag(pos: Vector2) -> void:
	var cell := grid.world_to_cell(pos)
	var obj = grid.occupant(cell)
	if obj == null or not (obj is FarmPlot):
		return
	var plot: FarmPlot = obj
	if mode == Mode.PLANT and plot.state == FarmPlot.State.EMPTY:
		var seed_id: String = ItemDB.crops[plant_crop]["seed"]
		if Game.remove_item(seed_id, 1):
			plot.plant(plant_crop)
			main.play_sfx("tap-a")
			if Game.count(seed_id) <= 0:
				cancel_mode()
			else:
				_update_banner()
	elif mode == Mode.HARVEST and plot.state == FarmPlot.State.MATURE:
		_harvest_plot(plot)

func _harvest_plot(plot: FarmPlot) -> void:
	var crop_id := plot.crop_id
	var yield_n := int(BalanceData.get_value("harvest_yield", 2.0))
	plot.harvest()
	Game.add_item(crop_id, yield_n)
	main.play_sfx("tap-b")
	main.notify_deposit(crop_id, yield_n, plot.global_position)

func _update_banner() -> void:
	if mode == Mode.PLANT:
		var seed_id: String = ItemDB.crops[plant_crop]["seed"]
		main.hud.set_mode_banner("Planting %s — click & drag on empty plots (%d seeds left)" % [ItemDB.items[plant_crop]["name"], Game.count(seed_id)], true)

# ---------- placement mode ----------

func start_placing(id: String) -> void:
	cancel_mode()
	place_id = id
	mode = Mode.PLACE
	_ghost = Sprite2D.new()
	if id == "farm_plot":
		_ghost.texture = ItemDB.tex("res://assets/world/farm_plot.png")
		_ghost.scale = Vector2.ONE * (BalanceData.get_value("disp_farm_plot", 50.0) / _ghost.texture.get_width())
	else:
		_ghost.texture = ItemDB.building_tex(id)
		var w := BalanceData.get_value(ItemDB.buildings[id]["disp"], 120.0)
		var s := w / _ghost.texture.get_width()
		_ghost.scale = Vector2.ONE * s
		_ghost.offset = Vector2(0, -_ghost.texture.get_height() * 0.5 + 4.0 / s)
	main.overlay_layer.add_child(_ghost)
	var cost := _place_cost()
	main.hud.set_mode_banner("Place %s — %d coins. Click a free spot." % [_place_name(), cost], true)

func _place_footprint() -> Vector2i:
	if place_id == "farm_plot":
		return Vector2i.ONE
	return ItemDB.buildings[place_id]["footprint"]

func _place_cost() -> int:
	if place_id == "farm_plot":
		return int(BalanceData.get_value("farm_plot_cost", 25.0))
	return int(BalanceData.get_value(ItemDB.buildings[place_id]["cost"], 100.0))

func _place_name() -> String:
	if place_id == "farm_plot":
		return "Farm Plot"
	return ItemDB.buildings[place_id]["name"]

func _try_place(pos: Vector2) -> void:
	var cell := _cell_for_place_pos(pos)
	var fp := _place_footprint()
	if not grid.is_free(cell, fp):
		return
	var cost := _place_cost()
	if not Game.spend(cost):
		main.hud.flash_money()
		return
	main.play_sfx("switch-a")
	if place_id == "farm_plot":
		main.spawn_plot(cell)
		Game.mark_placed("farm_plot")
		# keep placing while player can afford more and limit not reached
		var maxed := Game.placed("farm_plot") >= int(BalanceData.get_value("farm_plot_max", 25.0))
		if maxed or not Game.can_afford(cost):
			cancel_mode()
		else:
			main.hud.set_mode_banner("Place Farm Plot — %d coins (%d/%d placed)" % [cost, Game.placed("farm_plot"), int(BalanceData.get_value("farm_plot_max", 25.0))], true)
	else:
		main.spawn_structure(place_id, cell)
		Game.mark_placed(place_id)
		cancel_mode()

func cancel_mode() -> void:
	mode = Mode.IDLE
	plant_crop = ""
	place_id = ""
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	main.hud.set_mode_banner("", false)
