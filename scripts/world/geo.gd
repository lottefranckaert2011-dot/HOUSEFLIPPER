class_name Geo
## Geometry helpers used to build the house procedurally.

const LAYER_WORLD := 1
const LAYER_INTERACT := 2
const LAYER_SURFACE := 4


## Splits a wall span [u0, u1] x [0, height] into solid rectangles around the
## openings. Returns [[ua, ub, va, vb], ...].
static func wall_rects(u0: float, u1: float, height: float, openings: Array) -> Array:
	var rects := []
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a, b): return a["from"] < b["from"])
	var cursor := u0
	for o in sorted:
		var a := maxf(float(o["from"]), u0)
		var b := minf(float(o["to"]), u1)
		if b <= a:
			continue
		if a > cursor:
			rects.append([cursor, a, 0.0, height])
		if o["top"] < height:
			rects.append([a, b, o["top"], height])
		if o["bottom"] > 0.0:
			rects.append([a, b, 0.0, o["bottom"]])
		cursor = maxf(cursor, b)
	if cursor < u1:
		rects.append([cursor, u1, 0.0, height])
	return rects


## Adds a quad a-b-c-d (any winding) facing `normal`, with the given UVs.
static func quad(st: SurfaceTool, pts: Array, uvs: Array, normal: Vector3) -> void:
	var order := [0, 1, 2, 0, 2, 3]
	# Godot treats clockwise triangles as front-facing.
	if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for i in order:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(pts[i])


static func mesh_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	return mi


static func static_box(
	parent: Node, size: Vector3, pos: Vector3, mat: Material, layer := LAYER_WORLD
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = pos
	if mat:
		body.add_child(mesh_box(size, mat))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body


## Bounding box of all meshes under `node`, in `node`'s parent space.
static func aabb(node: Node, xf := Transform3D.IDENTITY) -> AABB:
	var box := AABB()
	var first := true
	if node is Node3D:
		xf = xf * node.transform
	if node is MeshInstance3D and node.mesh:
		box = xf * node.get_aabb()
		first = false
	for c in node.get_children():
		var b := aabb(c, xf)
		if b.size != Vector3.ZERO:
			box = b if first else box.merge(b)
			first = false
	return box


static func mesh_instances(node: Node, out: Array = []) -> Array:
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		mesh_instances(c, out)
	return out


## Loads a model, recentres it so its footprint is centred on the origin and its
## base sits at y = 0, and scales it. Returns a holder node.
static func load_model(path: String, scale: float) -> Node3D:
	var holder := Node3D.new()
	var inst: Node3D = load(path).instantiate()
	holder.add_child(inst)
	var box := aabb(inst)
	var c := box.get_center()
	inst.position = -Vector3(c.x, box.position.y, c.z)
	holder.scale = Vector3.ONE * scale
	return holder
