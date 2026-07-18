extends Node
## Autoload: ItemDB. Static definitions of items, crops, recipes and buildings.
## Prices/times are looked up from BalanceData at point of use.

const ICONS := "res://assets/icons/"
const CROPS_DIR := "res://assets/crops/"
const BUILDINGS_DIR := "res://assets/buildings/"
const WORLD_DIR := "res://assets/world/"

# Goods that exist in inventory. storage: silo (crops) | barn (everything else).
var items := {
	"wheat": {"name": "Wheat", "icon": "icon_wheat", "sell": "wheat_sell", "xp": "wheat_xp", "storage": "silo"},
	"corn": {"name": "Corn", "icon": "icon_corn", "sell": "corn_sell", "xp": "corn_xp", "storage": "silo"},
	"soybean": {"name": "Soybean", "icon": "icon_soybean", "sell": "soybean_sell", "xp": "soybean_xp", "storage": "silo"},
	"potato": {"name": "Potato", "icon": "icon_potato", "sell": "potato_sell", "xp": "potato_xp", "storage": "silo"},
	"egg": {"name": "Egg", "icon": "icon_egg", "sell": "egg_sell", "xp": "egg_xp", "storage": "barn"},
	"milk": {"name": "Milk", "icon": "icon_milk", "sell": "milk_sell", "xp": "milk_xp", "storage": "barn"},
	"butter": {"name": "Butter", "icon": "icon_butter", "sell": "butter_sell", "xp": "butter_xp", "storage": "barn"},
	"bread": {"name": "Bread", "icon": "icon_bread", "sell": "bread_sell", "xp": "bread_xp", "storage": "barn"},
	"chicken_feed": {"name": "Chicken Feed", "icon": "icon_chicken_feed", "sell": "", "xp": "", "storage": "barn"},
	"cow_feed": {"name": "Cow Feed", "icon": "icon_cow_feed", "sell": "", "xp": "", "storage": "barn"},
	"wheat_seed": {"name": "Wheat Seed", "icon": "icon_wheat_seed", "sell": "", "xp": "", "storage": "barn"},
	"corn_seed": {"name": "Corn Seed", "icon": "icon_corn_seed", "sell": "", "xp": "", "storage": "barn"},
	"soybean_seed": {"name": "Soybean Seed", "icon": "icon_soybean_seed", "sell": "", "xp": "", "storage": "barn"},
	"potato_seed": {"name": "Potato Seed", "icon": "icon_potato_seed", "sell": "", "xp": "", "storage": "barn"},
	"axe": {"name": "Axe", "icon": "icon_axe", "sell": "", "xp": "", "storage": "barn"},
	"saw": {"name": "Saw", "icon": "icon_saw", "sell": "", "xp": "", "storage": "barn"},
}

# crop id -> seed item, grow time key, stage textures
var crops := {
	"wheat": {"seed": "wheat_seed", "grow": "wheat_grow_time"},
	"corn": {"seed": "corn_seed", "grow": "corn_grow_time"},
	"soybean": {"seed": "soybean_seed", "grow": "soybean_grow_time"},
	"potato": {"seed": "potato_seed", "grow": "potato_grow_time"},
}

# recipe id -> building, inputs, output, craft-time key
var recipes := {
	"chicken_feed": {"building": "feed_mill", "inputs": {"wheat": 2}, "out": "chicken_feed", "qty": 1, "time": "chicken_feed_craft_time"},
	"cow_feed": {"building": "feed_mill", "inputs": {"corn": 2, "soybean": 1}, "out": "cow_feed", "qty": 1, "time": "cow_feed_craft_time"},
	"butter": {"building": "dairy_barn", "inputs": {"milk": 3}, "out": "butter", "qty": 1, "time": "butter_craft_time"},
	"bread": {"building": "bakery", "inputs": {"wheat": 2}, "out": "bread", "qty": 1, "time": "bread_craft_time"},
}

# placeable/pre-placed structures. footprint in grid cells, disp = balance key
# for on-screen sprite width.
var buildings := {
	"player_home": {"name": "Home", "tex": "player_home", "footprint": Vector2i(3, 2), "disp": "disp_player_home"},
	"barn": {"name": "Barn", "tex": "barn", "footprint": Vector2i(3, 2), "disp": "disp_barn"},
	"silo": {"name": "Silo", "tex": "silo", "footprint": Vector2i(2, 2), "disp": "disp_silo"},
	"delivery_box": {"name": "Delivery Box", "tex": "delivery_box", "footprint": Vector2i(2, 1), "disp": "disp_delivery_box", "dir": WORLD_DIR},
	"chicken_coop": {"name": "Chicken Coop", "tex": "chicken_coop", "footprint": Vector2i(2, 2), "disp": "disp_chicken_coop", "cost": "chicken_coop_cost", "max": 1},
	"cow_pasture": {"name": "Cow Pasture", "tex": "cow_pasture", "footprint": Vector2i(4, 3), "disp": "disp_cow_pasture", "cost": "cow_pasture_cost", "max": 1},
	"feed_mill": {"name": "Feed Mill", "tex": "feed_mill", "footprint": Vector2i(2, 2), "disp": "disp_feed_mill", "cost": "feed_mill_cost", "max": 1},
	"dairy_barn": {"name": "Dairy Barn", "tex": "dairy_barn", "footprint": Vector2i(3, 2), "disp": "disp_dairy_barn", "cost": "dairy_barn_cost", "max": 1},
	"bakery": {"name": "Bakery", "tex": "bakery", "footprint": Vector2i(2, 2), "disp": "disp_bakery", "cost": "bakery_cost", "max": 1},
}

var _tex_cache: Dictionary = {}

func tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]

func icon(item_id: String) -> Texture2D:
	if items.has(item_id):
		return tex(ICONS + items[item_id]["icon"] + ".png")
	return null

func crop_stage_tex(crop_id: String, stage: int) -> Texture2D:
	return tex(CROPS_DIR + "%s_stage%d.png" % [crop_id, stage])

func building_tex(building_id: String) -> Texture2D:
	var b: Dictionary = buildings[building_id]
	var dir: String = b.get("dir", BUILDINGS_DIR)
	return tex(dir + b["tex"] + ".png")

func sell_price(item_id: String) -> int:
	var key: String = items[item_id]["sell"]
	if key == "":
		return 0
	return int(BalanceData.get_value(key, 0.0))

func xp_value(item_id: String) -> float:
	var key: String = items[item_id]["xp"]
	if key == "":
		return 0.0
	return BalanceData.get_value(key, 0.0)

func is_sellable(item_id: String) -> bool:
	return items[item_id]["sell"] != ""
