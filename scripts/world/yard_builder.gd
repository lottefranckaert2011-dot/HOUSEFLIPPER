class_name YardBuilder
extends Node3D
## Builds everything outside the house: lawn, pool, patio, paths, street,
## fences, neighbouring houses, trees and the invisible play-area boundary.

const NATURE := "res://assets/models/nature/%s.glb"
const SUBURB := "res://assets/models/suburban/%s.glb"
const GROUND_Y := -0.02


func build() -> void:
	_build_ground()
	_build_pool()
	_build_paving()
	_build_fences()
	_build_neighbourhood()
	_build_bounds()


func _build_ground() -> void:
	var grass := Mats.triplanar("grass", 3.0)
	var p: Array = HouseLayout.POOL
	var big := [-70.0, -60.0, 80.0, 90.0]
	# Four pieces around the pool hole.
	var pieces := [
		[big[0], big[1], p[0], big[3]],
		[p[2], big[1], big[2], big[3]],
		[p[0], big[1], p[2], p[1]],
		[p[0], p[3], p[2], big[3]],
	]
	for r in pieces:
		var size := Vector3(r[2] - r[0], 0.5, r[3] - r[1])
		var pos := Vector3((r[0] + r[2]) / 2, GROUND_Y - 0.25, (r[1] + r[3]) / 2)
		Geo.static_box(self, size, pos, grass)


func _build_pool() -> void:
	var p: Array = HouseLayout.POOL
	var depth := 1.4
	var tile := Mats.triplanar("wall_tiles_white", 1.0, Color(0.75, 0.9, 1.0), 0.3)
	var concrete := Mats.triplanar("concrete", 2.0)
	var w: float = p[2] - p[0]
	var d: float = p[3] - p[1]
	var c := Vector3((p[0] + p[2]) / 2, 0, (p[1] + p[3]) / 2)
	# Basin walls and floor
	Geo.static_box(self, Vector3(w, 0.2, d), c + Vector3(0, -depth - 0.1, 0), tile)
	for s in [-1, 1]:
		Geo.static_box(
			self, Vector3(w, depth, 0.2), c + Vector3(0, -depth / 2, s * (d / 2 + 0.1)), tile
		)
		Geo.static_box(
			self, Vector3(0.2, depth, d), c + Vector3(s * (w / 2 + 0.1), -depth / 2, 0), tile
		)
	# Coping around the edge
	var cw := 0.9
	for s in [-1, 1]:
		Geo.static_box(
			self,
			Vector3(w + cw * 2, 0.1, cw),
			c + Vector3(0, -0.02, s * (d / 2 + cw / 2)),
			concrete
		)
		Geo.static_box(
			self, Vector3(cw, 0.1, d), c + Vector3(s * (w / 2 + cw / 2), -0.02, 0), concrete
		)
	# Water
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, d)
	water.mesh = pm
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/water.gdshader")
	water.material_override = sm
	water.position = c + Vector3(0, -0.18, 0)
	add_child(water)
	# Keep the player out of the water.
	var blocker := Geo.static_box(self, Vector3(w, 2.0, d), c + Vector3(0, 1.0, 0), null)
	blocker.name = "PoolBlocker"
	# Loungers by the pool are decoration; buyers expect more.
	_model(NATURE % "tree_palmDetailedTall", 3.6, Vector3(p[2] + 2.0, 0, p[3] + 2.0), 30)
	_model(NATURE % "tree_palmTall", 3.4, Vector3(p[0] - 2.2, 0, p[3] + 1.5), 120)


func _build_paving() -> void:
	var concrete := Mats.triplanar("concrete", 2.5)
	var deck := Mats.triplanar("wood_deck", 2.0)
	var asphalt := Mats.color(Color(0.22, 0.22, 0.24), 0.95)
	var pt: Array = HouseLayout.PATIO
	_slab(
		Vector3(pt[2] - pt[0], 0.08, pt[3] - pt[1]),
		Vector3((pt[0] + pt[2]) / 2, 0.0, (pt[1] + pt[3]) / 2),
		deck
	)
	# Front path and driveway
	_slab(Vector3(1.6, 0.06, 9.9), Vector3(3.55, -0.01, -5.05), concrete)
	_slab(Vector3(4.0, 0.06, 10.0), Vector3(11.5, -0.01, -5.1), concrete)
	# Path from patio to pool
	_slab(Vector3(1.4, 0.06, 2.2), Vector3(9.3, -0.01, 15.0), concrete)
	# Sidewalk and street
	_slab(Vector3(160, 0.08, 2.0), Vector3(5, -0.0, -11.0), concrete)
	_slab(Vector3(160, 0.04, 10.0), Vector3(5, -0.03, -17.0), asphalt)
	var line := Mats.color(Color(0.95, 0.85, 0.3), 0.9)
	for i in range(-12, 14):
		var dash := Geo.mesh_box(Vector3(2.0, 0.01, 0.15), line)
		dash.position = Vector3(i * 5.0, 0.0, -17.0)
		add_child(dash)


func _slab(size: Vector3, center: Vector3, mat: Material) -> void:
	var mi := Geo.mesh_box(size, mat)
	mi.position = center + Vector3(0, -size.y / 2 + 0.01, 0)
	add_child(mi)


func _build_fences() -> void:
	var left := HouseLayout.YARD_LEFT
	var right := HouseLayout.YARD_RIGHT
	var back := HouseLayout.YARD_BACK
	var depth := HouseLayout.DEPTH
	# Back and sides of the backyard
	_fence_line(Vector3(left, 0, back), Vector3(right, 0, back))
	_fence_line(Vector3(left, 0, depth), Vector3(left, 0, back))
	_fence_line(Vector3(right, 0, depth), Vector3(right, 0, back))
	# Short fences joining the house corners to the side fences
	_fence_line(Vector3(left, 0, depth), Vector3(-0.1, 0, depth))
	_fence_line(Vector3(HouseLayout.WIDTH + 0.1, 0, depth), Vector3(right, 0, depth))
	# Hedges in front of the house
	for x in [0.8, 1.9, 5.8, 6.9, 8.6]:
		_model(NATURE % "plant_bushDetailed", 2.2, Vector3(x, 0, -0.9), randf() * 360)


func _fence_line(a: Vector3, b: Vector3) -> void:
	var seg := 2.9
	var length := a.distance_to(b)
	var n := maxi(1, int(ceil(length / seg)))
	var dir := (b - a).normalized()
	var yaw := atan2(dir.x, dir.z) + PI / 2
	for i in n:
		var p := a + dir * (seg * (i + 0.5) * length / (seg * n))
		var m := Geo.load_model(NATURE % "fence_planks", 3.0)
		m.scale.x = 3.0 * length / (seg * n) / 0.97
		m.position = p
		m.rotation.y = yaw
		add_child(m)
	var body := StaticBody3D.new()
	body.collision_layer = Geo.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 1.6, 0.2)
	cs.shape = box
	body.add_child(cs)
	body.position = (a + b) / 2 + Vector3(0, 0.8, 0)
	body.rotation.y = yaw
	add_child(body)


func _build_neighbourhood() -> void:
	# Neighbouring houses
	_model(SUBURB % "building-type-c", 9.0, Vector3(-17, 0, 5), 90)
	_model(SUBURB % "building-type-f", 9.0, Vector3(31, 0, 5), -90)
	_model(SUBURB % "building-type-a", 9.0, Vector3(-4, 0, -30), 0)
	_model(SUBURB % "building-type-k", 9.0, Vector3(12, 0, -30), 0)
	_model(SUBURB % "building-type-p", 9.0, Vector3(28, 0, -30), 0)
	_model(SUBURB % "building-type-c", 9.0, Vector3(6, 0, 38), 180)
	# Trees
	var trees := [
		["tree_oak", Vector3(-8, 0, -6)],
		["tree_default", Vector3(22, 0, -5)],
		["tree_detailed", Vector3(-8, 0, 16)],
		["tree_oak", Vector3(23, 0, 20)],
		["tree_pineRoundA", Vector3(-9, 0, 28)],
		["tree_default", Vector3(15, 0, 30)],
		["tree_detailed", Vector3(0, 0, 31)],
		["tree_oak", Vector3(-20, 0, -20)],
		["tree_default", Vector3(36, 0, -14)],
		["tree_pineRoundA", Vector3(25, 0, 32)],
	]
	for t in trees:
		_model(NATURE % t[0], 4.5 + randf() * 1.0, t[1], randf() * 360)
	for x in [-14, -2, 10, 22, 34]:
		_model(NATURE % "tree_small", 4.0, Vector3(x, 0, -21), randf() * 360)


func _build_bounds() -> void:
	var rect := [-9.0, -15.5, 23.0, 29.0]
	var h := 4.0
	var w: float = rect[2] - rect[0]
	var d: float = rect[3] - rect[1]
	Geo.static_box(self, Vector3(w, h, 0.5), Vector3((rect[0] + rect[2]) / 2, h / 2, rect[1]), null)
	Geo.static_box(self, Vector3(w, h, 0.5), Vector3((rect[0] + rect[2]) / 2, h / 2, rect[3]), null)
	Geo.static_box(self, Vector3(0.5, h, d), Vector3(rect[0], h / 2, (rect[1] + rect[3]) / 2), null)
	Geo.static_box(self, Vector3(0.5, h, d), Vector3(rect[2], h / 2, (rect[1] + rect[3]) / 2), null)


func _model(path: String, scale: float, pos: Vector3, yaw_deg: float) -> Node3D:
	var m := Geo.load_model(path, scale)
	m.position = pos
	m.rotation_degrees.y = yaw_deg
	add_child(m)
	return m
