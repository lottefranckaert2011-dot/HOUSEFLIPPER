class_name Mats
## Shared material factory with caching.

static var _cache := {}


static func tex(tex_name: String) -> Texture2D:
	var key := "tex:" + tex_name
	if not _cache.has(key):
		_cache[key] = load("res://assets/textures/%s.png" % tex_name)
	return _cache[key]


## Material for a wall or floor finish. Meshes using it must have UVs in metres.
static func finish(kind: String, id: String) -> StandardMaterial3D:
	var key := "finish:%s:%s" % [kind, id]
	if _cache.has(key):
		return _cache[key]
	var data := Catalog.finish(kind, id)
	var m := StandardMaterial3D.new()
	m.roughness = 0.85 if kind == "wall" else 0.7
	if data.has("tex"):
		m.albedo_texture = tex(data["tex"])
		var s := 1.0 / float(data.get("m", 2.0))
		m.uv1_scale = Vector3(s, s, 1)
		m.albedo_color = data.get("tint", Color.WHITE)
	else:
		m.albedo_color = data.get("color", Color.WHITE)
	if data.get("cat", "") == "tiles":
		m.roughness = 0.3
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m


static func color(c: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var key := "col:%s:%s:%s" % [c.to_html(), roughness, metallic]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = roughness
		m.metallic = metallic
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cache[key] = m
	return _cache[key]


## Textured material with UVs in metres (one repeat every `metres`).
static func textured(
	tex_name: String, metres: float, tint := Color.WHITE, roughness := 0.85
) -> StandardMaterial3D:
	var key := "tx:%s:%s:%s" % [tex_name, metres, tint.to_html()]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex(tex_name)
		m.albedo_color = tint
		m.roughness = roughness
		m.uv1_scale = Vector3(1.0 / metres, 1.0 / metres, 1)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_cache[key] = m
	return _cache[key]


## Same as textured() but projected in world space, for primitive meshes.
static func triplanar(
	tex_name: String, metres: float, tint := Color.WHITE, roughness := 0.85
) -> StandardMaterial3D:
	var key := "tri:%s:%s:%s" % [tex_name, metres, tint.to_html()]
	if not _cache.has(key):
		var m := textured(tex_name, metres, tint, roughness).duplicate()
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		_cache[key] = m
	return _cache[key]


static func ghost(valid: bool) -> StandardMaterial3D:
	var key := "ghost:%s" % valid
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.3, 1.0, 0.45, 0.45) if valid else Color(1.0, 0.3, 0.25, 0.45)
		m.no_depth_test = false
		_cache[key] = m
	return _cache[key]
