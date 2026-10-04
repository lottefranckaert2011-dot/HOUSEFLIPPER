class_name HouseBuilder
extends Node3D
## Builds the house geometry from HouseLayout: walls, paintable surfaces,
## floors, ceilings, door and window frames, roof and lights.

const H := HouseLayout.WALL_H
const T := HouseLayout.WALL_T
const EPS := 0.004

## key ("room:side") -> Surface
var surfaces := {}

var _wall_mat := Mats.color(Color(0.93, 0.92, 0.89))
var _trim_mat := Mats.color(Color(0.97, 0.96, 0.93), 0.5)
var _ceiling_mat := Mats.color(Color(0.96, 0.96, 0.95), 0.95)


func build() -> void:
	_build_slab()
	_build_walls()
	for id in HouseLayout.ROOMS:
		_build_room(id)
	_build_exterior()
	_build_openings()
	_build_roof()


func _build_slab() -> void:
	var w := HouseLayout.WIDTH + T
	var d := HouseLayout.DEPTH + T
	Geo.static_box(
		self,
		Vector3(w, 0.3, d),
		Vector3(HouseLayout.WIDTH / 2, -0.15, HouseLayout.DEPTH / 2),
		Mats.textured("floor_wood", 2.4, Color(0.75, 0.65, 0.55))
	)


func _build_walls() -> void:
	for wall in HouseLayout.WALLS:
		var openings := HouseLayout.openings_on(wall["axis"], wall["at"])
		var u0: float = wall["from"] - T / 2
		var u1: float = wall["to"] + T / 2
		for r in Geo.wall_rects(u0, u1, H, openings):
			var length: float = r[1] - r[0]
			var height: float = r[3] - r[2]
			var mid_u: float = (r[0] + r[1]) / 2
			var mid_v: float = (r[2] + r[3]) / 2
			if wall["axis"] == "x":
				Geo.static_box(
					self, Vector3(length, height, T), Vector3(mid_u, mid_v, wall["at"]), _wall_mat
				)
			else:
				Geo.static_box(
					self, Vector3(T, height, length), Vector3(wall["at"], mid_v, mid_u), _wall_mat
				)


## Surface point for a wall side: u along the wall, v height.
func _side_point(side: String, rect: Array, u: float, v: float, offset: float) -> Vector3:
	match side:
		"s":
			return Vector3(u, v, rect[1] + offset)
		"n":
			return Vector3(u, v, rect[3] - offset)
		"w":
			return Vector3(rect[0] + offset, v, u)
		_:
			return Vector3(rect[2] - offset, v, u)


func _build_room(id: String) -> void:
	var room: Dictionary = HouseLayout.ROOMS[id]
	var rect: Array = room["rect"]
	var normals := {"s": Vector3.BACK, "n": Vector3.FORWARD, "w": Vector3.RIGHT, "e": Vector3.LEFT}
	for side in ["s", "n", "w", "e"]:
		var along_x: bool = side == "s" or side == "n"
		var axis := "x" if along_x else "z"
		var at: float
		match side:
			"s":
				at = rect[1]
			"n":
				at = rect[3]
			"w":
				at = rect[0]
			_:
				at = rect[2]
		var u0: float = (rect[0] if along_x else rect[1]) + T / 2
		var u1: float = (rect[2] if along_x else rect[3]) - T / 2
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var area := 0.0
		for r in Geo.wall_rects(u0, u1, H, HouseLayout.openings_on(axis, at)):
			var pts := [
				_side_point(side, rect, r[0], r[2], T / 2 + EPS),
				_side_point(side, rect, r[1], r[2], T / 2 + EPS),
				_side_point(side, rect, r[1], r[3], T / 2 + EPS),
				_side_point(side, rect, r[0], r[3], T / 2 + EPS),
			]
			# Mirror U on two sides so textures are not flipped when viewed from inside.
			var flip: bool = side == "n" or side == "w"
			var ua: float = -r[0] if flip else r[0]
			var ub: float = -r[1] if flip else r[1]
			var uvs := [
				Vector2(ua, -r[2]), Vector2(ub, -r[2]), Vector2(ub, -r[3]), Vector2(ua, -r[3])
			]
			Geo.quad(st, pts, uvs, normals[side])
			area += (r[1] - r[0]) * (r[3] - r[2])
		var s := Surface.new()
		s.name = "%s_%s" % [id, side]
		s.area = area
		s.setup("wall", id, side, st.commit(), room["wall"])
		add_child(s)
		surfaces[s.key] = s

	# Floor
	var x0: float = rect[0] + T / 2
	var x1: float = rect[2] - T / 2
	var z0: float = rect[1] + T / 2
	var z1: float = rect[3] - T / 2
	var fst := SurfaceTool.new()
	fst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fp := [
		Vector3(x0, EPS, z0), Vector3(x1, EPS, z0), Vector3(x1, EPS, z1), Vector3(x0, EPS, z1)
	]
	Geo.quad(
		fst, fp, [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)], Vector3.UP
	)
	var floor_s := Surface.new()
	floor_s.name = "%s_floor" % id
	floor_s.area = (x1 - x0) * (z1 - z0)
	floor_s.setup("floor", id, "floor", fst.commit(), room["floor"])
	add_child(floor_s)
	surfaces[floor_s.key] = floor_s

	# Ceiling
	var cst := SurfaceTool.new()
	cst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cp := [
		Vector3(x0, H - EPS, z0),
		Vector3(x1, H - EPS, z0),
		Vector3(x1, H - EPS, z1),
		Vector3(x0, H - EPS, z1)
	]
	Geo.quad(cst, cp, [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3.DOWN)
	var ceil_mi := MeshInstance3D.new()
	ceil_mi.mesh = cst.commit()
	ceil_mi.material_override = _ceiling_mat
	add_child(ceil_mi)

	# Ceiling lamp and light
	var cx := (x0 + x1) / 2
	var cz := (z0 + z1) / 2
	var lamp := Geo.load_model(Catalog.FURNITURE_DIR % "lampSquareCeiling", 2.0)
	lamp.position = Vector3(cx, H - 0.46, cz)
	add_child(lamp)
	var light := OmniLight3D.new()
	light.position = Vector3(cx, H - 0.6, cz)
	light.light_color = Color(1.0, 0.92, 0.8)
	light.light_energy = 0.9
	light.omni_range = maxf(x1 - x0, z1 - z0) * 0.95
	light.omni_attenuation = 0.6
	add_child(light)


func _build_exterior() -> void:
	var siding := Mats.textured("siding", 2.4)
	var width := HouseLayout.WIDTH
	var depth := HouseLayout.DEPTH
	var o := T / 2 + EPS
	var specs := [
		# axis, at, normal, plane offset sign
		["x", 0.0, Vector3.FORWARD],
		["x", depth, Vector3.BACK],
		["z", 0.0, Vector3.LEFT],
		["z", width, Vector3.RIGHT],
	]
	for spec in specs:
		var axis: String = spec[0]
		var at: float = spec[1]
		var n: Vector3 = spec[2]
		var length := width if axis == "x" else depth
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for r in Geo.wall_rects(
			-T / 2 - EPS, length + T / 2 + EPS, H, HouseLayout.openings_on(axis, at)
		):
			var pts := []
			for c in [[r[0], r[2]], [r[1], r[2]], [r[1], r[3]], [r[0], r[3]]]:
				if axis == "x":
					pts.append(Vector3(c[0], c[1], at + n.z * o))
				else:
					pts.append(Vector3(at + n.x * o, c[1], c[0]))
			var uvs := [
				Vector2(r[0], -r[2]),
				Vector2(r[1], -r[2]),
				Vector2(r[1], -r[3]),
				Vector2(r[0], -r[3])
			]
			Geo.quad(st, pts, uvs, n)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = siding
		add_child(mi)
	# Corner trims
	for c in [Vector2(0, 0), Vector2(width, 0), Vector2(0, depth), Vector2(width, depth)]:
		var trim := Geo.mesh_box(Vector3(T + 0.1, H + 0.05, T + 0.1), _trim_mat)
		trim.position = Vector3(c.x, H / 2, c.y)
		add_child(trim)


func _build_openings() -> void:
	var glass := Mats.color(Color(0.65, 0.82, 0.95, 0.28), 0.05, 0.3)
	var fw := 0.08
	var depth := T + 0.05
	for o in HouseLayout.OPENINGS:
		var a: float = o["from"]
		var b: float = o["to"]
		var bottom: float = o["bottom"]
		var top: float = o["top"]
		var pieces := []
		# jambs and header: [u_center, v_center, u_size, v_size]
		pieces.append([a - fw / 2, (bottom + top) / 2, fw, top - bottom + fw])
		pieces.append([b + fw / 2, (bottom + top) / 2, fw, top - bottom + fw])
		pieces.append([(a + b) / 2, top + fw / 2, b - a + fw * 2, fw])
		if o["kind"] == "window":
			pieces.append([(a + b) / 2, bottom - 0.03, b - a + fw * 3, 0.06])
			pieces.append([(a + b) / 2, (bottom + top) / 2, 0.05, top - bottom])
		for p in pieces:
			var size: Vector3
			var pos: Vector3
			if o["axis"] == "x":
				size = Vector3(p[2], p[3], depth + (0.08 if p[3] == 0.06 else 0.0))
				pos = Vector3(p[0], p[1], o["at"])
			else:
				size = Vector3(depth + (0.08 if p[3] == 0.06 else 0.0), p[3], p[2])
				pos = Vector3(o["at"], p[1], p[0])
			var mi := Geo.mesh_box(size, _trim_mat)
			mi.position = pos
			add_child(mi)
		if o["kind"] == "window":
			var gsize: Vector3
			var gpos: Vector3
			if o["axis"] == "x":
				gsize = Vector3(b - a, top - bottom, 0.02)
				gpos = Vector3((a + b) / 2, (bottom + top) / 2, o["at"])
			else:
				gsize = Vector3(0.02, top - bottom, b - a)
				gpos = Vector3(o["at"], (bottom + top) / 2, (a + b) / 2)
			Geo.static_box(self, gsize, gpos, glass)


func _build_roof() -> void:
	var width := HouseLayout.WIDTH
	var depth := HouseLayout.DEPTH
	var over := 0.5
	var base_y := H
	var ridge_y := H + 2.4
	var x0 := -T / 2 - over
	var x1 := width + T / 2 + over
	var zf := -T / 2 - over
	var zb := depth + T / 2 + over
	var zm := depth / 2
	var slope_drop := over * (ridge_y - base_y) / (zm - zf + over)
	var roof_mat := Mats.textured("roof", 2.0).duplicate() as StandardMaterial3D
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front_len := Vector2(zm - zf, ridge_y - base_y).length()
	var nf := Vector3(0, zm - zf, -(ridge_y - base_y)).normalized()
	var nb := Vector3(0, zb - zm, ridge_y - base_y).normalized()
	Geo.quad(
		st,
		[
			Vector3(x0, base_y - slope_drop, zf),
			Vector3(x1, base_y - slope_drop, zf),
			Vector3(x1, ridge_y, zm),
			Vector3(x0, ridge_y, zm)
		],
		[Vector2(x0, front_len), Vector2(x1, front_len), Vector2(x1, 0), Vector2(x0, 0)],
		nf
	)
	Geo.quad(
		st,
		[
			Vector3(x0, base_y - slope_drop, zb),
			Vector3(x1, base_y - slope_drop, zb),
			Vector3(x1, ridge_y, zm),
			Vector3(x0, ridge_y, zm)
		],
		[Vector2(x0, front_len), Vector2(x1, front_len), Vector2(x1, 0), Vector2(x0, 0)],
		nb
	)
	var roof := MeshInstance3D.new()
	roof.mesh = st.commit()
	roof.material_override = roof_mat
	add_child(roof)

	# Gable ends with siding
	var gst := SurfaceTool.new()
	gst.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-T / 2 - EPS, width + T / 2 + EPS]:
		var n := Vector3.LEFT if x < 0 else Vector3.RIGHT
		var p0 := Vector3(x, base_y, -T / 2)
		var p1 := Vector3(x, base_y, depth + T / 2)
		var p2 := Vector3(x, ridge_y - 0.05, zm)
		var tri := [p0, p1, p2]
		var uvs := [Vector2(p0.z, -p0.y), Vector2(p1.z, -p1.y), Vector2(p2.z, -p2.y)]
		var order := [0, 1, 2]
		if (p1 - p0).cross(p2 - p0).dot(n) > 0.0:
			order = [0, 2, 1]
		for i in order:
			gst.set_normal(n)
			gst.set_uv(uvs[i])
			gst.add_vertex(tri[i])
	var gable := MeshInstance3D.new()
	gable.mesh = gst.commit()
	gable.material_override = Mats.textured("siding", 2.4)
	add_child(gable)

	# Fascia boards along the eaves
	for z in [zf, zb]:
		var fascia := Geo.mesh_box(Vector3(x1 - x0, 0.18, 0.06), _trim_mat)
		fascia.position = Vector3(width / 2, base_y - slope_drop - 0.05, z)
		add_child(fascia)
	# Attic floor so the roof never shows gaps from inside the eaves
	var attic := Geo.mesh_box(Vector3(width + T, 0.05, depth + T), _ceiling_mat)
	attic.position = Vector3(width / 2, H + 0.03, depth / 2)
	add_child(attic)
