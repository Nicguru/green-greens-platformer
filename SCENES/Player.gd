extends KinematicBody2D

var state_machine # Animation Tree

signal shake_camera(trauma)

export var MOVE_SPEED : float = 0.5
export var MAX_SPEED : int = 200
export var TERMINAL_VEL : int = 200
export var GRAVITY = 9

export var WALL_SLIDE_ACCEL : int = 6
export var WALL_SLIDE_SPEED : int = 100

# Jump Variables
export var MAX_JUMPS : int = 2
export var JUMP_FORCE : int = 50
export var JUMP_MIN : int = 25
var jumps = MAX_JUMPS
var landed = false

var is_attacking = false
var is_ground_pound = false


# velocity
var velocity : Vector2 = Vector2(0, 0)
var velocity_prev : Vector2 = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine = $AnimationTree.get("parameters/playback")


# gets player input
func get_input():
	#inputs
	if is_on_floor() and Input.is_action_just_pressed("attack"):
		state_machine.travel("attack")
	if not is_attacking:
		if Input.is_action_pressed("move_left"):
			velocity.x = lerp(velocity.x, -MAX_SPEED, MOVE_SPEED)
		if Input.is_action_pressed("move_right"):
			velocity.x = lerp(velocity.x, MAX_SPEED, MOVE_SPEED)
		if Input.is_action_just_pressed("move_down"):
			is_ground_pound = true
		jump_handler()

func toggle_attacking():
	is_attacking = !is_attacking

func ground_pound():
	if is_ground_pound and not is_on_floor():
		velocity.y = TERMINAL_VEL
	

func jump_handler():
	if Input.is_action_just_pressed("jump") and jumps > 0:
		jumps -= 1
		velocity.y = -JUMP_FORCE
		
		# Wall Jumps
		if not is_on_floor() and is_on_wall():
			if Input.is_action_pressed("move_right"):
				velocity.x = -MAX_SPEED * 4
			elif Input.is_action_pressed("move_left"):
				velocity.x = MAX_SPEED * 4
		
		if is_on_floor():
			state_machine.travel("jump")
		else:
			state_machine.travel("double_jump")
		
	elif is_on_floor():
		jumps = MAX_JUMPS
	
	if Input.is_action_just_released("jump") and velocity.y < -JUMP_MIN:
		velocity.y = -JUMP_MIN
	

func wall_slide():
	#wall slide
	if is_on_wall() and velocity.y > 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		jumps = MAX_JUMPS
		if velocity.y >= 0:
			velocity.y = min(velocity.y + WALL_SLIDE_ACCEL, WALL_SLIDE_SPEED)
	

func handle_animation():
	if velocity.x > 1:
		$Sprite.flip_h = false
	elif velocity.x < -1:
		$Sprite.flip_h = true
		
	if is_on_floor():
		if abs(velocity.x) >= 1:
			state_machine.travel("run")
		else:
			state_machine.travel("idle")
	if not is_on_floor():
		# wall sliding animation
		if is_on_wall() and velocity.y > 0:
			if Input.is_action_pressed("move_left"):
				$Sprite.flip_h = false
				state_machine.travel("wall_slide")
			elif Input.is_action_pressed("move_right"):
				$Sprite.flip_h = true
				state_machine.travel("wall_slide")
		else:
			# falling animation
			if velocity.y < 0:
				state_machine.travel("air_up")
			elif velocity.y > 0:
				state_machine.travel("air_down")
			else:
				state_machine.travel("air_idle")

func squash_and_stretch(delta):
	if not is_on_floor():
		landed = false
		$Sprite.scale.y = range_lerp(abs(velocity.y), 0, abs(JUMP_FORCE), 0.8, 1.0)
		$Sprite.scale.x = range_lerp(abs(velocity.y), 0, abs(JUMP_FORCE), 1.1, 0.8)
	if not landed and is_on_floor():
		landed = true
		if is_ground_pound:
			is_ground_pound = false
			emit_signal("shake_camera", 0.4)
		$Sprite.scale.x = range_lerp(abs(velocity_prev.y), 0, abs(1700), 1.2, 1.5)
		$Sprite.scale.y = range_lerp(abs(velocity_prev.y), 0, abs(1700), 0.8, 0.5)
	
	$Sprite.scale.x = lerp($Sprite.scale.x, 1, 1 - pow(0.01, delta))
	$Sprite.scale.y = lerp($Sprite.scale.y, 1, 1 - pow(0.01, delta))
	

func _physics_process(delta):
	
	handle_animation()
	get_input()
	wall_slide()
	ground_pound()
	
	#lerp
	velocity.x = lerp(velocity.x, 0, 0.2)
	
	
	#gravity
	velocity.y = min(velocity.y + GRAVITY, TERMINAL_VEL)
	velocity_prev = velocity
	
	# handle collisions
	velocity = move_and_slide(velocity, Vector2.UP)
	
	squash_and_stretch(delta)
