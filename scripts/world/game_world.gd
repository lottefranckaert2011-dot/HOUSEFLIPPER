class_name GameWorld
extends Node3D
## Root of the game scene. Builds the level, restores saved progress, owns the
## player and UI, tracks job tasks and handles buying, selling and finishes.

signal tasks_updated(progress: Array, all_done: bool)
signal job_changed

var house: HouseBuilder
var yard: YardBuilder
var player: Player
var hud: Hud
var menu_camera: Camera3D
var furniture_root: Node3D
var mess_root: Node3D

var _task_progress := []
var _tasks_done := false
var _dirty := false
var _menu_t := 0.0
var _mess_layout := {}


func _ready() -> void:
	_build_environment()
	house = HouseBuilder.new()
	house.name = "House"
	add_child(house)
	house.build()
	yard = YardBuilder.new()
	yard.name = "Yard"
	add_child(yard)
	yard.build()

	furniture_root = Node3D.new()
	furniture_root.name = "Furniture"
	add_child(furniture_root)
	mess_root = Node3D.new()
	mess_root.name = "Mess"
	add_child(mess_root)
	_restore_house()

	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.tools.world = self
	player.position = HouseLayout.PLAYER_START
	player.set_look(PI)

	menu_camera = Camera3D.new()
	menu_camera.fov = 60
	add_child(menu_camera)
	menu_camera.current = true

	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.setup(self)

	_recompute_tasks()
	CrazySDK.loading_stop()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.18, 0.47, 0.92)
	mat.sky_horizon_color = Color(0.62, 0.8, 0.97)
	mat.ground_horizon_color = Color(0.62, 0.8, 0.97)
	mat.ground_bottom_color = Color(0.3, 0.4, 0.3)
	mat.sun_angle_max = 20.0
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


# --- Saving & restoring -----------------------------------------------------------


func _restore_house() -> void:
	var state: Dictionary = Game.house
	var removed: Array = state.get("removed", [])
	var spawner := MessSpawner.new(Game.house_no * 7919 + 13)
	var spawned := spawner.spawn(removed)
	_mess_layout = spawner.layout
	for m: Mess in spawned["mess"]:
		mess_root.add_child(m)
		m.removed.connect(_on_mess_removed)
	for f: Furniture in spawned["junk"]:
		furniture_root.add_child(f)
	var finishes: Dictionary = state.get("finishes", {})
	for key in finishes:
		if house.surfaces.has(key):
			house.surfaces[key].apply(finishes[key])
	for entry in state.get("furniture", []):
		if not Catalog.ITEMS.has(entry["id"]):
			continue
		var f := Furniture.create(entry["id"])
		furniture_root.add_child(f)
		var p: Array = entry["pos"]
		f.global_position = Vector3(p[0], p[1], p[2])
		var r: Array = entry["rot"]
		f.global_rotation = Vector3(r[0], r[1], r[2])


func _save_house() -> void:
	var finishes := {}
	for key in house.surfaces:
		var s: Surface = house.surfaces[key]
		if s.finish_id != HouseLayout.ROOMS[s.room][s.kind]:
			finishes[key] = s.finish_id
	var furn := []
	for f: Furniture in furniture_root.get_children():
		if f.junk or f.is_queued_for_deletion():
			continue
		var p := f.global_position
		var r := f.global_rotation
		furn.append({"id": f.item_id, "pos": [p.x, p.y, p.z], "rot": [r.x, r.y, r.z]})
	var removed: Array = Game.house.get("removed", [])
	Game.house = {"finishes": finishes, "furniture": furn, "removed": removed}
	Game.queue_save()


func _mark_removed(key: String) -> void:
	var removed: Array = Game.house.get("removed", [])
	if key not in removed:
		removed.append(key)
	Game.house["removed"] = removed


func _changed() -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty:
		_dirty = false
		_save_house()
		_recompute_tasks()
	if menu_camera.current:
		_menu_t += delta * 0.06
		var center := Vector3(7, 1.5, 8)
		var p := center + Vector3(sin(_menu_t) * 24.0, 9.0, -cos(_menu_t) * 24.0)
		menu_camera.global_position = p
		menu_camera.look_at(center)


# --- Game flow --------------------------------------------------------------------


func start_playing() -> void:
	player.camera.current = true
	Game.playing = true
	Game.capture_mouse()
	Sfx.start_music()
	CrazySDK.gameplay_start()


func show_menu() -> void:
	Game.playing = false
	menu_camera.current = true
	CrazySDK.gameplay_stop()


func current_job() -> Dictionary:
	return Jobs.get_job(Game.job_index)


func is_sell_job() -> bool:
	return current_job()["id"] == "sell"


func task_progress() -> Array:
	return _task_progress


func tasks_done() -> bool:
	return _tasks_done


func complete_job() -> void:
	if not _tasks_done or is_sell_job():
		return
	var reward := Jobs.reward(Game.job_index, Game.house_no)
	Game.add_money(reward, "Job complete: " + current_job()["title"])
	Sfx.play("complete", 0.0)
	CrazySDK.happytime()
	Game.job_index += 1
	Game.save_game()
	_recompute_tasks()
	job_changed.emit()
	# A natural break: show a midgame ad between jobs.
	CrazySDK.request_midgame_ad()


## Price the house would sell for right now.
func house_value() -> Dictionary:
	var base := 18000 + 4000 * (Game.house_no - 1)
	var furniture := 0
	for f: Furniture in furniture_root.get_children():
		if not f.junk and not f.is_queued_for_deletion():
			furniture += int(f.data()["price"] * 1.3)
	var finishes := 0
	for s: Surface in house.surfaces.values():
		if not s.is_old():
			finishes += int(s.finish_data()["price"] * 1.6) + 25
	var mess_left := mess_root.get_child_count()
	var junk_left := 0
	for f: Furniture in furniture_root.get_children():
		if f.junk:
			junk_left += 1
	var penalty := mess_left * 40 + junk_left * 150
	return {
		"base": base,
		"furniture": furniture,
		"finishes": finishes,
		"penalty": penalty,
		"total": maxi(base + furniture + finishes - penalty, 5000)
	}


func sell_house() -> int:
	var v := house_value()
	var profit: int = v["total"] - 15000 - 3000 * (Game.house_no - 1)
	Game.add_money(maxi(profit, 500), "House sold!")
	Sfx.play("complete", 0.0)
	CrazySDK.happytime()
	Game.start_next_house()
	return v["total"]


func load_next_house() -> void:
	CrazySDK.gameplay_stop()
	Game.playing = false
	CrazySDK.ad_finished.connect(func(_ok): get_tree().reload_current_scene(), CONNECT_ONE_SHOT)
	CrazySDK.request_midgame_ad()


# --- Actions used by the tools ------------------------------------------------------


func _on_mess_removed(m: Mess) -> void:
	_mark_removed(m.key)
	Game.add_money(m.reward(), m.display_name)
	_changed()


func remove_junk(f: Furniture) -> void:
	_mark_removed(f.key)
	Game.add_money(int(f.data()["value"]), "Sold " + f.display_name() + " for scrap")
	Sfx.play("whoosh")
	sparkle(f.global_position + Vector3(0, 0.4, 0), false)
	f.collision_layer = 0
	var tw := create_tween()
	tw.tween_property(f, "scale", Vector3.ONE * 0.01, 0.25).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(f.queue_free)
	tw.tween_callback(_changed)


func buy_and_place(id: String, xf: Transform3D) -> bool:
	var data := Catalog.item(id)
	if not Game.spend(data["price"], data["name"]):
		return false
	var f := Furniture.create(id)
	furniture_root.add_child(f)
	f.global_transform = xf
	_pop_in(f)
	Sfx.play("place")
	_changed()
	return true


func move_furniture(f: Furniture, xf: Transform3D) -> void:
	f.global_transform = xf
	f.visible = true
	f.collision_layer = Geo.LAYER_WORLD
	_pop_in(f)
	Sfx.play("place")
	_changed()


func return_furniture(f: Furniture) -> void:
	Game.add_money(int(f.data()["price"]), "Returned " + f.display_name())
	Sfx.play("whoosh")
	f.collision_layer = 0
	f.queue_free()
	_changed.call_deferred()


func apply_finish(targets: Array, id: String) -> bool:
	var todo := targets.filter(func(s): return s.finish_id != id)
	if todo.is_empty():
		return false
	var data := Catalog.finish(todo[0].kind, id)
	var cost: int = data["price"] * todo.size()
	if not Game.spend(cost, data["name"]):
		return false
	for s: Surface in todo:
		s.apply(id)
		var tw := create_tween()
		s.mesh_instance.transparency = 0.6
		tw.tween_property(s.mesh_instance, "transparency", 0.0, 0.35)
	Sfx.play("paint")
	_changed()
	return true


func room_surfaces(room: String, kind: String) -> Array:
	var out := []
	for s: Surface in house.surfaces.values():
		if s.room == room and s.kind == kind:
			out.append(s)
	return out


func sparkle(pos: Vector3, leaves: bool) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.6
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.4
	p.gravity = Vector3(0, -4, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.45, 0.75, 0.3) if leaves else Color(1.0, 1.0, 0.85)
	mesh.material = mat
	p.mesh = mesh
	add_child(p)
	p.global_position = pos
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _pop_in(f: Furniture) -> void:
	f.scale = Vector3.ONE * 0.85
	(
		create_tween()
		. tween_property(f, "scale", Vector3.ONE, 0.18)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


# --- Tasks --------------------------------------------------------------------------


func _recompute_tasks() -> void:
	var job := current_job()
	var progress := []
	var all_done := true
	for t in job["tasks"]:
		var res := _evaluate(t)
		progress.append({"label": Jobs.task_label(t), "done": res[0], "total": res[1]})
		if res[0] < res[1]:
			all_done = false
	var was_done := _tasks_done
	_task_progress = progress
	_tasks_done = all_done and not job["tasks"].is_empty()
	if _tasks_done and not was_done and Game.playing:
		Sfx.play("complete", 0.0)
		Game.notify("All tasks done! Press Tab to finish the job", Color(1, 0.9, 0.4))
	tasks_updated.emit(progress, _tasks_done)


## Returns [done, total] for one task.
func _evaluate(t: Dictionary) -> Array:
	match t["type"]:
		"trash", "dirt", "weeds":
			var kind: String = {"trash": "trash", "dirt": "dirt", "weeds": "weed"}[t["type"]]
			return _count_mess(kind, t.get("rooms", []))
		"junk":
			var total := 0
			var left := 0
			var removed: Array = Game.house.get("removed", [])
			for i in MessSpawner.JUNK_LAYOUT.size():
				var room := HouseLayout.room_at(MessSpawner.JUNK_LAYOUT[i][1])
				if room in t["rooms"]:
					total += 1
					if "junk_%d" % i not in removed:
						left += 1
			return [total - left, total]
		"walls", "floor":
			var kind := "wall" if t["type"] == "walls" else "floor"
			var list := room_surfaces(t["room"], kind)
			var ok := 0
			for s: Surface in list:
				var cat: String = s.finish_data().get("cat", "old")
				if cat != "old" and (t["cat"].is_empty() or cat in t["cat"]):
					ok += 1
			return [ok, list.size()]
		"item":
			var n := 0
			for f: Furniture in furniture_root.get_children():
				if f.junk or f.is_queued_for_deletion() or not f.visible:
					continue
				if (
					f.data().get("cat", "") == t["cat"]
					and HouseLayout.room_at(f.global_position) == t["room"]
				):
					n += 1
			return [mini(n, t["count"]), t["count"]]
	return [0, 1]


func _count_mess(kind: String, rooms: Array) -> Array:
	var total := 0
	for key in _mess_layout:
		var entry: Array = _mess_layout[key]
		if entry[0] == kind and (rooms.is_empty() or entry[1] in rooms):
			total += 1
	var left := 0
	for m: Mess in mess_root.get_children():
		if m.kind == kind and not m.is_gone() and (rooms.is_empty() or m.room in rooms):
			left += 1
	return [total - left, total]
