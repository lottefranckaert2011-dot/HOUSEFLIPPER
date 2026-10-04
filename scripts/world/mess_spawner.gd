class_name MessSpawner
## Creates the mess for a house deterministically from a seed, so removed
## pieces can be remembered in the save file by key.

const T := HouseLayout.WALL_T

const TRASH_PER_ROOM := {
	"living": 10,
	"kitchen": 7,
	"bathroom": 2,
	"bedroom": 4,
	"utility": 2,
	"backyard": 6,
	"frontyard": 3
}
const FLOOR_DIRT := {"living": 5, "kitchen": 4, "bathroom": 3, "bedroom": 3, "utility": 2}
const WALL_DIRT := {"living": 4, "kitchen": 3, "bathroom": 3, "bedroom": 2, "utility": 1}
const WEEDS := 14

## Junk furniture: id, position, yaw in degrees.
const JUNK_LAYOUT := [
	["junk_sofa", Vector3(0.75, 0, 3.0), 90.0],
	["junk_table", Vector3(4.6, 0, 3.2), 0.0],
	["junk_chair", Vector3(4.6, 0, 2.3), 0.0],
	["junk_chair", Vector3(4.6, 0, 4.1), 180.0],
	["junk_tv", Vector3(6.8, 0, 5.55), 180.0],
	["junk_fridge", Vector3(13.4, 0, 5.4), 180.0],
	["junk_table", Vector3(11.2, 0, 3.4), 90.0],
	["junk_chair", Vector3(12.1, 0, 3.4), -90.0],
	["junk_toilet", Vector3(10.4, 0, 9.4), 180.0],
	["junk_bed", Vector3(1.3, 0, 8.5), 90.0],
	["junk_dresser", Vector3(5.6, 0, 9.65), 180.0],
	["junk_washer", Vector3(13.45, 0, 9.45), 180.0],
]

var rng := RandomNumberGenerator.new()
## key -> [kind, room] for every piece of mess this house started with.
var layout := {}
var _occupied: Array[Vector3] = []


func _init(seed_value: int) -> void:
	rng.seed = seed_value


## Returns {"mess": [Mess...], "junk": [Furniture...]}; skips keys in `removed`.
func spawn(removed: Array) -> Dictionary:
	var mess := []
	var junk := []
	for i in JUNK_LAYOUT.size():
		var j: Array = JUNK_LAYOUT[i]
		_occupied.append(j[1])
		var key := "junk_%d" % i
		if key in removed:
			continue
		var f := Furniture.create(j[0])
		f.key = key
		f.position = j[1]
		f.rotation_degrees.y = j[2]
		junk.append(f)

	var n := 0
	for room in TRASH_PER_ROOM:
		for i in TRASH_PER_ROOM[room]:
			var key := "trash_%d" % n
			n += 1
			var pos := _random_spot(room)
			var m := _make_trash()
			# Always consume the same random numbers so keys stay stable.
			var yaw := rng.randf() * TAU
			layout[key] = ["trash", room]
			if key in removed:
				m.free()
				continue
			m.key = key
			m.room = room
			m.position = pos
			m.rotation.y = yaw
			mess.append(m)

	n = 0
	for room in FLOOR_DIRT:
		for i in FLOOR_DIRT[room]:
			var key := "dirt_%d" % n
			n += 1
			var pos := _random_spot(room, 0.5, false)
			var size := rng.randf_range(0.8, 1.4)
			var yaw := rng.randf() * TAU
			layout[key] = ["dirt", room]
			if key in removed:
				continue
			var m := _make_dirt(size, "dirt_floor")
			m.key = key
			m.room = room
			m.position = Vector3(pos.x, 0.012, pos.z)
			m.rotation = Vector3(-PI / 2, 0, 0)
			m.rotate_y(yaw)
			mess.append(m)
	for room in WALL_DIRT:
		for i in WALL_DIRT[room]:
			var key := "dirt_%d" % n
			n += 1
			var placement := _random_wall_spot(room)
			var size := rng.randf_range(0.6, 1.1)
			var spin := rng.randf() * TAU
			if not placement.is_empty():
				layout[key] = ["dirt", room]
			if key in removed or placement.is_empty():
				continue
			var m := _make_dirt(size, "dirt_wall")
			m.key = key
			m.room = room
			m.position = placement["pos"]
			m.basis = Basis.looking_at(-placement["normal"], Vector3.UP)
			m.rotate_object_local(Vector3.BACK, spin)
			mess.append(m)

	for i in WEEDS:
		var key := "weed_%d" % i
		var pos := _random_spot("backyard")
		var s := rng.randf_range(2.6, 3.6)
		var yaw := rng.randf() * TAU
		layout[key] = ["weed", "backyard"]
		if key in removed:
			continue
		var m := _make_weed(s)
		m.key = key
		m.room = "backyard"
		m.position = pos
		m.rotation.y = yaw
		mess.append(m)
	return {"mess": mess, "junk": junk}


func _random_spot(room: String, margin := 0.6, avoid := true) -> Vector3:
	for attempt in 40:
		var p := Vector3.ZERO
		if HouseLayout.ROOMS.has(room):
			var r: Array = HouseLayout.ROOMS[room]["rect"]
			p = Vector3(
				rng.randf_range(r[0] + margin, r[2] - margin),
				0,
				rng.randf_range(r[1] + margin, r[3] - margin)
			)
		elif room == "backyard":
			p = Vector3(
				rng.randf_range(HouseLayout.YARD_LEFT + 0.8, HouseLayout.YARD_RIGHT - 0.8),
				0,
				rng.randf_range(HouseLayout.DEPTH + 0.8, HouseLayout.YARD_BACK - 0.8)
			)
			var pool: Array = HouseLayout.POOL
			var patio: Array = HouseLayout.PATIO
			if (
				p.x > pool[0] - 1.3
				and p.x < pool[2] + 1.3
				and p.z > pool[1] - 1.3
				and p.z < pool[3] + 1.3
			):
				continue
			if p.x > patio[0] - 0.3 and p.x < patio[2] + 0.3 and p.z < patio[3] + 0.3:
				continue
		else:
			p = Vector3(rng.randf_range(-3.0, 17.0), 0, rng.randf_range(-9.0, -1.6))
		if avoid:
			var ok := true
			for o in _occupied:
				if Vector2(o.x, o.z).distance_to(Vector2(p.x, p.z)) < 1.1:
					ok = false
					break
			if not ok:
				continue
			_occupied.append(p)
		return p
	return Vector3.ZERO


func _random_wall_spot(room: String) -> Dictionary:
	var r: Array = HouseLayout.ROOMS[room]["rect"]
	for attempt in 30:
		var side: String = ["s", "n", "w", "e"][rng.randi() % 4]
		var along_x := side == "s" or side == "n"
		var axis := "x" if along_x else "z"
		var at: float = {"s": r[1], "n": r[3], "w": r[0], "e": r[2]}[side]
		var u0: float = (r[0] if along_x else r[1]) + 0.7
		var u1: float = (r[2] if along_x else r[3]) - 0.7
		var u := rng.randf_range(u0, u1)
		var v := rng.randf_range(0.7, 2.0)
		var blocked := false
		for o in HouseLayout.openings_on(axis, at):
			if u > o["from"] - 0.6 and u < o["to"] + 0.6:
				blocked = true
		if blocked:
			continue
		var off := T / 2 + 0.012
		var normal: Vector3 = {
			"s": Vector3.BACK, "n": Vector3.FORWARD, "w": Vector3.RIGHT, "e": Vector3.LEFT
		}[side]
		var pos := Vector3(u, v, at) if along_x else Vector3(at, v, u)
		pos += normal * off
		return {"pos": pos, "normal": normal}
	return {}


# --- Visuals --------------------------------------------------------------------


func _make_trash() -> Mess:
	var m := Mess.new()
	var kind := rng.randi() % 6
	var root := Node3D.new()
	var nm := ""
	var size := Vector3.ONE * 0.3
	var off := Vector3.ZERO
	match kind:
		0:
			nm = "Pizza Box"
			var box := Geo.mesh_box(Vector3(0.44, 0.05, 0.44), Mats.color(Color(0.86, 0.66, 0.45)))
			box.position.y = 0.025
			root.add_child(box)
			var top := MeshInstance3D.new()
			var q := PlaneMesh.new()
			q.size = Vector2(0.43, 0.43)
			top.mesh = q
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = Mats.tex("pizza_box")
			top.material_override = mat
			top.position.y = 0.052
			root.add_child(top)
			size = Vector3(0.46, 0.1, 0.46)
			off.y = 0.05
		1:
			nm = "Garbage Bag"
			var bag := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.28
			sm.height = 0.5
			bag.mesh = sm
			bag.material_override = Mats.color(Color(0.2, 0.22, 0.24), 0.35)
			bag.position.y = 0.22
			bag.scale = Vector3(1.0, 0.85, 0.9)
			root.add_child(bag)
			var knot := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = 0.07
			cm.height = 0.12
			knot.mesh = cm
			knot.material_override = bag.material_override
			knot.position.y = 0.46
			root.add_child(knot)
			size = Vector3(0.56, 0.5, 0.5)
			off.y = 0.25
		2:
			nm = "Bottle"
			var b := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.025
			cm.bottom_radius = 0.045
			cm.height = 0.3
			b.mesh = cm
			var col: Color = [Color(0.2, 0.5, 0.25, 0.85), Color(0.45, 0.28, 0.12, 0.85)][
				rng.randi() % 2
			]
			b.material_override = Mats.color(col, 0.1)
			b.rotation.z = PI / 2
			b.position.y = 0.045
			root.add_child(b)
			size = Vector3(0.36, 0.14, 0.14)
			off.y = 0.06
		3:
			nm = "Soda Can"
			var c := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.034
			cm.bottom_radius = 0.034
			cm.height = 0.12
			c.mesh = cm
			var col: Color = [
				Color(0.85, 0.15, 0.15), Color(0.15, 0.4, 0.85), Color(0.75, 0.75, 0.78)
			][rng.randi() % 3]
			c.material_override = Mats.color(col, 0.3, 0.6)
			c.position.y = 0.06
			root.add_child(c)
			size = Vector3(0.18, 0.16, 0.18)
			off.y = 0.07
		4:
			nm = "Cardboard Box"
			var model := Geo.load_model(
				Catalog.FURNITURE_DIR % ["cardboardBoxOpen", "cardboardBoxClosed"][rng.randi() % 2],
				1.8
			)
			root.add_child(model)
			size = Vector3(0.5, 0.52, 0.42)
			off.y = 0.26
		_:
			nm = "Crumpled Paper"
			for i in 3:
				var p := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.06
				sm.height = 0.1
				sm.radial_segments = 8
				sm.rings = 4
				p.mesh = sm
				p.material_override = Mats.color(Color(0.92, 0.92, 0.88), 1.0)
				p.position = Vector3(
					rng.randf_range(-0.12, 0.12), 0.05, rng.randf_range(-0.12, 0.12)
				)
				root.add_child(p)
			size = Vector3(0.4, 0.14, 0.4)
			off.y = 0.06
	m.setup("trash", "", nm, root, size, off)
	return m


func _make_dirt(size: float, tex: String) -> Mess:
	var m := Mess.new()
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Mats.tex(tex)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.95)
	mat.roughness = 1.0
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.setup(
		"dirt",
		"",
		"Grime" if tex == "dirt_wall" else "Dirt Stain",
		mi,
		Vector3(size * 0.7, size * 0.7, 0.04)
	)
	return m


func _make_weed(s: float) -> Mess:
	var m := Mess.new()
	var holder := Node3D.new()
	var model := Geo.load_model(
		(
			"res://assets/models/nature/%s.glb"
			% ["grass_large", "grass", "plant_bushSmall"][rng.randi() % 3]
		),
		s
	)
	holder.add_child(model)
	for mi: MeshInstance3D in Geo.mesh_instances(model):
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			if src is StandardMaterial3D:
				var mat: StandardMaterial3D = src.duplicate()
				mat.albedo_color = mat.albedo_color * Color(0.75, 0.85, 0.45)
				mi.set_surface_override_material(i, mat)
	m.setup("weed", "", "Weed", holder, Vector3(0.9, 0.8, 0.9), Vector3(0, 0.4, 0))
	return m
