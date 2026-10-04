extends SceneTree
## Prints the bounding box size of every imported model. Run with:
## godot --headless -s res://tools/measure_models.gd


func _initialize() -> void:
	for dir in [
		"res://assets/models/furniture",
		"res://assets/models/nature",
		"res://assets/models/suburban"
	]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".glb"):
				continue
			var inst: Node3D = load(dir + "/" + f).instantiate()
			root.add_child(inst)
			var box := _aabb(inst, Transform3D.IDENTITY)
			print(
				"%s/%s size=%s pos=%s" % [dir.get_file(), f.get_basename(), box.size, box.position]
			)
			inst.free()
	quit()


func _aabb(node: Node, xf: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	if node is Node3D:
		xf = xf * node.transform
	if node is MeshInstance3D:
		box = xf * node.get_aabb()
		first = false
	for c in node.get_children():
		var b := _aabb(c, xf)
		if b.size != Vector3.ZERO:
			box = b if first else box.merge(b)
			first = false
	return box
