class_name RPGActor extends Actor

@export_subgroup("Stats")
### Current/Max Health
@export var Level:int = 1
@export var Health: Vector2i = Vector2i(10,10)
@export var Stamina: Vector2 = Vector2(10,10)
@export_range(-1,1,.001) var Energetic_Twilight = 0
@export var affinities:Affinities
