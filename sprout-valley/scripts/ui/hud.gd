extends CanvasLayer
class_name Hud
## Persistent HUD: money (top-left), level/XP and settings button (top-right),
## shop button (bottom-left), mode banner with cancel button (top-center).

signal shop_pressed
signal cancel_pressed

var _money_label: Label
var _level_label: Label
var _xp_bar_fill: ColorRect
var _xp_bar_bg: ColorRect
var _banner: PanelContainer
var _banner_label: Label
var _money_box: Control

func _ready() -> void:
	layer = 10
	_build_money()
	_build_level()
	_build_shop_button()
	_build_settings_button()
	_build_banner()
	Game.money_changed.connect(func(_m: int) -> void: _refresh())
	Game.xp_changed.connect(func(_x: float, _l: int, _n: float) -> void: _refresh())
	Game.level_up.connect(_on_level_up)
	_refresh()

func _panel_style(bg := Color(0.29, 0.20, 0.12, 0.92)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(12)
	sb.border_color = Color(0.55, 0.38, 0.22)
	sb.set_border_width_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _build_money() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(12, 10)
	add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	var coin := TextureRect.new()
	coin.texture = ItemDB.tex("res://assets/icons/icon_coin.png")
	coin.custom_minimum_size = Vector2(26, 26)
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(coin)
	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 20)
	_money_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	row.add_child(_money_label)
	_money_box = panel

func _build_level() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.position = Vector2(-190, 10)
	panel.custom_minimum_size = Vector2(178, 0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	col.add_child(_level_label)
	_xp_bar_bg = ColorRect.new()
	_xp_bar_bg.color = Color(0.15, 0.11, 0.07)
	_xp_bar_bg.custom_minimum_size = Vector2(150, 8)
	col.add_child(_xp_bar_bg)
	_xp_bar_fill = ColorRect.new()
	_xp_bar_fill.color = Color(0.55, 0.85, 0.35)
	_xp_bar_fill.position = Vector2(1, 1)
	_xp_bar_fill.size = Vector2(0, 6)
	_xp_bar_bg.add_child(_xp_bar_fill)

func _art_button(tex_path: String, size: Vector2, tooltip: String) -> TextureButton:
	## Button whose art already includes full button chrome.
	var btn := TextureButton.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.texture_normal = ItemDB.tex(tex_path)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = size
	btn.size = size
	btn.tooltip_text = tooltip
	btn.mouse_entered.connect(func() -> void: btn.modulate = Color(1.12, 1.12, 1.12))
	btn.mouse_exited.connect(func() -> void: btn.modulate = Color.WHITE)
	return btn

func _build_shop_button() -> void:
	var btn := _art_button("res://assets/ui/shop_glyph.png", Vector2(68, 72), "Shop")
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.position = Vector2(12, -84)
	btn.pressed.connect(func() -> void: shop_pressed.emit())
	add_child(btn)

func _build_settings_button() -> void:
	var btn := _art_button("res://assets/ui/settings_icon.png", Vector2(44, 44), "Settings")
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.position = Vector2(-56, 58)
	btn.pressed.connect(_toggle_settings)
	add_child(btn)

var _settings_panel: CenterContainer

func _toggle_settings() -> void:
	if _settings_panel != null:
		_settings_panel.visible = not _settings_panel.visible
		return
	_settings_panel = CenterContainer.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# only the panel itself should catch clicks, not the whole screen
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_settings_panel)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	_settings_panel.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	col.add_child(title)
	var note := Label.new()
	note.text = "Nothing to configure yet."
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	col.add_child(note)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: _settings_panel.visible = false)
	col.add_child(close)

var _banner_center: CenterContainer

func _build_banner() -> void:
	_banner_center = CenterContainer.new()
	_banner_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner_center.offset_top = 8
	_banner_center.offset_bottom = 56
	_banner_center.visible = false
	add_child(_banner_center)
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", _panel_style(Color(0.20, 0.32, 0.16, 0.95)))
	_banner_center.add_child(_banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_banner.add_child(row)
	_banner_label = Label.new()
	_banner_label.add_theme_font_size_override("font_size", 14)
	_banner_label.add_theme_color_override("font_color", Color(0.95, 1.0, 0.9))
	row.add_child(_banner_label)
	var cancel := Button.new()
	cancel.text = "✕ Done"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.add_theme_font_size_override("font_size", 13)
	cancel.pressed.connect(func() -> void: cancel_pressed.emit())
	row.add_child(cancel)

func set_mode_banner(text: String, show: bool) -> void:
	_banner_center.visible = show and text != ""
	_banner_label.text = text

func flash_money() -> void:
	var tw := _money_box.create_tween()
	tw.tween_property(_money_box, "modulate", Color(1.6, 0.6, 0.6), 0.1)
	tw.tween_property(_money_box, "modulate", Color.WHITE, 0.3)

func _refresh() -> void:
	_money_label.text = str(Game.money)
	_level_label.text = "Level %d" % Game.level
	_xp_bar_fill.size.x = maxf(0.0, (_xp_bar_bg.custom_minimum_size.x - 2.0) * clampf(Game.xp_in_level / Game.xp_to_next(), 0.0, 1.0))

func _on_level_up(new_level: int) -> void:
	var lbl := Label.new()
	lbl.text = "Level %d!" % new_level
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color(0.4, 0.25, 0.1))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.anchor_left = 0.5
	lbl.anchor_right = 0.5
	lbl.anchor_top = 0.35
	lbl.anchor_bottom = 0.35
	add_child(lbl)
	await get_tree().process_frame
	lbl.position.x = -lbl.size.x / 2.0
	var tw := lbl.create_tween()
	lbl.scale = Vector2(0.3, 0.3)
	lbl.pivot_offset = lbl.size / 2.0
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)
