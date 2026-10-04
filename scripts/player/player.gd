class_name Player
extends CharacterBody3D
## First-person controller: WASD to move, mouse to look.

const WALK_SPEED := 4.2
const SPRINT_SPEED := 6.8
const JUMP_VELOCITY := 4.2
const BASE_SENSITIVITY := 0.0022
const MAX_PITCH := deg_to_rad(88.0)
const EYE_HEIGHT := 1.62

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var head: Node3D
var camera: Camera3D
var tools: ToolController
var _bob := 0.0


func _init() -> void:
	collision_layer = Geo.LAYER_PLAYER
	collision_mask = Geo.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	cs.shape = capsule
	cs.position.y = 0.875
	add_child(cs)
	head = Node3D.new()
	head.name = "Head"
	head.position.y = EYE_HEIGHT
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 75.0
	camera.near = 0.03
	camera.far = 250.0
	head.add_child(camera)
	tools = ToolController.new()
	tools.name = "Tools"
	camera.add_child(tools)


func set_look(yaw: float, pitch := 0.0) -> void:
	rotation.y = yaw
	head.rotation.x = pitch


func _can_control() -> bool:
	return Game.playing and not Game.is_ui_open()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_control():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s: float = BASE_SENSITIVITY * float(Game.settings["sensitivity"])
		rotate_y(-event.relative.x * s)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * s, -MAX_PITCH, MAX_PITCH)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_dir := Vector2.ZERO
	if _can_control():
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var accel := 12.0 if is_on_floor() else 3.0
	velocity.x = move_toward(velocity.x, direction.x * speed, accel * speed * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, accel * speed * delta)
	move_and_slide()

	# Gentle head bob while walking.
	var horizontal := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal > 0.5:
		_bob += delta * horizontal * 2.2
	else:
		_bob = lerpf(_bob, roundf(_bob / PI) * PI, delta * 6.0)
	head.position.y = EYE_HEIGHT + sin(_bob) * 0.035
