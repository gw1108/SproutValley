extends Node
## Dev harness (not a gdUnit test): boots Main, waits, saves a screenshot,
## optionally simulates clicks, then quits. Run with:
##   godot --path sprout-valley res://test/BootProbe.tscn -- [out.png] [script]
## "script" is a comma list of timed actions, e.g. "1.0:click:500,300"

var out_path := "boot_probe.png"
var main: Node

func _ready() -> void:
	Input.use_accumulated_input = false   # keep every synthetic drag motion event
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		out_path = args[0]
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	_run(args)

func _run(args: PackedStringArray) -> void:
	await get_tree().create_timer(0.8).timeout
	if args.size() >= 2:
		for step in args[1].split(";"):
			var parts := step.split(":")
			if parts.size() < 2:
				continue
			await get_tree().create_timer(float(parts[0])).timeout
			if parts[1] == "click" and parts.size() >= 3:
				var xy := parts[2].split(",")
				_click(Vector2(float(xy[0]), float(xy[1])))
			elif parts[1] == "drag" and parts.size() >= 4:
				var a := parts[2].split(",")
				var b := parts[3].split(",")
				_drag(Vector2(float(a[0]), float(a[1])), Vector2(float(b[0]), float(b[1])))
			elif parts[1] == "give" and parts.size() >= 3:
				var kv := parts[2].split(",")
				get_node("/root/Game").add_item(kv[0], int(kv[1]))
			elif parts[1] == "earn" and parts.size() >= 3:
				get_node("/root/Game").earn(int(parts[2]))
			elif parts[1] == "plot" and parts.size() >= 3:
				var c := parts[2].split(",")
				main.spawn_plot(Vector2i(int(c[0]), int(c[1])))
			elif parts[1] == "plant" and parts.size() >= 3:
				main.interaction.start_planting(parts[2])
			elif parts[1] == "mature":
				for p in get_tree().get_nodes_in_group("interactable"):
					if p is FarmPlot and p.state == FarmPlot.State.GROWING:
						p.grow_elapsed = p.grow_total
			elif parts[1] == "esc":
				var ev := InputEventKey.new()
				ev.keycode = KEY_ESCAPE
				ev.pressed = true
				Input.parse_input_event(ev)
				var ev2 := InputEventKey.new()
				ev2.keycode = KEY_ESCAPE
				Input.parse_input_event(ev2)
			elif parts[1] == "shot" and parts.size() >= 3:
				await _shot(":".join(parts.slice(2)))   # rejoin Windows drive-letter colons
	await get_tree().create_timer(0.3).timeout
	await _shot(out_path)
	get_tree().quit()

func _click(pos: Vector2) -> void:
	Input.warp_mouse(pos)   # keep get_global_mouse_position() in sync
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	Input.parse_input_event(move)
	_mouse_button(pos, true)
	_mouse_button(pos, false)
	Input.flush_buffered_events()

func _drag(from: Vector2, to: Vector2) -> void:
	Input.warp_mouse(from)
	_mouse_button(from, true)
	var steps := 12
	for i in range(steps + 1):
		var p := from.lerp(to, float(i) / steps)
		Input.warp_mouse(p)
		var ev := InputEventMouseMotion.new()
		ev.position = p
		ev.global_position = p
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(ev)
	_mouse_button(to, false)

func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.global_position = pos
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SCREENSHOT saved: ", path)
