extends Node
## Dev tool: plays the game through simulated mouse clicks and key presses,
## the same way a player would, and reports anything that goes wrong.
## godot -- --playtest   (Game autoload adds this node when it sees --playtest.)

var world: GameWorld
var failures := 0


func _ready() -> void:
	await _frames(2)
	Game.reset_progress()
	get_tree().reload_current_scene()
	await _frames(5)
	world = get_tree().current_scene

	# Main menu -> Play (real click).
	await _click_button(world.hud.menu, "Play")
	_check(Game.playing, "Play button starts the game")
	_check(world.hud.tablet.visible, "tablet opens with the first job")
	await _key(KEY_TAB)
	_check(not world.hud.tablet.visible, "Tab closes the tablet")

	# Tools switch with number keys.
	for i in 5:
		await _key(KEY_1 + i)
		_check(world.player.tools.tool == i, "key %d selects tool %d" % [i + 1, i])
	await _key(KEY_1)

	# Clean the living room and kitchen.
	_clean(["living", "kitchen"])
	await _frames(40)
	_check(world.tasks_done(), "cleanup tasks done")
	_check(world.hud._done_banner.visible, "job-done banner shows")

	# Finish the job through the tablet (this used to crash).
	await _key(KEY_TAB)
	var money := Game.money
	await _click_button(world.hud.tablet, "Complete Job")
	await _frames(10)
	_check(is_instance_valid(world) and Game.job_index == 1, "Complete Job advances to job 2")
	_check(Game.money > money, "job reward paid")
	_check(
		world.hud.tablet.visible and _find(world.hud.tablet, "Bathroom Makeover") != null,
		"tablet shows the next job"
	)
	await _key(KEY_TAB)

	# Catalog: switch tabs and pick an item with real clicks (tab buttons used to crash).
	world.player.global_position = Vector3(9.0, 0, 7.4)
	world.player.set_look(PI, -0.95)
	await _key(KEY_5)
	await _key(KEY_Q)
	_check(world.hud.picker.visible, "Q opens the catalog")
	await _click_button(world.hud.picker, "Bathroom")
	await _frames(3)
	_check(_find(world.hud.picker, "Toilet") != null, "Bathroom tab lists the toilet")
	await _click_card(world.hud.picker, "Toilet")
	_check(not world.hud.picker.visible, "picking an item closes the catalog")
	_check(world.player.tools.build_item == "toilet", "toilet selected for placing")
	await _frames(5)
	print("    mouse mode: %d  hint: %s" % [Input.mouse_mode, world.player.tools._hint])
	_check(world.player.tools._ghost_valid, "toilet preview is placeable on the bathroom floor")
	money = Game.money
	await _mouse(MOUSE_BUTTON_LEFT)
	await _frames(5)
	var toilets := world.furniture_root.get_children().filter(func(f): return f.item_id == "toilet")
	_check(
		toilets.size() == 1 and Game.money == money - 150, "left click buys and places the toilet"
	)
	# Nothing may be placed where the player stands.
	world.player.tools.select_item("sofa")
	world.player.set_look(PI, -1.5)
	await _frames(5)
	_check(not world.player.tools._ghost_valid, "can't place a sofa on top of yourself")
	world.player.set_look(PI, -0.95)
	await _mouse(MOUSE_BUTTON_RIGHT)
	_check(world.player.tools.build_item == "", "right click cancels placing")

	# Paint tool through the catalog.
	world.player.set_look(PI, -0.3)
	await _key(KEY_3)
	await _key(KEY_Q)
	await _click_button(world.hud.picker, "Tiles")
	await _click_card(world.hud.picker, "White Tiles")
	_check(world.player.tools.wall_finish == "tiles_white", "picked white tiles")
	await _frames(3)
	money = Game.money
	print("    mouse mode: %d  hint: %s" % [Input.mouse_mode, world.player.tools._hint])
	await _mouse(MOUSE_BUTTON_LEFT)
	await _frames(3)
	_check(Game.money == money - 45, "left click tiles one wall (%d -> %d)" % [money, Game.money])

	# Pause and resume.
	await _key(KEY_ESCAPE)
	await _frames(3)

	# Jump to the sale and sell through the tablet.
	Game.job_index = Jobs.count() - 1
	world._recompute_tasks()
	await _key(KEY_TAB)
	world.hud.tablet.refresh()
	await _frames(2)
	money = Game.money
	await _click_button(world.hud.tablet, "Sell House")
	await _frames(5)
	_check(Game.money > money and Game.house_no == 2, "Sell House pays out and moves to house #2")
	await _key(KEY_TAB)
	_check(world.hud.tablet.visible, "sold screen can't be closed (must go to next house)")
	await _click_button(world.hud.tablet, "Next House  >")
	await _frames(15)
	world = get_tree().current_scene
	_check(Game.house_no == 2 and Game.job_index == 0, "next house loaded")
	_check(world.mess_root.get_child_count() > 20, "new house is messy again")

	Game.reset_progress()
	print("PLAYTEST %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures else 0)


func _clean(rooms: Array) -> void:
	for m: Mess in world.mess_root.get_children():
		if m.room in rooms:
			if m.kind == "trash":
				m.pick_up(Vector3.ZERO)
			else:
				m.scrub(10.0)
	for f: Furniture in world.furniture_root.get_children():
		if f.junk and HouseLayout.room_at(f.global_position) in rooms:
			world.remove_junk(f)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = code
		e.keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
		await _frames(2)


func _mouse(button: MouseButton, pos := Vector2(640, 360)) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = button
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		Input.parse_input_event(e)
		await _frames(2)


func _click_button(root: Node, text: String) -> void:
	var b := _find(root, text)
	if not b:
		_check(false, "button '%s' exists" % text)
		return
	var pos := b.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	Input.parse_input_event(move)
	await _frames(1)
	await _mouse(MOUSE_BUTTON_LEFT, pos)


## Clicks the catalog card whose name label matches `text`.
func _click_card(root: Node, text: String) -> void:
	var l := _find_label(root, text)
	if not l:
		_check(false, "card '%s' exists" % text)
		return
	await _mouse(MOUSE_BUTTON_LEFT, l.get_global_rect().get_center())


func _find(n: Node, text: String) -> Control:
	if (n is Button or n is Label) and n.text == text and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var b := _find(c, text)
		if b:
			return b
	return null


func _find_label(n: Node, text: String) -> Label:
	var c := _find(n, text)
	return c as Label
