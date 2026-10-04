class_name Furniture
extends StaticBody3D
## A placed piece of furniture (bought by the player) or old junk furniture.

var item_id := ""
var junk := false
var key := ""
var box_size := Vector3.ONE
var box_center := Vector3.ZERO
var model: Node3D


static func create(id: String, ghost := false) -> Furniture:
	var f := Furniture.new()
	f.item_id = id
	f.junk = Catalog.JUNK.has(id)
	var data := Catalog.item(id)
	f.name = id
	var scale: float = data.get("scale", 2.0)
	f.model = Geo.load_model(Catalog.model_path(data), scale)
	f.add_child(f.model)
	var box := Geo.aabb(f.model)
	if data.get("place", "floor") == "wall":
		# Wall items hang with their back against the wall (local -Z) and are
		# centred vertically on the placement point.
		f.model.position = Vector3(0, -box.get_center().y, -box.position.z)
		box = Geo.aabb(f.model)
	f.box_size = box.size
	f.box_center = box.get_center()
	if ghost:
		f.collision_layer = 0
		f.collision_mask = 0
		for mi in Geo.mesh_instances(f.model):
			mi.material_override = Mats.ghost(true)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		f.collision_layer = Geo.LAYER_WORLD
		f.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = (box.size - Vector3(0.02, 0.0, 0.02)).max(Vector3.ONE * 0.05)
		cs.shape = shape
		cs.position = box.get_center()
		f.add_child(cs)
		if f.junk:
			f._tint(data.get("tint", Color(0.5, 0.4, 0.35)))
	return f


func data() -> Dictionary:
	return Catalog.item(item_id)


func display_name() -> String:
	return data().get("name", item_id)


func place_mode() -> String:
	return data().get("place", "floor")


func set_ghost_valid(valid: bool) -> void:
	var m := Mats.ghost(valid)
	for mi in Geo.mesh_instances(model):
		mi.material_override = m


func _tint(c: Color) -> void:
	for mi: MeshInstance3D in Geo.mesh_instances(model):
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			if src is StandardMaterial3D:
				var m: StandardMaterial3D = src.duplicate()
				m.albedo_color = m.albedo_color.lerp(c, 0.55).darkened(0.15)
				m.roughness = 1.0
				mi.set_surface_override_material(i, m)
