extends Node2D
class_name Animal
## Chicken or cow. Wanders inside its home area. Cycle: hungry -> eat one
## feed unit -> produce for a fixed time -> deposit product in the barn ->
## hungry again. No feed available -> idles with a hungry bubble (no fail).

enum State { HUNGRY, EATING, PRODUCING }

var kind: String              # "chicken" | "cow"
var home: Structure
var _bounds: Rect2            # wander area, clipped to the walkable map

var state: int = State.HUNGRY
var timer: float = 0.0
var cycle_total: float = 0.0

var _sprite: Sprite2D
var _bubble: Sprite2D
var _idle_tex: Texture2D
var _eat_tex: Texture2D
var _wander_target: Vector2
var _wander_pause: float = 0.0
var _feed_check: float = 0.0

func setup(p_kind: String, p_home: Structure, grid: FarmGrid) -> void:
	kind = p_kind
	home = p_home
	# Wander only where the home strip overlaps the walkable map, so animals
	# never stray off the ground into the off-map void.
	_bounds = home.home_rect().intersection(grid.play_rect)
	if _bounds.get_area() <= 0.0:
		_bounds = home.home_rect()

func _ready() -> void:
	_idle_tex = ItemDB.tex("res://assets/animals/%s_idle.png" % kind)
	_eat_tex = ItemDB.tex("res://assets/animals/%s_eat.png" % kind)
	_sprite = Sprite2D.new()
	_sprite.texture = _idle_tex
	add_child(_sprite)
	_apply_tex(_idle_tex)

	_bubble = Sprite2D.new()
	_bubble.texture = ItemDB.tex("res://assets/ui/bubble_hungry.png")
	_bubble.scale = Vector2.ONE * (26.0 / _bubble.texture.get_width())
	_bubble.visible = false
	add_child(_bubble)

	global_position = _random_home_point()
	_wander_target = _random_home_point()

func _apply_tex(t: Texture2D) -> void:
	_sprite.texture = t
	var w := BalanceData.get_value("disp_" + kind, 40.0)
	var s := w / t.get_width()
	_sprite.scale = Vector2.ONE * s
	_sprite.position = Vector2(0, -t.get_height() * s * 0.5)
	_bubble_pos()

func _bubble_pos() -> void:
	if _bubble:
		_bubble.position = Vector2(10, -_sprite.texture.get_height() * _sprite.scale.y - 10)

func _random_home_point() -> Vector2:
	var r := _bounds.grow(-8.0)
	if r.get_area() <= 0.0:
		r = _bounds
	return Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))

func _process(delta: float) -> void:
	match state:
		State.HUNGRY:
			_feed_check -= delta
			if _feed_check <= 0.0:
				_feed_check = 0.5
				var feed := kind + "_feed"
				if Game.remove_item(feed, 1):
					state = State.EATING
					timer = BalanceData.get_value("animal_eat_duration", 2.5)
					_apply_tex(_eat_tex)
					_bubble.visible = false
				else:
					_bubble.visible = true
			_wander(delta)
		State.EATING:
			timer -= delta
			if timer <= 0.0:
				state = State.PRODUCING
				cycle_total = BalanceData.get_value(kind + "_cycle_time", 30.0)
				timer = cycle_total
				_apply_tex(_idle_tex)
		State.PRODUCING:
			timer -= delta
			_wander(delta)
			if timer <= 0.0:
				var product := "egg" if kind == "chicken" else "milk"
				Game.add_item(product, 1)
				state = State.HUNGRY
				_feed_check = 0.0
				get_tree().call_group("main", "notify_deposit", product, 1, global_position)

func _wander(delta: float) -> void:
	if _wander_pause > 0.0:
		_wander_pause -= delta
		return
	var speed := BalanceData.get_value("animal_wander_speed", 22.0)
	var to_target := _wander_target - global_position
	if to_target.length() < 4.0:
		_wander_pause = randf_range(1.0, 4.0)
		_wander_target = _random_home_point()
		return
	global_position += to_target.normalized() * speed * delta
	global_position = global_position.clamp(_bounds.position, _bounds.end)
	_sprite.flip_h = to_target.x > 0.0
