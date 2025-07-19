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

func InventoryCheck(name:String)->bool:
	return player.PlayerHasItem(name)

func AddItem(item:Item)->void:
	player.items.push_back(item)

func RemoveItem(item:Item)->void:
	if player.items.has(item):
		var index = player.items.find(item)
		player.items.pop_at(index)
