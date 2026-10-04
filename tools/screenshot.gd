extends Node
## Dev tool: renders screenshots of the game from a few camera spots.
## xvfb-run godot --rendering-driver opengl3 -- --shots <out_dir> [shot names...]
## (Game autoload adds this node when it sees --shots.)

var out_dir := "user://shots"
var world: GameWorld


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	args = args.slice(args.find("--shots") + 1)
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _frames(10)
	world = get_tree().current_scene as GameWorld
	world.hud.suppress_pause = true
	var only := args.slice(1)
	var shots := [
		["menu", Callable(self, "_menu")],
		["front", Callable(self, "_spot").bind(Vector3(3.5, 0, -6.5), Vector3(7, 2, 5))],
		["living", Callable(self, "_spot").bind(Vector3(7.2, 0, 1.0), Vector3(2, 0.6, 4.5))],
		["kitchen", Callable(self, "_spot").bind(Vector3(8.6, 0, 1.0), Vector3(13, 0.7, 5))],
		["bathroom", Callable(self, "_spot").bind(Vector3(7.9, 0, 6.6), Vector3(10, 0.8, 9.5))],
		["bedroom", Callable(self, "_spot").bind(Vector3(5.5, 0, 6.6), Vector3(1, 0.6, 9))],
		["backyard", Callable(self, "_spot").bind(Vector3(13, 0, 11.5), Vector3(4, 0, 18))],
		["tablet", Callable(self, "_tablet")],
		["picker", Callable(self, "_picker")],
		["renovated", Callable(self, "_renovated")],
	]
	for s in shots:
		if only.is_empty() or s[0] in only:
			await s[1].call()
			await _frames(8)
			_save(s[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _save(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
	print("saved ", shot_name)


func _menu() -> void:
	await _frames(20)


func _play() -> void:
	if not Game.playing:
		world.hud._on_play()
		world.hud.tablet.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world.hud.pause_overlay.visible = false


func _spot(pos: Vector3, look: Vector3) -> void:
	await _play()
	world.player.global_position = pos
	world.player.velocity = Vector3.ZERO
	var eye := pos + Vector3(0, Player.EYE_HEIGHT, 0)
	var dir := (look - eye).normalized()
	world.player.set_look(atan2(-dir.x, -dir.z), asin(dir.y))
	await _frames(20)
	world.hud.pause_overlay.visible = false


func _tablet() -> void:
	await _play()
	world.hud.tablet.open("job")
	await _frames(5)


func _picker() -> void:
	world.hud.tablet.close()
	world.player.tools.set_tool(ToolController.Tool.BUILD)
	world.hud.picker.open("build")
	await _frames(5)


func _renovated() -> void:
	world.hud.picker.close()
	var saved_money: int = Game.money
	Game.money = 100000
	for s in world.room_surfaces("living", "wall"):
		s.apply("wp_leaf")
	for s in world.room_surfaces("living", "floor"):
		s.apply("carpet_grey")
	for f in world.furniture_root.get_children():
		f.queue_free()
	for m in world.mess_root.get_children():
		if m.room == "living":
			m.queue_free()
	var items := [
		["sofa_corner", Vector3(2.5, 0, 3.6), 0.0],
		["coffee_glass", Vector3(3.6, 0, 2.4), 0.0],
		["tv_cabinet", Vector3(3.4, 0, 0.35), 0.0],
		["tv_modern", Vector3(3.4, 0.62, 0.35), 0.0],
		["rug_rect", Vector3(3.4, 0, 2.6), 0.0],
		["lamp_floor", Vector3(0.6, 0, 5.4), 0.0],
		["plant_potted", Vector3(7.4, 0, 5.4), 0.0],
		["bookcase", Vector3(6.0, 0, 5.75), PI],
		["dining_table", Vector3(6.2, 0, 2.6), PI / 2],
		["chair", Vector3(5.6, 0, 2.6), PI / 2],
		["chair", Vector3(6.8, 0, 2.6), -PI / 2],
	]
	for it in items:
		var f := Furniture.create(it[0])
		world.furniture_root.add_child(f)
		f.global_position = it[1]
		f.rotation.y = it[2]
	Game.money = saved_money
	await _spot(Vector3(6.8, 0, 0.9), Vector3(1.5, 0.3, 4.5))
