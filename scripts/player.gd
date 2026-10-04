class_name Player
extends CharacterBody3D
## First-person controller: WASD to move, mouse to look, E / left click to interact.

const WALK_SPEED := 4.0
const SPRINT_SPEED := 7.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const MAX_PITCH := deg_to_rad(89.0)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(
			head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -MAX_PITCH, MAX_PITCH
		)
	elif event.is_action_pressed("ui_toggle_mouse"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	elif event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


## Calls `interact(player)` on whatever the crosshair is pointing at, if it supports it.
func _try_interact() -> void:
	if not interact_ray.is_colliding():
		return
	var target := interact_ray.get_collider()
	if target and target.has_method("interact"):
		target.interact(self)
