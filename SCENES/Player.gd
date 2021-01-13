class_name Player
extends Actor

onready var platform_detector = $PlatformDetector

var state_machine # Animation Tree

signal shake_camera(trauma)

const FLOOR_DETECT_DISTANCE = 30


# Jump Variables
export var MAX_JUMPS : int = 2
export var JUMP_FORCE : int = 50
export var JUMP_MIN : int = 25
var jumps = MAX_JUMPS
var landed = false

var is_attacking = false
var is_ground_pound = false


var velocity_prev : Vector2 = Vector2()

# returns a Vector2 for the direction of the player
func get_direction():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1 if jumps > 0 and Input.is_action_just_pressed("jump") else 0
	)

func is_jumping(direction):
	return direction.y != 0.0

# calculates the player's velocity
# handles jumps, short hops, wall slide, ground pound
func calculate_move_velocity(
	linear_velocity,
	direction,
	speed,
	is_jump_interrupted
):
	var velocity = linear_velocity
	# ground movement
	velocity.x = int(lerp(velocity.x, speed.x * direction.x, 0.2))
	
	if not is_on_floor() and is_on_wall() and direction.x != 0:
		jumps = MAX_JUMPS
		velocity.y = min(velocity.y, speed.y * 0.5)
	
	if is_ground_pound:
		velocity.y = speed.y
	
	# jump movement
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
		
		# wall jump
		if not is_on_floor() and is_on_wall():
			velocity.x = -speed.x * 2 if direction.x > 0 else speed.x * 2
	
	# short hop
	if is_jump_interrupted:
		velocity *= 0.5
	return velocity

# handles various player input
func player_input():
	if Input.is_action_just_pressed("move_down") and not is_on_floor():
		is_ground_pound = true

# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine = $AnimationTree.get("parameters/playback")

func toggle_attacking():
	is_attacking = !is_attacking

# takes a direction vector and decrements the jump count
# resets the jump count when the player lands on the floor
func jump_handler(direction):
	if is_jumping(direction) and jumps > 0:
		jumps -= 1
		
	elif is_on_floor():
		jumps = MAX_JUMPS
	

# takes a direction vector and returns an animation node string
# for the current state
func get_new_animation_node(direction):
	var animation_new = ""
	if is_on_floor():
		animation_new = "run" if abs(_velocity.x) > 1 else "idle"
	elif is_on_wall():
		animation_new = "wall_slide"
	elif is_jumping(direction):
		animation_new = "double_jump"
	else:
		animation_new = "air_down" if _velocity.y > 0 else "air_up"
	return animation_new

func handle_animation():
	if _velocity.x > 1:
		$Sprite.flip_h = false
	elif _velocity.x < -1:
		$Sprite.flip_h = true

	if is_on_floor():
		if abs(_velocity.x) >= 1:
			state_machine.travel("run")
		else:
			state_machine.travel("idle")
	if not is_on_floor():
		# wall sliding animation
		if is_on_wall() and _velocity.y > 0:
			if Input.is_action_pressed("move_left"):
				$Sprite.flip_h = false
				state_machine.travel("wall_slide")
			elif Input.is_action_pressed("move_right"):
				$Sprite.flip_h = true
				state_machine.travel("wall_slide")
		else:
			# falling animation
			if _velocity.y < 0:
				state_machine.travel("air_up")
			elif _velocity.y > 0:
				state_machine.travel("air_down")
			else:
				state_machine.travel("air_idle")

# applies squash and stretch animation technique when jumping and landing
func squash_and_stretch(delta):
	if not is_on_floor():
		landed = false
		$Sprite.scale.y = range_lerp(abs(_velocity.y), 0, abs(JUMP_FORCE), 0.8, 1.0)
		$Sprite.scale.x = range_lerp(abs(_velocity.y), 0, abs(JUMP_FORCE), 1.1, 0.8)
	if not landed and is_on_floor():
		landed = true
		if is_ground_pound:
			is_ground_pound = false
			emit_signal("shake_camera", 0.4)
		$Sprite.scale.x = range_lerp(abs(velocity_prev.y), 0, abs(1700), 1.2, 1.5)
		$Sprite.scale.y = range_lerp(abs(velocity_prev.y), 0, abs(1700), 0.8, 0.5)
	
	$Sprite.scale.x = lerp($Sprite.scale.x, 1, 1 - pow(0.01, delta))
	$Sprite.scale.y = lerp($Sprite.scale.y, 1, 1 - pow(0.01, delta))
	
# runs every physics cycle
func _physics_process(delta):
	var direction = get_direction()
	
	player_input()
	
	var is_jump_interrupted = Input.is_action_just_released("jump") and _velocity.y < 0.0
	_velocity = calculate_move_velocity(
		_velocity,
		direction,
		speed,
		is_jump_interrupted)
	jump_handler(direction)
	
	velocity_prev = _velocity
	
	# handle collisions
	var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y == 0 else Vector2.ZERO 
	var is_on_platform = platform_detector.is_colliding()
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4, 0.9, false
	)
	
	# flip sprite
	if direction.x > 0:
		$Sprite.flip_h = true if is_on_wall() and not is_on_floor() else false
	elif direction.x < 0:
		$Sprite.flip_h = false if is_on_wall() and not is_on_floor() else true
	
	
	
	var animation = get_new_animation_node(direction)
	state_machine.travel(animation)
	
	squash_and_stretch(delta)
