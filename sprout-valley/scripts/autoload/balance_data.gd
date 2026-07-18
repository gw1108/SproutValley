extends Node
## Autoload: BalanceData. Reads data/balance.csv (id,value,notes).
## All tunable scalars live in the CSV — get_value's default is only a
## missing-row fallback.

var _values: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	_values.clear()
	var f := FileAccess.open("res://data/balance.csv", FileAccess.READ)
	if f == null:
		push_error("balance.csv not found")
		return
	var header_skipped := false
	while not f.eof_reached():
		var line := f.get_csv_line()
		if not header_skipped:
			header_skipped = true
			continue
		if line.size() >= 2 and line[0].strip_edges() != "":
			_values[line[0].strip_edges()] = float(line[1])

func get_value(id: String, default: float = 0.0) -> float:
	if _values.has(id):
		return _values[id]
	push_warning("balance.csv missing row: %s" % id)
	return default
