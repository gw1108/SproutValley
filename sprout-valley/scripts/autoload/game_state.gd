extends Node
## Autoload: Game. Player state — money, XP/level, inventory, owned placeables.

signal money_changed(amount: int)
signal inventory_changed(item_id: String, count: int)
signal xp_changed(xp: float, level: int, to_next: float)
signal level_up(level: int)
signal sold(item_id: String, n: int)

var money: int = 0
var xp_in_level: float = 0.0
var level: int = 1
var inventory: Dictionary = {}          # item_id -> count
var placed_counts: Dictionary = {}      # building_id / "farm_plot" -> count
var animal_counts: Dictionary = {"chicken": 0, "cow": 0}

func _ready() -> void:
	money = int(BalanceData.get_value("start_money", 150.0))

func xp_to_next() -> float:
	var base := BalanceData.get_value("xp_level_base", 4.0)
	return roundf(base * (1.0 + log(float(level))))

func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	xp_in_level += amount
	while xp_in_level >= xp_to_next():
		xp_in_level -= xp_to_next()
		level += 1
		level_up.emit(level)
	xp_changed.emit(xp_in_level, level, xp_to_next())

func can_afford(cost: int) -> bool:
	return money >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	money_changed.emit(money)
	return true

func earn(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func add_item(item_id: String, n: int = 1) -> void:
	inventory[item_id] = count(item_id) + n
	inventory_changed.emit(item_id, inventory[item_id])

func remove_item(item_id: String, n: int = 1) -> bool:
	if count(item_id) < n:
		return false
	inventory[item_id] -= n
	inventory_changed.emit(item_id, inventory[item_id])
	return true

func has_items(reqs: Dictionary) -> bool:
	for id in reqs:
		if count(id) < int(reqs[id]):
			return false
	return true

func take_items(reqs: Dictionary) -> bool:
	if not has_items(reqs):
		return false
	for id in reqs:
		remove_item(id, int(reqs[id]))
	return true

func placed(building_id: String) -> int:
	return placed_counts.get(building_id, 0)

func mark_placed(building_id: String) -> void:
	placed_counts[building_id] = placed(building_id) + 1

func sell(item_id: String, n: int) -> void:
	n = mini(n, count(item_id))
	if n <= 0:
		return
	remove_item(item_id, n)
	earn(ItemDB.sell_price(item_id) * n)
	add_xp(ItemDB.xp_value(item_id) * n)
	sold.emit(item_id, n)
	get_tree().call_group("main", "play_sfx", "switch-b")
