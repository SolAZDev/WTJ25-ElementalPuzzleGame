class_name PlayerHUD extends CanvasLayer

# This means we NEED to have this object as a child of the player.
@onready var player:Player = $".." 

@onready var UpdateTimer = $UpdateTimer

# Bars
@onready var Health:TextureProgressBar = $Bars/Health
@onready var Stamina:TextureProgressBar = $Bars/Stamina
@onready var ETNeg:TextureProgressBar = $"Bars/Energy Twilight/Negative"
@onready var ETPos:TextureProgressBar = $"Bars/Energy Twilight/Positive"

#Inputs
@onready var WestBtnText:Label = $Inputs/FaceBtns/West/Label
@onready var EastBtnText:Label = $Inputs/FaceBtns/East/Label
@onready var ItemIcon:TextureRect = $Inputs/HBoxContainer/ItemIcon
@onready var NullItemIcon = preload("res://Assets/Sprites/circle.svg")

# Afinities - Chakras
@onready var CrownLabel:Label = $Affinities/Chakras/Crown/Label
@onready var ThirdEyeLabel:Label = $Affinities/Chakras/ThirdEye/Label
@onready var ThroatLabel:Label = $Affinities/Chakras/Throat/Label
@onready var HeartLabel:Label = $Affinities/Chakras/Heart/Label
@onready var SolarLabel:Label = $Affinities/Chakras/Solar/Label
@onready var SacralLabel:Label = $Affinities/Chakras/Sacral/Label
@onready var RootLabel:Label = $Affinities/Chakras/Root/Label
# Afinities - Elements
@onready var SpiritLabel:Label = $Affinities/Element/Aether/Label
@onready var AirLabel:Label = $Affinities/Element/Air/Label
@onready var FireLabel:Label = $Affinities/Element/Fire/Label
@onready var WaterLabel:Label = $Affinities/Element/Water/Label
@onready var EarthLabel:Label = $Affinities/Element/Earth/Label

signal updateEastBtn(str: String)
signal updateWestBtn(str: String)

# Called when the node enters the scene tree for the first time.
func _ready():
	UpdateTimer.timeout.connect(UpadteUI)
	updateEastBtn.connect(updateEBtn)
	updateWestBtn.connect(updateWBtn)
	UpdateTimer.start()

func UpadteUI()->void:
	
	# Bars
	Health.max_value = player.Health.y
	Health.value = player.Health.x
	Stamina.max_value = player.Stamina.y
	Stamina.value = player.Stamina.x
	ETNeg.value = player.Energetic_Twilight
	ETPos.value = player.Energetic_Twilight
	
	# Afinities - Chakras
	CrownLabel.text = str(player.affinities.Crown)
	ThirdEyeLabel.text = str(player.affinities.ThirdEye)
	ThroatLabel.text = str(player.affinities.Throat)
	HeartLabel.text = str(player.affinities.Heart)
	SolarLabel.text = str(player.affinities.SolarPlexus)
	SacralLabel.text = str(player.affinities.Sacral)
	RootLabel.text = str(player.affinities.Root)
	# Afinities - Elements
	SpiritLabel.text = str(player.affinities.Spirit)
	AirLabel.text = str(player.affinities.Air)
	FireLabel.text = str(player.affinities.Fire)
	WaterLabel.text = str(player.affinities.Water)
	EarthLabel.text = str(player.affinities.Earth)
	
	# Inputs, The Tricky one.
	if player.activeItem == -1: ItemIcon.texture = NullItemIcon
	else: ItemIcon.texture = player.items[player.activeItem].Icon
	
func updateEBtn(str:String)->void:
	print(str)
	updateButtonLabel(EastBtnText,str)
func updateWBtn(str:String)->void:updateButtonLabel(WestBtnText,str)
func updateButtonLabel(btnLabel:Label, string:String)->void:
	btnLabel.text = string
