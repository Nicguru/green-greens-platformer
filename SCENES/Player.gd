extends KinematicBody2D

var state_machine
export var MOVE_SPEED : int = 100
export var TERMINAL_VEL : int = 200

var GRAVITY = 9


# Jump Variables
export var MAX_JUMPS : int = 2
export var JUMP_FORCE : int = 50
var landed = false


#velocity
var velocity : Vector2 = Vector2(0, 0)
var velocity_prev : Vector2 = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine = $AnimationTree.get("parameters/playback")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_input():
	var current = state_machine.get_current_node()
	#inputs
	if Input.is_action_pressed("move_left"):
		velocity.x = -MOVE_SPEED
		state_machine.travel("run")
		$Sprite.flip_h = true
	elif Input.is_action_pressed("move_right"):
		velocity.x = MOVE_SPEED
		state_machine.travel("run")
		$Sprite.flip_h = false
	elif is_on_floor():
		state_machine.travel("idle")
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		$JumpTimer.start()
		state_machine.travel("air_up")

func _physics_process(delta):
	
	get_input()
	
	if not is_on_floor():
		
		landed = false
		$Sprite.scale.y = range_lerp(abs(velocity.y), 0, abs(JUMP_FORCE), 0.8, 1.0)
		$Sprite.scale.x = range_lerp(abs(velocity.y), 0, abs(JUMP_FORCE), 1.1, 0.8)
		
		if velocity.y < 0:
			state_machine.travel("air_up")
		elif velocity.y > 0:
			state_machine.travel("air_down")
		else:
			state_machine.travel("air_idle")
	
	#lerp
	velocity.x = lerp(velocity.x, 0, 0.2)
	
	velocity.y = min(velocity.y + GRAVITY, TERMINAL_VEL)
	
	# handle collisions
	velocity_prev = velocity
	velocity = move_and_slide(velocity, Vector2.UP)
	
	#TODO Sprite Animations
	# if jump pressed, play jump animation
	# if jump pressed in mid-air, play double jump animation
	#
	# when jump animation is complete, go back to main loop
	#
	# when landed, play landed animation
	# when animation is complete, return to main loop
	
	
	
	
	
	
	
	# Squash and Stretch Sprite
	if not landed and is_on_floor():
		landed = true
		$Sprite.scale.x = range_lerp(abs(velocity_prev.y), 0, abs(1700), 1.2, 2.0)
		$Sprite.scale.y = range_lerp(abs(velocity_prev.y), 0, abs(1700), 0.8, 0.5)
	
	$Sprite.scale.x = lerp($Sprite.scale.x, 1, 1 - pow(0.01, delta))
	$Sprite.scale.y = lerp($Sprite.scale.y, 1, 1 - pow(0.01, delta))


func _on_AnimationPlayer_animation_changed(old_name, new_name):
	print(new_name)


func _on_JumpTimer_timeout():
	velocity.y = -JUMP_FORCE
