class_name InteractableArea extends Area3D
@export var isPerson: bool = false
@export var item:Item
@export var req_item:Item
@export var dialogue: DialogueResource
@export var sprite:Sprite3D
# @export var Quest:QuestResource
#@onready var MainObject: Node3D = $".."


func _init():
	monitoring=true # Force it
	body_entered.connect(enterBody)
	body_exited.connect(exitBody)
	
func _ready():
	if !isPerson:
		if sprite!=null and item!=null:
			sprite.texture = item.Icon

func _exit_tree():
	body_entered.disconnect(enterBody)
	body_exited.disconnect(exitBody)
	
func enterBody(body:Node3D): 
	if body is Player: 
		(body as Player).nearest_interactable = self
	
func exitBody(body:Node3D):
	if body is Player:
		if (body as Player).nearest_interactable == self: 
			(body as Player).nearest_interactable=null

func Interact():
	_GameManager.player.input_dir=Vector2.ZERO # FORCE ET
	_GameManager.player.mDir=Vector3.ZERO # FORCE ET
	if isPerson:
		look_at(_GameManager.player.position)
	if dialogue: DialogueManager.show_dialogue_balloon(dialogue)
