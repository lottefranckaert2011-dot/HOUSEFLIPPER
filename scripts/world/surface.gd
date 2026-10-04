class_name Surface
extends StaticBody3D
## A paintable wall side or floor of one room.

var kind := "wall"  # "wall" or "floor"
var room := ""
var side := ""
var key := ""
var finish_id := ""
var area := 0.0
var mesh_instance: MeshInstance3D


func setup(
	p_kind: String, p_room: String, p_side: String, mesh: ArrayMesh, p_finish: String
) -> void:
	kind = p_kind
	room = p_room
	side = p_side
	key = "%s:%s" % [room, side]
	collision_layer = Geo.LAYER_SURFACE
	collision_mask = 0
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	add_child(cs)
	apply(p_finish)


func apply(id: String) -> void:
	finish_id = id
	mesh_instance.material_override = Mats.finish(kind, id)


func finish_data() -> Dictionary:
	return Catalog.finish(kind, finish_id)


func is_old() -> bool:
	return finish_data().get("cat", "old") == "old"
