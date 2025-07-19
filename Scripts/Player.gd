class_name Player extends RPGActor


@export_subgroup("Settings")
@export var mouse_sensitivity: float = 0.25
@export var joycam_sensitivity: float = 1.25

@onready var camera: Camera3D = $Camera3D
@onready var meditation_timer: Timer = $MeditationTimer
@onready var WallClimbCheck: RayCast3D = $Mesh/WallClimbCheck
@onready var pcam: PhantomCamera3D = $ThirdPartyCam
@onready var CharacterHolder: Node3D = $Mesh
@onready var HUD: PlayerHUD = $PlayerHUD

@export_category("Speed Settings")
@export var swim_speed = 4.0
@export var climb_speed = 4.5
@export var jump_force = 4.5

var jDir: Vector3 = Vector3.ZERO
var mDir: Vector3 = Vector3.ZERO
var cJoy: Vector2 = Vector2.ZERO
var aim: Vector3 = Vector3.ZERO
var action_dir_mod: Vector3 = Vector3.ZERO
var stamina_drain:float = 0
var input_dir: Vector2 = Vector2.ZERO

var jumped: bool = false
var isMeditating: bool = false
var timesBreathCycled: int = 0
var deepMeditation: bool = false
var deeperMeditation: bool = false
var isFloating: bool = false;
var isClimbing: bool = false

var elemental_area: ElementalArea = null
var nearest_interactable: InteractableArea = null

@export var items: Array[Item] = []
var activeItem: int = 0 # TODO: ItemIndex ffs

func _init(): pass

func CanClimb() -> bool:
	if elemental_area != null:
		if elemental_area is ClimbableArea:
			return WallClimbCheck.is_colliding()
	return false

func isSwimming()->bool:
	if elemental_area!=null:
		return !is_on_floor() and elemental_area.element==Utils.Element.WATER
	else: return false


func _process(_delta):
	cJoy = Input.get_vector("cam_lt", "cam_rt", "cam_up", "cam_dw")
	if cJoy: _set_pcam_rotation(pcam, cJoy, true)
	#super(_delta)
	
func _physics_process(delta):
	if not is_on_floor():
		Stamina.x -= StaminaDrain(delta)
		if isFloating :
			if PlayerActiveItemIs('Wing Cloak') and Stamina.x>0:
				#print(velocity.y)
				if velocity.y<0 and elemental_area==null:
					velocity += (get_gravity() / 2) * delta
				elif elemental_area!=null:
					if elemental_area.element==Utils.Element.AIR:  # Who gives a crap about gravity -TF2 Scout
						if velocity.y>0: pass
						if velocity.y<0: 
							velocity.y=1
						#velocity += (get_gravity() / 16) * delta #idk figured it would be worth the try
				else: velocity += (get_gravity() / 1.5) * delta
			else: velocity += get_gravity() * delta
		elif isClimbing and Stamina.x>0: pass #Remain 
		else: velocity+=get_gravity()*delta
	
	if is_on_floor():
		if Stamina.x < Stamina.y: Stamina.x += delta
		if isFloating: isFloating=false

	if !WallClimbCheck.is_colliding() and isClimbing: isClimbing=false
	# Finalize Movement -- Moved from Unhandled Input
	if mDir and !isMeditating:
		if isClimbing:
			velocity.x = mDir.x * climb_speed   + ElementalAreaInfluence().x
			velocity.y = - mDir.z * climb_speed + ElementalAreaInfluence().y
			if jumped: velocity.y+=climb_speed
			# Stamina.x -= velocity.length() / 64
		else:
			velocity.x = mDir.x * base_speed + ElementalAreaInfluence().x
			velocity.z = mDir.z * base_speed + ElementalAreaInfluence().z
			CharacterHolder.rotation.y = Vector2(velocity.z, velocity.x).angle()
			# if isSwimming(): Stamina.x -= velocity.length() / 8
	else:
		velocity.x = move_toward(velocity.x, 0, base_speed) + ElementalAreaInfluence().x
		velocity.z = move_toward(velocity.z, 0, base_speed) + ElementalAreaInfluence().z
		if isClimbing: velocity.y = move_toward(velocity.y, 0, base_speed) + ElementalAreaInfluence().y

	move_and_slide()
	

### Add Extra Speed to Movement based on Elemental Area
func ElementalAreaInfluence() -> Vector3:
	var returnable = Vector3.ZERO
	if elemental_area != null:
		var dir = elemental_area.direction
		match elemental_area.element:
			Utils.Element.AIR: 
				dir *= (elemental_area.multiplier + (.1 * affinities.Air))
				if PlayerActiveItemIs('Wing Cloak'): dir *= (Vector3.UP*(float(affinities.Air)/2))
					
				#else: dir *= (elemental_area.multiplier + (.1 * extra))
			Utils.Element.FIRE: 
				dir *= (elemental_area.multiplier + (.1 * affinities.Fire))
			Utils.Element.WATER:
				# TODO: Add Canoe
				dir *= (elemental_area.multiplier + (.1 * affinities.Water))
				if PlayerActiveItemIs('Canoe'): dir *= (float(affinities.Air)/2)
			Utils.Element.EARTH: 
				dir *= (elemental_area.multiplier + (.1 * affinities.Earth))
				if elemental_area is ClimbableArea:
					if PlayerActiveItemIs('Glove'): dir *= (float(affinities.Earth)/2)
					if (elemental_area as ClimbableArea).isWet:
						dir.y -= (elemental_area as ClimbableArea).slipperiness / (float(affinities.Earth) / 2 + float(affinities.Root) / 2)
				#extra = affinities.Earth # TODO: Add Grippy Hands or Boots
			 # Dunno why but sure... Is this how we teleport?
			# Is this how we can project outside our bodies?
			# But what happens when we don't have a body??? 
			Utils.Element.SPIRIT: 
				#extra = affinities.Spirit
				dir *= (elemental_area.multiplier + (.1 * affinities.Air))
				
		
		if dir.length() > 0: returnable = dir
	return returnable

### Basically, Healing and Affinities
func GroundingAndMeditation():
	# I lowkey wish life were this easy.
	meditation_timer.start()
	timesBreathCycled += 1
	var healing = 1;
	if timesBreathCycled >= 4:
		if timesBreathCycled >= 8: deepMeditation = true
		if timesBreathCycled >= 13: deeperMeditation = true
		if elemental_area != null:
			match (elemental_area.element):
				Utils.Element.NONE: pass
				Utils.Element.AIR:
					affinities.Air += 1
					if deepMeditation:
						affinities.Throat += 1
						affinities.Heart += 1
						affinities.ThirdEye += 1
				Utils.Element.FIRE:
					affinities.Fire += 1
					if deepMeditation:
						affinities.Sacral += 1
						# This is most likely broken and needs to be nerfed further
						Energetic_Twilight += .1 * (float(affinities.Sacral) / 4 + float(affinities.Spirit) / 8)
				Utils.Element.WATER:
					affinities.Water += 1
					if deepMeditation:
						affinities.Sacral += 1
						affinities.Heart += 1
				Utils.Element.EARTH:
					affinities.Earth += 1
					if deepMeditation:
						affinities.Root += 1
						affinities.SolarPlexus += 1
						affinities.Crown += 1 # Get it? Grounding.
				Utils.Element.SPIRIT:
					affinities.Spirit += 1 # If you Reach this, you're probably in End Game, or the Very Start
				_: pass
	if deeperMeditation:
		healing += float(affinities.Heart) / 2 + float(affinities.SolarPlexus) / 2 + float(affinities.Spirit) / 4
		affinities.Spirit += 1
		deeperMeditation = false # Also nerf it.
	if deepMeditation: deepMeditation = false # To Nerf it.
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
	aim = - pcam.global_basis.z

func PlayerHasItem(ItemName: String = '') -> bool:
	for item in items:
		if item.Name == ItemName: return true
	return false

func PlayerActiveItemIs(ItemName: String = '') -> bool:
	if items[activeItem] != null:
		return items[activeItem].Name == ItemName
	return false

func StaminaDrain(delta:float)->float:
	var calculated:float = 1
	if is_on_floor(): return 0
	else:
		if isClimbing: # Earth Element
			calculated = 2+affinities.Earth+(float(affinities.SolarPlexus)/2 + float(affinities.Root)/2)
			if PlayerActiveItemIs('Glove'): calculated+=8
			print((velocity.length()/calculated)*delta)
			return (velocity.length()/calculated)*delta
		if isSwimming(): # Water
			calculated = 4 + (affinities.Water+(float(affinities.Sacral)/2+float(affinities.SolarPlexus)/2)+float(affinities.Root)/4)
			if PlayerActiveItemIs('Canoe'): calculated+=8
			return (velocity.length() / calculated)*delta
		if PlayerActiveItemIs('Wing Cloak') and isFloating:
			return delta/4
		return 0

func _unhandled_input(event):
	jumped = false
	if event is InputEventMouseMotion and pcam != null: _set_pcam_rotation(pcam, event.relative, false)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("mv_lt", "mv_rt", "mv_fw", "mv_bk")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if isClimbing:
		var rot = - (atan2(WallClimbCheck.get_collision_normal().z, WallClimbCheck.get_collision_normal().x) - PI / 2)
		#CharacterHolder.rotation.y = rot # Doesnt work.
		#CharacterHolder.rotation.y = (atan2(-WallClimbCheck.get_collision_normal().z, -WallClimbCheck.get_collision_normal().x)-PI/2) # Doesnt work.
		mDir = direction.rotated(Vector3.UP, rot).normalized()
	else:
		mDir = direction.rotated(Vector3.UP, camera.rotation.y).normalized()
	
	# Item Scrolling
	if Input.is_action_just_pressed('item_fw'):
		activeItem += 1
		if activeItem > items.size() - 1: activeItem = -1
	if Input.is_action_just_pressed('item_bk'):
		activeItem -= 1
		print(activeItem)
		if activeItem < -1: activeItem = items.size() - 1
		#else: activeItem=-1
	
	# Attack is now Interact
	if Input.is_action_just_pressed("attack"): 
		if nearest_interactable !=null:
			if nearest_interactable.isPerson: pass
			elif !nearest_interactable.isPerson and nearest_interactable.item!=null: pass
	# Meditate/Ground
	if Input.is_action_just_pressed('ground'):
		if isMeditating: isMeditating = false
		else:
			# If in an Elemental Area, only meditate IF you're allowed to.
			if elemental_area != null: if elemental_area.canMeditate: isMeditating = true
			else: isMeditating = true # But it probably won't do much.
		if isMeditating: meditation_timer.start()
		else:
			meditation_timer.stop()
			timesBreathCycled = 0
	# Elemental Action
	if Input.is_action_just_pressed('action'):
		if PlayerActiveItemIs('Wing Cloak') and Stamina.x > 0: 
			isFloating = !isFloating
			print(isFloating)
		if elemental_area != null:
			match (elemental_area.element):
				Utils.Element.NONE: pass
				Utils.Element.AIR: pass
					# if Pressing Down, Stop Floating
					#if input_dir.y > .5: isFloating = false; print("Dropping!"); # Do an animation
				Utils.Element.FIRE:
					if affinities.Fire > 5: pass # What do the Fire do tho??
				Utils.Element.WATER:
					if !is_on_floor():
						if Stamina.x > swim_speed / 8:
							if PlayerActiveItemIs('Canoe'): action_dir_mod = velocity * swim_speed
							else: action_dir_mod = velocity * (swim_speed / 8)
					pass
				Utils.Element.EARTH:
					print(CanClimb())
					if CanClimb():
						print("Climbing!")
						isClimbing = !isClimbing
						#climbCam.look_at_targets.push_back(elemental_area)
						#setMainCamera(climbCam if isClimbing else null)
				Utils.Element.SPIRIT: pass
				_: pass
				
	# Handle jump.
	#TODO: Try Wall Climb Boost
	if Input.is_action_just_pressed("jump"):
		if isClimbing and Stamina.x > climb_speed / 2:
			# velocity.y += climb_speed
			jumped=true
			Stamina.x -= climb_speed / 4
		else:
			velocity.y = jump_force
