class_name Actor extends CharacterBody3D

@export var base_speed = 3

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
