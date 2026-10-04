class_name ToolController
extends Node3D
## The player's tools: hand, sponge, paint roller, flooring and build mode.
## Lives under the camera; raycasts from the screen centre.

signal tool_changed(tool: int)
signal hint_changed(text: String)
signal selection_changed

enum Tool { HAND, CLEAN, PAINT, FLOOR, BUILD }

const TOOL_NAMES := ["Hand", "Sponge", "Paint", "Floor", "Build"]
const REACH := 3.6
const BUILD_REACH := 7.0
const SCRUB_SPEED := {"dirt": 1.25, "weed": 1.6}

var tool := Tool.HAND
var wall_finish := "paint_white"
var floor_finish := "wood_oak"
var build_item := ""
var world: Node  # GameWorld

var _ghost: Furniture
var _ghost_valid := false
var _ghost_yaw := 0.0
var _moving: Furniture
var _hint := ""
var _scrub_sound_t := 0.0
var _held: Node3D
var _held_items := {}
var _use_anim := 0.0
var _query_shape := BoxShape3D.new()


func _ready() -> void:
	_build_held_items()
	_show_held()


func camera() -> Camera3D:
	return get_parent() as Camera3D


func set_tool(t: int) -> void:
	if t == tool:
		return
	if tool == Tool.BUILD and t != Tool.BUILD:
		cancel_build()
	tool = t
	Sfx.play("click")
	_show_held()
	tool_changed.emit(tool)


func select_wall_finish(id: String) -> void:
	wall_finish = id
	set_tool(Tool.PAINT)
	_update_roller_color()
	selection_changed.emit()


func select_floor_finish(id: String) -> void:
	floor_finish = id
	set_tool(Tool.FLOOR)
	selection_changed.emit()


func select_item(id: String) -> void:
	cancel_build()
	build_item = id
	set_tool(Tool.BUILD)
	_make_ghost(id)
	selection_changed.emit()


func cancel_build() -> void:
	if _moving:
		# Put a furniture piece that was being moved back where it was.
		_moving.visible = true
		_moving.collision_layer = Geo.LAYER_WORLD
		_moving = null
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	build_item = ""
	selection_changed.emit()


func _make_ghost(id: String) -> void:
	if _ghost:
		_ghost.queue_free()
	_ghost = Furniture.create(id, true)
	_ghost.visible = false
	world.add_child(_ghost)


# --- Input ----------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if not Game.playing or Game.is_ui_open():
		return
	for i in 5:
		if event.is_action_pressed("tool_%d" % (i + 1)):
			set_tool(i)
			return
	if event.is_action_pressed("rotate_item") and tool == Tool.BUILD:
		_ghost_yaw += deg_to_rad(15.0 if Input.is_key_pressed(KEY_SHIFT) else 90.0)
		Sfx.play("click")
	elif (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
	):
		var dir := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
		if tool == Tool.BUILD and _ghost:
			_ghost_yaw += deg_to_rad(15.0) * dir
		else:
			set_tool(wrapi(tool - dir, 0, 5))
	elif event.is_action_pressed("cancel") and tool == Tool.BUILD and (_ghost or _moving):
		cancel_build()
		Sfx.play("whoosh")
	elif event.is_action_pressed("sell"):
		_try_return()
	elif event.is_action_pressed("interact"):
		_primary()


func _primary() -> void:
	var hit := _ray(REACH, Geo.LAYER_WORLD | Geo.LAYER_INTERACT | Geo.LAYER_SURFACE)
	var col: Object = hit.get("collider")
	match tool:
		Tool.HAND:
			if col is Mess and col.kind == "trash":
				var to := camera().global_position + Vector3(0, -0.6, 0)
				col.pick_up(to)
				_use_anim = 1.0
				Sfx.play("pop")
			elif col is Furniture:
				if col.junk:
					world.remove_junk(col)
				else:
					_start_move(col)
		Tool.PAINT:
			if col is Surface and col.kind == "wall":
				_apply_finish(col, wall_finish)
		Tool.FLOOR:
			if col is Surface and col.kind == "floor":
				_apply_finish(col, floor_finish)
		Tool.BUILD:
			_place()


func _apply_finish(s: Surface, id: String) -> void:
	var targets := [s]
	if Input.is_key_pressed(KEY_SHIFT) and s.kind == "wall":
		targets = world.room_surfaces(s.room, "wall")
	if world.apply_finish(targets, id):
		_use_anim = 1.0


func _try_return() -> void:
	if tool == Tool.BUILD and _ghost:
		return
	var hit := _ray(REACH, Geo.LAYER_WORLD)
	var col: Object = hit.get("collider")
	if col is Furniture and not col.junk:
		world.return_furniture(col)


func _start_move(f: Furniture) -> void:
	cancel_build()
	_moving = f
	f.visible = false
	f.collision_layer = 0
	_ghost_yaw = f.global_rotation.y
	build_item = f.item_id
	_make_ghost(f.item_id)
	tool = Tool.BUILD
	_show_held()
	tool_changed.emit(tool)
	selection_changed.emit()
	Sfx.play("whoosh")


func _place() -> void:
	if not _ghost or not _ghost.visible:
		return
	if not _ghost_valid:
		Sfx.play("error")
		Game.notify("Can't place that here", Color(1, 0.6, 0.5))
		return
	var xf := _ghost.global_transform
	if _moving:
		world.move_furniture(_moving, xf)
		_moving = null
		cancel_build()
	else:
		world.buy_and_place(build_item, xf)


# --- Per-frame ------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	_animate_held(delta)
	if not Game.playing or Game.is_ui_open():
		if _ghost:
			_ghost.visible = false
		_set_hint("")
		return
	match tool:
		Tool.HAND:
			_hand_hint()
		Tool.CLEAN:
			_clean(delta)
		Tool.PAINT:
			_paint_hint("wall")
		Tool.FLOOR:
			_paint_hint("floor")
		Tool.BUILD:
			_update_ghost()


func _hand_hint() -> void:
	var col: Object = _ray(REACH, Geo.LAYER_WORLD | Geo.LAYER_INTERACT).get("collider")
	if col is Mess:
		if col.kind == "trash":
			_set_hint("[LMB] Pick up %s  +$%d" % [col.display_name, col.reward()])
		else:
			_set_hint("Use the Sponge [2] to clean this")
	elif col is Furniture:
		if col.junk:
			_set_hint("[LMB] Throw away %s  +$%d" % [col.display_name(), col.data()["value"]])
		else:
			_set_hint(
				"[LMB] Move %s    [X] Return  +$%d" % [col.display_name(), col.data()["price"]]
			)
	else:
		_set_hint("")


func _clean(delta: float) -> void:
	var col: Object = _ray(REACH, Geo.LAYER_WORLD | Geo.LAYER_INTERACT).get("collider")
	if not (col is Mess) or col.kind == "trash":
		_set_hint("Use the Hand [1] to pick up trash" if col is Mess else "")
		return
	var verb := "scrub" if col.kind == "dirt" else "pull the weed"
	if Input.is_action_pressed("interact"):
		var done: bool = col.scrub(delta * SCRUB_SPEED[col.kind])
		_use_anim = minf(_use_anim + delta * 6.0, 1.0)
		_scrub_sound_t -= delta
		if _scrub_sound_t <= 0.0:
			_scrub_sound_t = 0.16
			Sfx.play("scrub" if col.kind == "dirt" else "rip", 0.15)
		if done:
			world.sparkle(col.global_position, col.kind == "weed")
		_set_hint("Cleaning... %d%%" % int((1.0 - clampf(col.health, 0, 1)) * 100))
	else:
		_set_hint("[Hold LMB] %s  +$%d" % [verb.capitalize(), col.reward()])


func _paint_hint(kind: String) -> void:
	var col: Object = _ray(REACH + 1.5, Geo.LAYER_WORLD | Geo.LAYER_SURFACE).get("collider")
	var id := wall_finish if kind == "wall" else floor_finish
	var data := Catalog.finish(kind, id)
	if col is Surface and col.kind == kind:
		if col.finish_id == id:
			_set_hint("Already %s    [Q] Choose another" % data["name"])
		elif kind == "wall":
			var room_cost := 0
			for s in world.room_surfaces(col.room, "wall"):
				if s.finish_id != id:
					room_cost += data["price"]
			_set_hint(
				(
					"[LMB] %s  $%d    [Shift+LMB] Whole room  $%d"
					% [data["name"], data["price"], room_cost]
				)
			)
		else:
			_set_hint("[LMB] Lay %s  $%d" % [data["name"], data["price"]])
	else:
		_set_hint("%s selected    [Q] Choose" % data["name"])


func _update_ghost() -> void:
	if not _ghost:
		_set_hint("")
		return
	var hit := _ray(BUILD_REACH, Geo.LAYER_WORLD | Geo.LAYER_SURFACE)
	if hit.is_empty():
		_ghost.visible = false
		_set_hint("Aim at the floor to place")
		return
	_ghost.visible = true
	var n: Vector3 = hit["normal"]
	var pos: Vector3 = hit["position"]
	var valid := true
	var basis := Basis(Vector3.UP, _ghost_yaw)
	if _ghost.place_mode() == "wall":
		var flat := Vector3(n.x, 0, n.z)
		valid = absf(n.y) < 0.3 and flat.length() > 0.1 and not (hit["collider"] is Furniture)
		if flat.length() > 0.1:
			basis = Basis.looking_at(-flat.normalized(), Vector3.UP)
		pos += flat.normalized() * 0.01 if flat.length() > 0.1 else Vector3.ZERO
	else:
		valid = n.y > 0.7
	_ghost.global_transform = Transform3D(basis, pos)
	if valid:
		valid = not _overlaps(_ghost)
	if valid and _ghost.place_mode() == "floor" and _ghost.box_size.y > 0.06:
		valid = pos.y < 1.6
	_ghost_valid = valid
	_ghost.set_ghost_valid(valid)
	var data := Catalog.item(build_item)
	if _moving:
		_set_hint("[LMB] Place    [R] Rotate    [RMB] Cancel")
	else:
		_set_hint("[LMB] Buy %s  $%d    [R] Rotate    [RMB] Cancel" % [data["name"], data["price"]])


func _overlaps(f: Furniture) -> bool:
	if f.box_size.y < 0.06:
		return false  # rugs lie flat under other furniture
	var margin := Vector3(0.08, 0.06, 0.08)
	_query_shape.size = (f.box_size - margin).max(Vector3.ONE * 0.02)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _query_shape
	var lift := Vector3(0, 0.03, 0)
	if f.place_mode() == "wall":
		lift = Vector3(0, 0, 0.03)
	q.transform = f.global_transform * Transform3D(Basis(), f.box_center + lift)
	q.collision_mask = Geo.LAYER_WORLD
	if _moving:
		q.exclude = [_moving.get_rid()]
	return not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _ray(dist: float, mask: int) -> Dictionary:
	var cam := camera()
	var from := cam.global_position
	var to := from - cam.global_basis.z * dist
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	return get_world_3d().direct_space_state.intersect_ray(q)


func _set_hint(text: String) -> void:
	if text != _hint:
		_hint = text
		hint_changed.emit(text)


# --- Held tool visuals ------------------------------------------------------------


func _build_held_items() -> void:
	var sponge := Node3D.new()
	var body := Geo.mesh_box(Vector3(0.12, 0.06, 0.08), Mats.color(Color(1.0, 0.85, 0.25), 1.0))
	sponge.add_child(body)
	var scour := Geo.mesh_box(Vector3(0.12, 0.02, 0.08), Mats.color(Color(0.25, 0.6, 0.3), 1.0))
	scour.position.y = -0.04
	sponge.add_child(scour)
	_held_items[Tool.CLEAN] = sponge

	var roller := Node3D.new()
	var handle := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.012
	cm.bottom_radius = 0.012
	cm.height = 0.28
	handle.mesh = cm
	handle.material_override = Mats.color(Color(0.2, 0.2, 0.22), 0.4)
	handle.rotation.x = 0.5
	handle.position = Vector3(0, -0.1, 0.05)
	roller.add_child(handle)
	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.04
	dm.bottom_radius = 0.04
	dm.height = 0.2
	drum.mesh = dm
	drum.name = "Drum"
	drum.rotation.z = PI / 2
	drum.position = Vector3(0, 0.04, -0.02)
	roller.add_child(drum)
	_held_items[Tool.PAINT] = roller

	var tiles := Node3D.new()
	for i in 3:
		var t := Geo.mesh_box(Vector3(0.18, 0.015, 0.18), Mats.color(Color(0.85, 0.75, 0.6), 0.5))
		t.position = Vector3(0.01 * i, 0.017 * i, 0)
		t.name = "Tile%d" % i
		tiles.add_child(t)
	_held_items[Tool.FLOOR] = tiles

	var hammer := Node3D.new()
	var h_handle := Geo.mesh_box(
		Vector3(0.025, 0.25, 0.025), Mats.color(Color(0.55, 0.36, 0.2), 0.7)
	)
	hammer.add_child(h_handle)
	var h_head := Geo.mesh_box(
		Vector3(0.12, 0.04, 0.04), Mats.color(Color(0.5, 0.52, 0.55), 0.3, 0.8)
	)
	h_head.position.y = 0.12
	hammer.add_child(h_head)
	_held_items[Tool.BUILD] = hammer

	var glove := Node3D.new()
	var palm := Geo.mesh_box(Vector3(0.09, 0.03, 0.11), Mats.color(Color(0.95, 0.55, 0.2), 0.9))
	glove.add_child(palm)
	for i in 4:
		var finger := Geo.mesh_box(Vector3(0.018, 0.022, 0.06), palm.material_override)
		finger.position = Vector3(-0.033 + i * 0.022, 0, -0.08)
		glove.add_child(finger)
	var thumb := Geo.mesh_box(Vector3(0.02, 0.022, 0.05), palm.material_override)
	thumb.position = Vector3(0.055, 0, -0.02)
	thumb.rotation.y = -0.6
	glove.add_child(thumb)
	_held_items[Tool.HAND] = glove

	for k in _held_items:
		var n: Node3D = _held_items[k]
		n.visible = false
		n.scale = Vector3.ONE * 0.7
		for mi in Geo.mesh_instances(n):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.layers = 1
		add_child(n)
	_update_roller_color()


func _show_held() -> void:
	for k in _held_items:
		_held_items[k].visible = k == tool
	_held = _held_items.get(tool)
	if tool == Tool.FLOOR:
		_update_tile_color()


func _update_roller_color() -> void:
	var roller: Node3D = _held_items.get(Tool.PAINT)
	if not roller:
		return
	var drum: MeshInstance3D = roller.get_node("Drum")
	var data := Catalog.finish("wall", wall_finish)
	var m := StandardMaterial3D.new()
	m.albedo_color = data.get("color", Color.WHITE)
	if data.has("tex"):
		m.albedo_texture = Mats.tex(data["tex"])
	drum.material_override = m


func _update_tile_color() -> void:
	var tiles: Node3D = _held_items.get(Tool.FLOOR)
	var data := Catalog.finish("floor", floor_finish)
	var m := StandardMaterial3D.new()
	m.albedo_texture = Mats.tex(data["tex"])
	m.albedo_color = data.get("tint", Color.WHITE)
	m.uv1_scale = Vector3(0.3, 0.3, 1)
	for c in tiles.get_children():
		c.material_override = m


func _animate_held(delta: float) -> void:
	if not _held:
		return
	_use_anim = maxf(_use_anim - delta * 3.0, 0.0)
	var t := Time.get_ticks_msec() / 1000.0
	var base := Vector3(0.3, -0.26, -0.5)
	var swing := sin(_use_anim * PI) * 0.06
	_held.position = base + Vector3(0, sin(t * 1.7) * 0.004 + swing, -swing)
	_held.rotation = Vector3(-0.25 - swing * 4.0, -0.35, 0.0)
	if tool == Tool.FLOOR and _held.visible:
		_held.rotation.x = 0.15
	if tool == Tool.HAND:
		_held.rotation = Vector3(0.35 - swing * 3.0, -0.5, -0.4)
