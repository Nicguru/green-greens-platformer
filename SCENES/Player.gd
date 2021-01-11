extends KinematicBody2D


export var move_speed : int = 200

#velocity
var velocity : Vector2 = Vector2(0, 0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _physics_process(delta):
	
	#inputs
	if Input.is_action_pressed("move_left"):
		velocity.x = -move_speed
		$AnimatedSprite.play("run")
		$AnimatedSprite.flip_h = true
	elif Input.is_action_pressed("move_right"):
		velocity.x = move_speed
		$AnimatedSprite.play("run")
		$AnimatedSprite.flip_h = false
	else:
		$AnimatedSprite.play("idle")
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	#lerp
	velocity.x = lerp(velocity.x, 0, 0.2)
