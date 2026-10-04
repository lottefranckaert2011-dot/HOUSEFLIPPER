extends Node
## Global game state: money, progress, settings and saving.

signal money_changed(amount: int, delta: int)
signal toast(text: String, color: Color)
signal ui_changed(open: bool)
signal settings_changed

const SAVE_PATH := "user://save.json"
const START_MONEY := 500
const SAVE_VERSION := 1

var money := START_MONEY
var house_no := 1
var job_index := 0
## Per-house state, filled in by the world: finishes, furniture, removed mess.
var house := {}
var settings := {"sensitivity": 1.0, "music": 0.6, "sfx": 0.8}
var total_earned := 0
var playing := false

var _ui_stack: Array[StringName] = []
var _save_queued := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()
	_start_dev_tools()


## Dev tools in tools/ (not exported) start from command-line flags, e.g.
## godot --headless -- --selftest
func _start_dev_tools() -> void:
	var flags := {
		"--shots": "screenshot",
		"--selftest": "selftest",
		"--thumbs": "thumbnails",
		"--playtest": "playtest"
	}
	for flag in flags:
		var path := "res://tools/%s.gd" % flags[flag]
		if flag in OS.get_cmdline_user_args() and ResourceLoader.exists(path):
			add_child(load(path).new())


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func add_money(amount: int, reason := "") -> void:
	money += amount
	if amount > 0:
		total_earned += amount
	money_changed.emit(money, amount)
	if reason != "":
		var sign_str := "+" if amount >= 0 else "-"
		var col := Color(0.45, 0.9, 0.45) if amount >= 0 else Color(1, 0.55, 0.45)
		toast.emit("%s$%d  %s" % [sign_str, absi(amount), reason], col)
	queue_save()


func can_afford(amount: int) -> bool:
	return money >= amount


func spend(amount: int, reason: String) -> bool:
	if money < amount:
		toast.emit("Not enough money! Need $%d" % amount, Color(1, 0.5, 0.4))
		Sfx.play("error")
		return false
	add_money(-amount, reason)
	Sfx.play("cash")
	return true


func notify(text: String, color := Color.WHITE) -> void:
	toast.emit(text, color)


# --- UI focus -----------------------------------------------------------------


## Opens a UI layer that needs the mouse cursor.
func push_ui(id: StringName) -> void:
	if id in _ui_stack:
		return
	_ui_stack.append(id)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui_changed.emit(true)


func pop_ui(id: StringName) -> void:
	_ui_stack.erase(id)
	ui_changed.emit(is_ui_open())


func is_ui_open() -> bool:
	return not _ui_stack.is_empty()


func capture_mouse() -> void:
	if not is_ui_open() and playing:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- Saving -------------------------------------------------------------------


func queue_save() -> void:
	if _save_queued:
		return
	_save_queued = true
	get_tree().create_timer(1.5, true, false, true).timeout.connect(_flush_save)


func _flush_save() -> void:
	_save_queued = false
	save_game()


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"money": money,
		"house_no": house_no,
		"job_index": job_index,
		"house": house,
		"settings": settings,
		"total_earned": total_earned,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
	if not has_save():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		return
	money = int(data.get("money", START_MONEY))
	house_no = int(data.get("house_no", 1))
	job_index = int(data.get("job_index", 0))
	house = data.get("house", {})
	total_earned = int(data.get("total_earned", 0))
	var s: Dictionary = data.get("settings", {})
	for k in s:
		settings[k] = s[k]


func reset_progress() -> void:
	money = START_MONEY
	house_no = 1
	job_index = 0
	house = {}
	total_earned = 0
	money_changed.emit(money, 0)
	save_game()


func start_next_house() -> void:
	house_no += 1
	job_index = 0
	house = {}
	save_game()


func set_setting(key: String, value) -> void:
	settings[key] = value
	settings_changed.emit()
	queue_save()
