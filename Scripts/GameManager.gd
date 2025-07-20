class_name  GameManager extends Node

var player:Player
var Quests: Dictionary[String, int] = {
	"Air":0,
	"Fire":0,
	"Water":0,
	"Earth":0,
	"Spirit":0,
}

func MakeProfile()->Dictionary:
	return {
		'PlayerPos': player.global_position,
		'Items':player.items,
		'Quests': Quests,
		'Affinities': player.affinities
	}
func PlayerHasRequestedItem()->bool: return InventoryCheck(player.nearest_interactable.req_item.Name)
func InventoryCheck(item_name:String)->bool:
	return player.PlayerHasItem(item_name)

func GetActiveInteractiveItem()->Item: return player.nearest_interactable.item
func DisableActiveInteractive()->void: 
	player.nearest_interactable.queue_free()
	player.nearest_interactable=null # Just in case
	
func AddActiveInteractiveItem(): AddItem(player.nearest_interactable.item)

func RemoveActiveInteractiveRequestItem(): RemoveItem(player.nearest_interactable.req_item)

func AddItem(item:Item)->void:
	player.items.push_back(item)

func RemoveItem(item:Item)->void:
	if player.items.has(item):
		if player.PlayerActiveItemIs(item.Name): player.activeItem=-1
		var index = player.items.find(item)
		player.items.pop_at(index)
