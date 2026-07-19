extends Node
## Autoload: ItemDB. Static definitions of items, crops, recipes and buildings.
## Prices/times are looked up from BalanceData at point of use.

const ICONS := "res://assets/icons/"
const CROPS_DIR := "res://assets/crops/"
const BUILDINGS_DIR := "res://assets/buildings/"
const WORLD_DIR := "res://assets/world/"

# Goods that exist in inventory (viewed by tapping the Player Home).
var items := {
	"wheat": {"name": "Wheat", "icon": "icon_wheat", "sell": "wheat_sell", "xp": "wheat_xp"},
	"beets": {"name": "Beets", "icon": "icon_beets", "sell": "beets_sell", "xp": "beets_xp"},
	"cabbage": {"name": "Cabbage", "icon": "icon_cabbage", "sell": "cabbage_sell", "xp": "cabbage_xp"},
	"egg": {"name": "Egg", "icon": "icon_egg", "sell": "egg_sell", "xp": "egg_xp"},
	"milk": {"name": "Milk", "icon": "icon_milk", "sell": "milk_sell", "xp": "milk_xp"},
	"butter": {"name": "Butter", "icon": "icon_butter", "sell": "butter_sell", "xp": "butter_xp"},
	"bread": {"name": "Bread", "icon": "icon_bread", "sell": "bread_sell", "xp": "bread_xp"},
	"chicken_feed": {"name": "Chicken Feed", "icon": "icon_chicken_feed", "sell": "", "xp": ""},
	"cow_feed": {"name": "Cow Feed", "icon": "icon_cow_feed", "sell": "", "xp": ""},
	"axe": {"name": "Axe", "icon": "icon_axe", "sell": "", "xp": ""},
	"saw": {"name": "Saw", "icon": "icon_saw", "sell": "", "xp": ""},
}

# crop id -> grow time key. You plant the crop item itself (no seeds); a mature
# plot yields `harvest_yield` of that same crop, which you replant. All crops
# share the same planted look (2 variations, picked randomly on planting) and
# have a per-crop mature texture.
const PLANTED_VARIANTS := 2

# Choppable world trees come in two sizes, each with N randomly-picked art
# variants (tree_small_1.png … / tree_large_1.png …).
const TREE_SMALL_VARIANTS := 3
const TREE_LARGE_VARIANTS := 2

var crops := {
	"wheat": {"grow": "wheat_grow_time"},
	"beets": {"grow": "beets_grow_time"},
	"cabbage": {"grow": "cabbage_grow_time"},
}

# recipe id -> building, inputs, output, craft-time key
var recipes := {
	"chicken_feed": {"building": "chicken_coop", "inputs": {"wheat": 2}, "out": "chicken_feed", "qty": 1, "time": "chicken_feed_craft_time"},
	"cow_feed": {"building": "barn", "inputs": {"beets": 2, "cabbage": 1}, "out": "cow_feed", "qty": 1, "time": "cow_feed_craft_time"},
	"butter": {"building": "dairy_barn", "inputs": {"milk": 3}, "out": "butter", "qty": 1, "time": "butter_craft_time"},
	"bread": {"building": "bakery", "inputs": {"wheat": 2}, "out": "bread", "qty": 1, "time": "bread_craft_time"},
}

# placeable/pre-placed structures. footprint in grid cells, disp = balance key
# for on-screen sprite width.
var buildings := {
	"player_home": {"name": "Home", "tex": "player_home", "footprint": Vector2i(2, 1), "disp": "disp_player_home"},
	"barn": {"name": "Barn", "tex": "barn", "footprint": Vector2i(2, 1), "disp": "disp_barn", "cost": "barn_cost", "max": 1},
	"delivery_box": {"name": "Delivery Box", "tex": "delivery_box", "footprint": Vector2i(1, 1), "disp": "disp_delivery_box", "dir": WORLD_DIR},
	"chicken_coop": {"name": "Chicken Coop", "tex": "chicken_coop", "footprint": Vector2i(1, 1), "disp": "disp_chicken_coop", "cost": "chicken_coop_cost", "max": 1},
	"dairy_barn": {"name": "Dairy Barn", "tex": "dairy_barn", "footprint": Vector2i(2, 1), "disp": "disp_dairy_barn", "cost": "dairy_barn_cost", "max": 1},
	"bakery": {"name": "Bakery", "tex": "bakery", "footprint": Vector2i(1, 1), "disp": "disp_bakery", "cost": "bakery_cost", "max": 1},
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

func planted_tex(variant: int) -> Texture2D:
	return tex(CROPS_DIR + "planted_%d.png" % clampi(variant, 1, PLANTED_VARIANTS))

func mature_tex(crop_id: String) -> Texture2D:
	return tex(CROPS_DIR + "%s_mature.png" % crop_id)

func tree_tex(big: bool, variant: int) -> Texture2D:
	var size := "large" if big else "small"
	var n := TREE_LARGE_VARIANTS if big else TREE_SMALL_VARIANTS
	return tex(WORLD_DIR + "tree_%s_%d.png" % [size, clampi(variant, 1, n)])

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
