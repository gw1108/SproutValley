extends Control
class_name RadialMenu
## Contextual radial menu: round icon buttons fanned around the click point.
## Options: [{id, icon: Texture2D, label, count, disabled, callback: Callable}]

signal closed

var _buttons: Array = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # click-outside catcher
	visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
		accept_event()

func open(center: Vector2, options: Array) -> void:
	clear()
	visible = true
	var n := options.size()
	var btn_size := BalanceData.get_value("radial_button_size", 52.0)
	var radius := BalanceData.get_value("radial_radius", 56.0)
	if n > 6:
		radius += (n - 6) * 6.0
	# keep the ring on screen
	var vp := get_viewport_rect().size
	center.x = clampf(center.x, radius + btn_size, vp.x - radius - btn_size)
	center.y = clampf(center.y, radius + btn_size, vp.y - radius - btn_size)

	for i in range(n):
		var opt: Dictionary = options[i]
		var angle := -PI / 2.0 + TAU * float(i) / float(n)
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		var btn := _make_button(opt, btn_size)
		btn.position = center - btn.size / 2.0
		add_child(btn)
		_buttons.append(btn)
		var tw := btn.create_tween()
		tw.tween_property(btn, "position", pos - btn.size / 2.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _make_button(opt: Dictionary, btn_size: float) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(btn_size, btn_size)
	btn.size = btn.custom_minimum_size
	btn.tooltip_text = opt.get("label", "")
	btn.disabled = opt.get("disabled", false)
	btn.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.93, 0.82) if not btn.disabled else Color(0.75, 0.72, 0.66)
	sb.set_corner_radius_all(int(btn_size / 2.0))
	sb.border_color = Color(0.55, 0.38, 0.22)
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate()
	sb_h.bg_color = Color(1.0, 0.98, 0.88)
	sb_h.border_color = Color(0.85, 0.6, 0.25)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	btn.add_theme_stylebox_override("disabled", sb)

	var icon_rect := TextureRect.new()
	icon_rect.texture = opt.get("icon")
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var pad := 9.0
	icon_rect.position = Vector2(pad, pad)
	icon_rect.size = Vector2(btn_size - pad * 2.0, btn_size - pad * 2.0)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if btn.disabled:
		icon_rect.modulate = Color(1, 1, 1, 0.5)
	btn.add_child(icon_rect)

	var count: int = opt.get("count", -1)
	if count >= 0:
		var lbl := Label.new()
		lbl.text = str(count)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.25, 0.16, 0.08))
		lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.position = Vector2(btn_size - 20, btn_size - 20)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)

	var cb: Callable = opt.get("callback")
	btn.pressed.connect(func() -> void:
		close()
		if cb.is_valid():
			cb.call())
	return btn

func clear() -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()

func close() -> void:
	clear()
	visible = false
	closed.emit()
