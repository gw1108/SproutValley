extends CanvasLayer
class_name ShopOverlay
## Tabbed shop: Seeds & Tools / Animal Homes / Animals / Production.
## Placeables hand off to placement mode; seeds/tools/animals buy instantly.

signal request_place(id: String)
signal request_animal(kind: String)

const TABS := ["Seeds & Tools", "Animal Homes", "Animals", "Production"]

var _root: Control
var _grid: GridContainer
var _tab_buttons: Array = []
var _current_tab := 0

func _ready() -> void:
	layer = 20
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.90, 0.76)
	sb.set_corner_radius_all(18)
	sb.border_color = Color(0.48, 0.32, 0.18)
	sb.set_border_width_all(5)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.custom_minimum_size = Vector2(780, 460)
	panel.position = Vector2(-390, -230)
	_root.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.35, 0.22, 0.10))
	top.add_child(title)
	top.add_spacer(false)
	var close := Button.new()
	close.text = "✕"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(36, 36)
	close.pressed.connect(close_shop)
	top.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	col.add_child(tabs)
	for i in range(TABS.size()):
		var tb := Button.new()
		tb.text = TABS[i]
		tb.focus_mode = Control.FOCUS_NONE
		tb.toggle_mode = true
		tb.add_theme_font_size_override("font_size", 15)
		tb.pressed.connect(_on_tab.bind(i))
		tabs.add_child(tb)
		_tab_buttons.append(tb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	Game.money_changed.connect(func(_m: int) -> void:
		if visible:
			_refresh())
	Game.inventory_changed.connect(func(_i: String, _c: int) -> void:
		if visible:
			_refresh())

func open_shop() -> void:
	visible = true
	_on_tab(_current_tab)

func close_shop() -> void:
	visible = false

func _on_tab(i: int) -> void:
	_current_tab = i
	for j in range(_tab_buttons.size()):
		_tab_buttons[j].button_pressed = j == i
	_refresh()

func _refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	match _current_tab:
		0:
			for crop_id in ItemDB.crops:
				var seed_id: String = ItemDB.crops[crop_id]["seed"]
				_add_card(ItemDB.items[seed_id]["name"], ItemDB.icon(seed_id),
					int(BalanceData.get_value(crop_id + "_seed_cost", 5.0)),
					"Buy", _buy_item.bind(seed_id, crop_id + "_seed_cost"),
					"Grows in %ds • sells %d" % [int(BalanceData.get_value(crop_id + "_grow_time", 60.0)), ItemDB.sell_price(crop_id)],
					Game.count(seed_id))
			_add_card("Axe", ItemDB.icon("axe"), int(BalanceData.get_value("axe_cost", 40.0)),
				"Buy", _buy_item.bind("axe", "axe_cost"), "Removes small trees (single use)", Game.count("axe"))
			_add_card("Saw", ItemDB.icon("saw"), int(BalanceData.get_value("saw_cost", 90.0)),
				"Buy", _buy_item.bind("saw", "saw_cost"), "Removes big trees (single use)", Game.count("saw"))
			_add_card("Farm Plot", ItemDB.tex("res://assets/world/farm_plot.png"),
				int(BalanceData.get_value("farm_plot_cost", 25.0)),
				"Place", _place.bind("farm_plot"),
				"%d/%d placed" % [Game.placed("farm_plot"), int(BalanceData.get_value("farm_plot_max", 25.0))],
				-1, Game.placed("farm_plot") >= int(BalanceData.get_value("farm_plot_max", 25.0)))
		1:
			_add_building_card("chicken_coop", "Home for chickens • crafts Chicken Feed")
			_add_building_card("barn", "Home for cows • crafts Cow Feed")
		2:
			_add_animal_card("chicken", "chicken_coop", "Eats Chicken Feed, lays Eggs")
			_add_animal_card("cow", "barn", "Eats Cow Feed, gives Milk")
		3:
			_add_building_card("dairy_barn", "3 Milk → Butter")
			_add_building_card("bakery", "2 Wheat → Bread")

func _add_building_card(id: String, desc: String) -> void:
	var b: Dictionary = ItemDB.buildings[id]
	var owned := Game.placed(id) >= int(b.get("max", 1))
	_add_card(b["name"], ItemDB.building_tex(id), int(BalanceData.get_value(b["cost"], 100.0)),
		"Owned" if owned else "Place", _place.bind(id), desc, -1, owned)

func _add_animal_card(kind: String, home_id: String, desc: String) -> void:
	var maxn := int(BalanceData.get_value(kind + "_max", 4.0))
	var have: int = Game.animal_counts.get(kind, 0)
	var no_home := Game.placed(home_id) == 0
	var full: bool = have >= maxn
	var label := "Buy"
	if no_home:
		label = "Needs " + ItemDB.buildings[home_id]["name"]
	elif full:
		label = "Full"
	_add_card(kind.capitalize(), ItemDB.tex("res://assets/animals/%s_idle.png" % kind),
		int(BalanceData.get_value(kind + "_cost", 30.0)),
		label, _buy_animal.bind(kind), desc + " (%d/%d)" % [have, maxn], -1, no_home or full)

func _add_card(name_text: String, icon: Texture2D, cost: int, action: String, cb: Callable, desc := "", owned_count := -1, locked := false) -> void:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.88) if not locked else Color(0.85, 0.82, 0.74)
	sb.set_corner_radius_all(12)
	sb.border_color = Color(0.62, 0.45, 0.28)
	sb.set_border_width_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(172, 0)
	_grid.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(col)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(0, 64)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if locked:
		icon_rect.modulate = Color(1, 1, 1, 0.55)
	col.add_child(icon_rect)

	var nm := Label.new()
	nm.text = name_text if owned_count < 0 else "%s  ×%d" % [name_text, owned_count]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 15)
	nm.add_theme_color_override("font_color", Color(0.35, 0.22, 0.10))
	col.add_child(nm)

	if desc != "":
		var dl := Label.new()
		dl.text = desc
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", 11)
		dl.add_theme_color_override("font_color", Color(0.45, 0.35, 0.24))
		col.add_child(dl)

	var buy := Button.new()
	buy.focus_mode = Control.FOCUS_NONE
	var affordable := Game.can_afford(cost)
	buy.disabled = locked or not affordable
	buy.add_theme_font_size_override("font_size", 14)
	if locked:
		buy.text = action
	else:
		buy.text = "%s  •  %d" % [action, cost]
	buy.pressed.connect(cb)
	col.add_child(buy)

func _buy_item(item_id: String, cost_key: String) -> void:
	if Game.spend(int(BalanceData.get_value(cost_key, 10.0))):
		Game.add_item(item_id, 1)

func _place(id: String) -> void:
	close_shop()
	request_place.emit(id)

func _buy_animal(kind: String) -> void:
	if Game.spend(int(BalanceData.get_value(kind + "_cost", 30.0))):
		Game.animal_counts[kind] = Game.animal_counts.get(kind, 0) + 1
		request_animal.emit(kind)
		close_shop()
