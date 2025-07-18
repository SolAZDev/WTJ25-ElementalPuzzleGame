class_name Player extends RPGActor



@export_subgroup("Settings")
@export var mouse_sensitivity: float = 0.25
@export var joycam_sensitivity: float = 1.25

@onready var camera: Camera3D = $Camera3D
@onready var meditation_timer: Timer = $MeditationTimer
@onready var WallClimbCheck: RayCast3D = $Mesh/WallClimbCheck	
@onready var pcam: PhantomCamera3D = $ThirdPartyCam
@onready var CharacterHolder: Node3D = $Mesh
@onready var HUD:PlayerHUD = $PlayerHUD

@export_category("Speed Settings")
@export var swim_speed = 5.0
@export var climb_speed = 4.0
@export var jump_force = 4.5

var jDir:Vector3 = Vector3.ZERO
var mDir: Vector3 = Vector3.ZERO
var cJoy: Vector3 = Vector3.ZERO
var aim:Vector3 = Vector3.ZERO

var meditating: bool = false
var timesBreathCycled: int = 0
var deepMeditation:bool=false
var deeperMeditation:bool=false
var isFloating: bool = false;
var isClimbing:bool = false
var elemental_area:ElementalArea = null

@export var items: Array[Item] = []
var activeItem:int = 0 # TODO: ItemIndex ffs

func _init(): pass

func CanClimb()->bool:
	if elemental_area!=null:
		if elemental_area is ClimbableArea:
			return WallClimbCheck.is_colliding()
	return false


func _process(_delta):
	var cJoy = Input.get_vector("cam_lt","cam_rt","cam_up","cam_dw")
	if cJoy: _set_pcam_rotation(pcam, cJoy, true)
	#super(_delta)
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and (!isFloating and !isClimbing):
		# this is slow af, I bet... No I sadly don't care...
		if PlayerActiveItemIs('Wing Cloak'): #TODO: This works, but what if we're in Wind Area?
			if Stamina.x > 0:
				velocity += (get_gravity()/2) * delta
				Stamina.x-=delta
			else:
				velocity += get_gravity() * delta
		else:
			velocity += get_gravity() * delta
	if !WallClimbCheck.is_colliding() and isClimbing:
		isClimbing=false
	var collided:bool = move_and_slide()
	
	if is_on_floor() and Stamina.x<Stamina.y:
		Stamina.x+=delta*.2
	
	# Disclaimer, I hate this; I don't wanna update UI on _process, but brain be farty
	#if CanClimb() and !isClimbing: HUD.emit_signal("updateEastBtn", 'Climb')
	#elif CanClimb() and isClimbing: HUD.emit_signal("updateEastBtn", 'idk,drop?')
	#else: HUD.emit_signal("updateEastBtn", '')

### Add Extra Speed to Movement based on Elemental Area
func ElementalAreaInfluence()->Vector3:
	var returnable = Vector3.ZERO
	if elemental_area!=null:
		var extra: float = 0
		match elemental_area.element:
			Utils.Element.AIR: extra=affinities.Air # TODO Add Glider
			Utils.Element.FIRE: extra=affinities.Fire # TODO Add Flame Boots
			Utils.Element.WATER: extra=affinities.Water # TODO: Add Canoe
			Utils.Element.EARTH: extra=affinities.Earth # TODO: Add Grippy Hands or Boots
			 # Dunno why but sure... Is this how we teleport?
			# Is this how we can project outside our bodies?
			# But what happens when we don't have a body??? 
			Utils.Element.SPIRIT: extra=affinities.Spirit
		var dir = elemental_area.direction * (elemental_area.multiplier + (.1*extra))
		if elemental_area is ClimbableArea:
			if (elemental_area as ClimbableArea).isWet:
				dir.y -= (elemental_area as ClimbableArea).slipperiness / (affinities.Earth/2 + affinities.Root/2)
		if dir.length() > 0: returnable=dir
	return returnable

### Basically, Healing and Affinities
func GroundingAndMeditation():
	# I lowkey wish life were this easy.
	meditation_timer.start()
	timesBreathCycled+=1
	var healing = 1;
	if timesBreathCycled>=4:
		if timesBreathCycled>=8: deepMeditation=true
		if timesBreathCycled>=13: deeperMeditation=true
		if elemental_area!=null:
			match (elemental_area.element):
				Utils.Element.NONE: pass
				Utils.Element.AIR: 
					affinities.Air+=1
					if deepMeditation:
						affinities.Throat+=1
						affinities.Heart+=1
						affinities.ThirdEye+=1
				Utils.Element.FIRE: 
					affinities.Fire+=1
					if deepMeditation:
						affinities.Sacral+=1
						# This is most likely broken and needs to be nerfed further
						Energetic_Twilight += .1 * (affinities.Sacral/4 + affinities.Spirit/8)
				Utils.Element.WATER: 
					affinities.Water+=1
					if deepMeditation: 
						affinities.Sacral+=1
						affinities.Heart+=1
				Utils.Element.EARTH: 
					affinities.Earth+=1
					if deepMeditation: 
						affinities.Root+=1
						affinities.SolarPlexus+=1
						affinities.Crown+=1 # Get it? Grounding. 
				Utils.Element.SPIRIT: 
					affinities.Spirit+1 # If you Reach this, you're probably in End Game, or the Very Start
				_: pass	
	if deeperMeditation: 
		healing += affinities.Heart/2 + affinities.SolarPlexus/2 + affinities.Spirit/4
		affinities.Spirit+=1
		deeperMeditation=false # Also nerf it.
	if deepMeditation: deepMeditation=false # To Nerf it.
	Health.x += healing

func _set_pcam_rotation(cam: PhantomCamera3D, dir: Vector2, isJoy: bool) -> void:
	if isClimbing: return
	var pcam_rotation_degrees: Vector3
	var sensitivity = joycam_sensitivity if isJoy else mouse_sensitivity
	pcam_rotation_degrees = cam.get_third_person_rotation_degrees()
	
	pcam_rotation_degrees.x -= dir.y * sensitivity
	pcam_rotation_degrees.y -= dir.x * sensitivity
	pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, -89, 50)
	pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, 0, 360)
	cam.set_third_person_rotation_degrees(pcam_rotation_degrees)
	aim=-pcam.global_basis.z

func PlayerHasItem(ItemName:String='') -> bool:
	for item in items:
		if item.Name == ItemName: return true
	return false

func PlayerActiveItemIs(ItemName:String='')->bool:
	if items[activeItem] != null:
		return items[activeItem].Name == ItemName
	return false


func _unhandled_input(event):
	if event is InputEventMouseMotion and pcam != null: _set_pcam_rotation(pcam, event.relative, false)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("mv_lt", "mv_rt", "mv_fw", "mv_bk")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if isClimbing:
		var rot = -(atan2(WallClimbCheck.get_collision_normal().z, WallClimbCheck.get_collision_normal().x)-PI/2)
		#CharacterHolder.rotation.y = rot # Doesnt work.
		#CharacterHolder.rotation.y = (atan2(-WallClimbCheck.get_collision_normal().z, -WallClimbCheck.get_collision_normal().x)-PI/2) # Doesnt work.
		mDir = direction.rotated(Vector3.UP, rot).normalized()
	else:
		mDir = direction.rotated(Vector3.UP, camera.rotation.y).normalized()
	
	
	if Input.is_action_just_pressed('item_fw'):
		activeItem+=1
		if activeItem>items.size()-1: activeItem=-1
	if Input.is_action_just_pressed('item_bk'):
		activeItem-=1
		print(activeItem)
		if activeItem < -1 : activeItem=items.size()-1
		#else: activeItem=-1
	
	# Attack????
	if Input.is_action_just_pressed("attack"): pass
	# Meditate/Ground
	if Input.is_action_just_pressed('ground'): 
		if meditating: meditating=false
		else:
			# If in an Elemental Area, only meditate IF you're allowed to.
			if elemental_area!=null: if elemental_area.canMeditate: meditating=true
			else: meditating=true # But it probably won't do much.
		if meditating: meditation_timer.start()
		else: 
			meditation_timer.stop()
			timesBreathCycled=0
	# Elemental Action
	if Input.is_action_just_pressed('action'):
		if isClimbing: isClimbing=false # Just drop.
		if elemental_area!=null:
			if CanClimb():
				print("Climbing!")
				isClimbing=!isClimbing
				#climbCam.look_at_targets.push_back(elemental_area)
				#setMainCamera(climbCam if isClimbing else null)
			match (elemental_area.element):
				Utils.Element.NONE: pass
				Utils.Element.AIR: 
					# if Pressing Down, Stop Floating
					if input_dir.y > .5: isFloating=false; print("Dropping!"); #Do an animation
				Utils.Element.FIRE: 
					if affinities.Fire>5: pass # Fire Attack?
				Utils.Element.WATER: pass
				Utils.Element.EARTH: pass
				Utils.Element.SPIRIT: pass
				_: pass
				
	# Handle jump.
	#TODO: Try Wall Climb Boost
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	# Finalize Movement
	if mDir and !meditating:
		if isClimbing: 
			velocity.x = mDir.x * base_speed + ElementalAreaInfluence().x
			velocity.y = -mDir.z * base_speed + ElementalAreaInfluence().y
		else:
			velocity.x = mDir.x * base_speed + ElementalAreaInfluence().x
			velocity.z = mDir.z * base_speed + ElementalAreaInfluence().z
			CharacterHolder.rotation.y = Vector2(velocity.z, velocity.x).angle()
	else:
		velocity.x = move_toward(velocity.x, 0, base_speed) + ElementalAreaInfluence().x
		velocity.z = move_toward(velocity.z, 0, base_speed) + ElementalAreaInfluence().z
		if isClimbing: velocity.y = move_toward(velocity.y, 0, base_speed) + ElementalAreaInfluence().y 
