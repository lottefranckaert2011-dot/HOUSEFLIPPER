class_name Mess
extends StaticBody3D
## A piece of mess: trash (picked up by hand), dirt (scrubbed with the sponge)
## or a weed (pulled with the sponge/garden tool).

signal removed(mess: Mess)

const REWARD := {"trash": 3, "dirt": 5, "weed": 4}

var kind := "trash"
var key := ""
var room := ""
var display_name := ""
var health := 1.0
var _visual: Node3D
var _material: StandardMaterial3D
var _base_alpha := 1.0
var _gone := false


func setup(
	p_kind: String,
	p_key: String,
	p_name: String,
	visual: Node3D,
	shape_size: Vector3,
	shape_offset := Vector3.ZERO
) -> void:
	kind = p_kind
	key = p_key
	display_name = p_name
	collision_layer = Geo.LAYER_INTERACT
	collision_mask = 0
	_visual = visual
	add_child(visual)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = shape_size
	cs.shape = box
	cs.position = shape_offset
	add_child(cs)
	if kind == "dirt":
		var mi := visual as MeshInstance3D
		_material = mi.material_override
		_base_alpha = _material.albedo_color.a


func reward() -> int:
	return REWARD.get(kind, 0)


## Hand tool: pick up trash.
func pick_up(toward: Vector3) -> void:
	if _gone:
		return
	_gone = true
	collision_layer = 0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "global_position", toward, 0.25).set_ease(Tween.EASE_IN).set_trans(
		Tween.TRANS_BACK
	)
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.25)
	tw.chain().tween_callback(_finish)


## Sponge tool: scrub dirt / pull weeds. Returns true once fully cleaned.
func scrub(amount: float) -> bool:
	if _gone:
		return false
	health -= amount
	if kind == "dirt" and _material:
		var c := _material.albedo_color
		c.a = _base_alpha * clampf(health, 0.0, 1.0)
		_material.albedo_color = c
	elif kind == "weed":
		_visual.scale = Vector3.ONE * lerpf(0.3, 1.0, clampf(health, 0.0, 1.0))
		_visual.rotation.z = sin(health * 40.0) * 0.08
	if health <= 0.0:
		_gone = true
		collision_layer = 0
		if kind == "weed":
			var tw := create_tween()
			tw.tween_property(self, "position:y", position.y + 0.5, 0.2)
			tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.15)
			tw.tween_callback(_finish)
		else:
			_finish()
		return true
	return false


func is_gone() -> bool:
	return _gone


func _finish() -> void:
	removed.emit(self)
	queue_free()
