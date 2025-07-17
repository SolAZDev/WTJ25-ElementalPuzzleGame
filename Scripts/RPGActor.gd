class_name RPGActor extends Actor


@export_subgroup("Stats")
### Current/Max Health
@export var Level:int = 1
@export var Health: Vector2i = Vector2i(10,10)
@export_range(-1,1,.001) var Energetic_Twilight = 0
 


# Micro-Rant about affinities
# Elements do One thing, they each touch certain things but not Chakras...
# Looking up Chakras and Elements together, pairs them up strange...
# Root = Earth = Understandable
# Sacral = Water?! = For Creativity? Usually thats Air or Fire...
# SolarPlex= Fire = Kinda ok?
# Heart = Air = For me it should be water, as emotions
# Throat = Spirit = ??? Air is literally thought and communication

@export_subgroup('Affinities')
### Allows for Grounding in any circumstance, boosts Earth
@export var Root: int = 3
### Allows for Transmutation, boosts Water and Fire
@export var Sacral: int = 3
### Allows for Strength, boosts Fire and Earth
@export var SolarPlexus: int = 3
### Improves Transmutation and Healing, Boosts Health
@export var Heart: int = 3
### Improves Comunication? 
@export var Throat: int = 3
### Improves Perception, boosts Spirit
@export var ThirdEye: int = 3
@export var Crown: int = 3
# Elements
@export var Spirit: int = 3
@export var Air: int = 3
@export var Fire: int = 3
@export var Water: int = 3
@export var Earth: int = 3



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
