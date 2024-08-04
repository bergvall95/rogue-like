extends CharacterBody3D

@export var SPEED_DEFAULT : float = 5.0
@export var SPEED_CROUCH : float = 2.0
@export var SPEED_SPRINT : float = 8.0 
@export var TOGGLE_CROUCH : bool = true
@export var JUMP_VELOCITY : float = 4.5
@export_range(5, 10, 0.1) var CROUCH_SPEED : float = 7.0
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var animation_player: AnimationPlayer
@export var CROUCH_SHAPECAST : Node3D
@export var BOB_FREQ = 2.0
@export var BOB_AMP= 0.1
# FOV variables
@export var BASE_FOV = 75.0
const FOV_CHANGE = 1.5
@onready var camera = $CameraController/Camera3D


var _speed : float
var _mouse_input : bool = false
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var t_bob= 0.0
var _is_crouching : bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event: InputEvent) -> void:
	
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
		
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("crouch") and is_on_floor() and TOGGLE_CROUCH == true:
		toggle_crouch()
	if event.is_action_pressed("crouch") and _is_crouching == false and is_on_floor() and TOGGLE_CROUCH == false:
		crouching(true)    # hold to crouch
	if event.is_action_released("crouch") and TOGGLE_CROUCH == false:
		if CROUCH_SHAPECAST.is_colliding() == false:
			crouching(false)
		elif CROUCH_SHAPECAST.is_colliding() == true:
			uncrouch_check()


func _update_camera(delta: float) -> void:
	
	# Rotates camera using euler rotation
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA_CONTROLLER.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0
	
func _ready():

	# Get mouse input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# set default speed
	_speed = SPEED_DEFAULT
	
	# add crouch check shapecast collision exception for CharacterBody3D node
	CROUCH_SHAPECAST.add_exception($".")

func _physics_process(delta):
	
	# Update camera movement based on mouse movement
	_update_camera(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and _is_crouching == false:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.is_action_pressed('sprint'):
		_speed = SPEED_SPRINT
	else: 
		_speed = SPEED_DEFAULT
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin
	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
	
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED_SPRINT * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	move_and_slide()

func toggle_crouch():
	if _is_crouching == true and CROUCH_SHAPECAST.is_colliding() == false:
		crouching(false)
	elif _is_crouching == false:
		crouching(true)

func uncrouch_check():
	if CROUCH_SHAPECAST.is_colliding() == false:
		crouching(false)
	if CROUCH_SHAPECAST.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()

func crouching(state : bool):
	match state:
		true:
			animation_player.play("Crouch", -1, CROUCH_SPEED)
			set_movement_speed("crouching")
		false:
			animation_player.play("Crouch", -1, -CROUCH_SPEED, true)
			set_movement_speed("default")



func _on_animation_player_animation_started(anim_name):
	if anim_name == "Crouch":
		_is_crouching = !_is_crouching

func set_movement_speed(state : String):
	match state:
		"default":
			_speed = SPEED_DEFAULT
		"crouching":
			_speed = SPEED_CROUCH



func _on_grab_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("loot"):
		area.target = self



func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ) * BOB_AMP
	return pos

func _on_collect_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
