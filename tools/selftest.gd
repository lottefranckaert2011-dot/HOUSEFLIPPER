extends Node
## Dev tool: plays through the first jobs automatically and checks the results.
## godot --headless -- --selftest
## (Game autoload adds this node when it sees --selftest.)

var world: GameWorld
var failures := 0


func _ready() -> void:
	await _frames(2)
	Game.reset_progress()
	get_tree().reload_current_scene()
	await _frames(5)
	world = get_tree().current_scene as GameWorld
	world.hud._on_play()
	world.hud.tablet.close()
	var start_money := Game.money

	# Job 1: clean living room and kitchen.
	_check(world.current_job()["id"] == "cleanup", "first job is cleanup")
	for m: Mess in world.mess_root.get_children():
		if m.room in ["living", "kitchen"]:
			if m.kind == "trash":
				m.pick_up(Vector3.ZERO)
			else:
				m.scrub(10.0)
	for f: Furniture in world.furniture_root.get_children():
		if f.junk and HouseLayout.room_at(f.global_position) in ["living", "kitchen"]:
			world.remove_junk(f)
	await _frames(40)
	_check(world.tasks_done(), "cleanup tasks done: %s" % str(world.task_progress()))
	_check(Game.money > start_money, "earned money from cleaning (%d)" % Game.money)
	world.complete_job()
	await _frames(5)
	_check(Game.job_index == 1, "advanced to job 2")

	# Job 2: bathroom.
	Game.money += 5000
	for m: Mess in world.mess_root.get_children():
		if m.room == "bathroom" and m.kind == "dirt":
			m.scrub(10.0)
	for f: Furniture in world.furniture_root.get_children():
		if f.junk and HouseLayout.room_at(f.global_position) == "bathroom":
			world.remove_junk(f)
	_check(
		world.apply_finish(world.room_surfaces("bathroom", "wall"), "tiles_white"),
		"tiled bathroom walls"
	)
	_check(
		world.apply_finish(world.room_surfaces("bathroom", "floor"), "tiles_beige"),
		"tiled bathroom floor"
	)
	var placements := [
		["toilet", Transform3D(Basis(), Vector3(10.3, 0.004, 9.3))],
		["sink", Transform3D(Basis(), Vector3(8.0, 0.004, 9.5))],
		["shower", Transform3D(Basis(), Vector3(10.2, 0.004, 7.0))],
		["mirror", Transform3D(Basis.looking_at(Vector3.BACK), Vector3(8.0, 1.6, 9.89))],
	]
	for p in placements:
		_check(world.buy_and_place(p[0], p[1]), "bought " + p[0])
	await _frames(40)
	_check(world.tasks_done(), "bathroom tasks done: %s" % str(world.task_progress()))

	# Ghost placement: look at the living room floor in build mode.
	var tools := world.player.tools
	world.player.global_position = Vector3(4, 0, 3)
	world.player.set_look(0, -0.7)
	tools.select_item("coffee_table")
	await _frames(5)
	_check(tools._ghost != null and tools._ghost.visible, "ghost visible when aiming at floor")
	_check(tools._ghost_valid, "ghost valid on empty floor")
	tools.cancel_build()

	# Save + restore.
	world._save_house()
	Game.save_game()
	var furn_before: int = Game.house["furniture"].size()
	get_tree().reload_current_scene()
	await _frames(5)
	world = get_tree().current_scene as GameWorld
	var count := 0
	for f: Furniture in world.furniture_root.get_children():
		if not f.junk:
			count += 1
	_check(
		count == furn_before and count == 4,
		"furniture restored after reload (%d/%d)" % [count, furn_before]
	)
	_check(
		world.room_surfaces("bathroom", "floor")[0].finish_id == "tiles_beige", "finish restored"
	)
	_check(Game.job_index == 1, "job index restored")
	_check(world.tasks_done(), "bathroom still done after reload")

	var v := world.house_value()
	_check(
		v["furniture"] > 0 and v["finishes"] > 0 and v["total"] >= 5000,
		"house value computed (%s)" % str(v)
	)

	Game.reset_progress()
	print("SELFTEST %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
