extends Node
## Dev tool: renders a catalog thumbnail for every shop item into assets/thumbs.
## xvfb-run godot --rendering-driver opengl3 --resolution 512x512 -- --thumbs
## (Game autoload adds this node when it sees --thumbs.)

const SIZE := 160


func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene.queue_free()
	await get_tree().process_frame
	var vp := get_viewport()
	vp.transparent_bg = true
	var stage := Node3D.new()
	get_tree().root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.environment.ambient_light_energy = 0.7
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.2
	stage.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30
	stage.add_child(cam)
	cam.current = true
	DirAccess.make_dir_recursive_absolute("res://assets/thumbs")
	var only := OS.get_cmdline_user_args().slice(OS.get_cmdline_user_args().find("--thumbs") + 1)
	for id in Catalog.ITEMS:
		if not only.is_empty() and id not in only:
			continue
		var f := Furniture.create(id, false)
		stage.add_child(f)
		var box := Geo.aabb(f.model)
		var center := box.get_center()
		var radius := box.size.length() * 0.5
		var dir := Vector3(0.75, 0.55, 1.0).normalized()
		if Catalog.item(id).get("place", "floor") == "wall":
			dir = Vector3(0.45, 0.25, 1.0).normalized()
		cam.global_position = center + dir * radius / sin(deg_to_rad(cam.fov * 0.5)) * 1.05
		cam.look_at(center)
		for i in 3:
			await get_tree().process_frame
		var img := vp.get_texture().get_image()
		var s := mini(img.get_width(), img.get_height())
		img = img.get_region(Rect2i((img.get_width() - s) / 2, (img.get_height() - s) / 2, s, s))
		img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		img.save_png("res://assets/thumbs/%s.png" % id)
		f.free()
	print("thumbnails done")
	get_tree().quit()
