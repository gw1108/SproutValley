extends CanvasLayer
class_name SellPanel
## Delivery box UI: fixed-price sell list for all sellable goods (GDD 13.4).

var _root: Control
var _list: VBoxContainer

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
	panel.custom_minimum_size = Vector2(560, 420)
	panel.position = Vector2(-280, -210)
	_root.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Delivery Box — Sell Goods"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.35, 0.22, 0.10))
	top.add_child(title)
	top.add_spacer(false)
	var close := Button.new()
	close.text = "✕"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(36, 36)
	close.pressed.connect(func() -> void: visible = false)
	top.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	Game.inventory_changed.connect(func(_i: String, _c: int) -> void:
		if visible:
			_refresh())

func open_panel() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var any := false
	for item_id in ItemDB.items:
		if not ItemDB.is_sellable(item_id):
			continue
		var n := Game.count(item_id)
		if n <= 0:
			continue
		any = true
		_add_row(item_id, n)
	if not any:
		var empty := Label.new()
		empty.text = "Nothing to sell yet — harvest crops or collect goods first!"
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", Color(0.45, 0.35, 0.24))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(empty)

func _add_row(item_id: String, n: int) -> void:
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.88)
	sb.set_corner_radius_all(10)
	sb.border_color = Color(0.62, 0.45, 0.28)
	sb.set_border_width_all(1)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	row.add_theme_stylebox_override("panel", sb)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(row)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)

	var icon := TextureRect.new()
	icon.texture = ItemDB.icon(item_id)
	icon.custom_minimum_size = Vector2(34, 34)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.add_child(icon)

	var nm := Label.new()
	nm.text = "%s ×%d" % [ItemDB.items[item_id]["name"], n]
	nm.add_theme_font_size_override("font_size", 16)
	nm.add_theme_color_override("font_color", Color(0.35, 0.22, 0.10))
	nm.custom_minimum_size = Vector2(150, 0)
	h.add_child(nm)

	var price := Label.new()
	price.text = "%d each  •  %s XP" % [ItemDB.sell_price(item_id), String.num(ItemDB.xp_value(item_id), 2)]
	price.add_theme_font_size_override("font_size", 13)
	price.add_theme_color_override("font_color", Color(0.5, 0.38, 0.2))
	price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(price)

	var one := Button.new()
	one.text = "Sell 1"
	one.focus_mode = Control.FOCUS_NONE
	one.pressed.connect(func() -> void: Game.sell(item_id, 1))
	h.add_child(one)
	var all := Button.new()
	all.text = "Sell All"
	all.focus_mode = Control.FOCUS_NONE
	all.pressed.connect(func() -> void: Game.sell(item_id, Game.count(item_id)))
	h.add_child(all)
