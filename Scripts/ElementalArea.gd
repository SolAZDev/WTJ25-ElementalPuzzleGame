class_name ElementalArea extends Area3D
@export var direction: Vector3 = Vector3.ZERO
@export var multiplier: float = 1
@export var element: Utils.Element
@export var canMeditate: bool = false
# Perdoname, you're in Puerto Rican Summer. 80 is a mercy
@export_range(-32, 300) var tempeture: int = 80

func _init():
	monitoring=true # Force it
	body_entered.connect(enterBody)
	body_exited.connect(exitBody)

func _exit_tree():
	body_entered.disconnect(enterBody)
	body_exited.disconnect(exitBody)
	
func enterBody(body:Node3D): 
	if body is Player: 
		(body as Player).elemental_area = self
		# if element == Utils.Element.AIR: (body as Player).isFloating = true
	
func exitBody(body:Node3D):
	if body is Player:
		if (body as Player).elemental_area == self: 
			(body as Player).elemental_area=null
			(body as Player).isFloating = false
