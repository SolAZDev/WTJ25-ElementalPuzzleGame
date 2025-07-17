class_name Player extends RPGActor

var SPEED = 5.0
var JUMP_VELOCITY = 4.5
@export_subgroup("Settings")
@export var mouse_sensitivity: float = 0.25
@export var joycam_sensitivity: float = 1.25

@onready var camera: Camera3D = $Camera3D
@onready var pcam: PhantomCamera3D = $PhantomCamera3D
@onready var meditation_timer: Timer = $MeditationTimer

var jDir:Vector3 = Vector3.ZERO
var mDir: Vector3 = Vector3.ZERO
var cJoy: Vector3 = Vector3.ZERO
var aim:Vector3 = Vector3.ZERO

var meditating: bool = false
var timesBreathCycled: int = 0
var deepMeditation:bool=false
var deeperMeditation:bool=false
var isFloating: bool = false;

var elemental_area:ElementalArea = null

func _init():
	pass
	
func _process(_delta):
	var cJoy = Input.get_vector("cam_lt","cam_rt","cam_up","cam_dw")
	if cJoy: _set_pcam_rotation(pcam, cJoy, true)
	super(_delta)
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and !isFloating:
		velocity += get_gravity() * delta
	move_and_slide()

### Add Extra Speed to Movement based on Elemental Area
func ElementalAreaInfluence()->Vector3:
	var returnable = Vector3.ZERO
	if elemental_area!=null:
		var extra: float = 0
		match elemental_area.element:
			Utils.Element.AIR: extra=Air
			Utils.Element.FIRE: extra=Fire
			Utils.Element.WATER: extra=Water
			Utils.Element.EARTH: extra=Earth
			 # Dunno why but sure... Is this how we teleport?
			# Is this how we can project outside our bodies?
			# But what happens when we don't have a body??? 
			Utils.Element.SPIRIT: extra=Spirit
		var dir = elemental_area.direction * (elemental_area.multiplier + (.1*extra))
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
					Air+=1
					if deepMeditation:
						Throat+=1
						Heart+=1
						ThirdEye+=1
				Utils.Element.FIRE: 
					Fire+=1
					if deepMeditation:
						Sacral+=1
						# This is most likely broken and needs to be nerfed further
						Energetic_Twilight += .1 * (Sacral/4 + Spirit/8)
				Utils.Element.WATER: 
					Water+=1
					if deepMeditation: 
						Sacral+=1
						Heart+=1
				Utils.Element.EARTH: 
					Earth+=1
					if deepMeditation: 
						Root+=1
						SolarPlexus+=1
						Crown+=1 # Get it? Grounding. 
				Utils.Element.SPIRIT: 
					Spirit+1 # If you Reach this, you're probably in End Game, or the Very Start
				_: pass	
	if deeperMeditation: 
		healing += Heart/2 + SolarPlexus/2 + Spirit/4
		Spirit+=1
		deeperMeditation=false # Also nerf it.
	if deepMeditation: deepMeditation=false # To Nerf it.
	Health.x += healing

func _unhandled_input(event):
	if event is InputEventMouseMotion and pcam != null: _set_pcam_rotation(pcam, event.relative, false)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("mv_lt", "mv_rt", "mv_fw", "mv_bk")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var mDir = direction.rotated(Vector3.UP, camera.rotation.y).normalized()
	
	# Attack????
	if Input.is_action_just_pressed("attack"): pass
	# Meditate/Ground
	if Input.is_action_just_pressed('ground'): 
		if meditating: meditating=false
		else:
			if elemental_area!=null: if elemental_area.canMeditate: meditating
			else: meditating=true # But it probably won't do much.
	# Elemental Action
	if Input.is_action_just_pressed('action'):
		if elemental_area!=null:
			match (elemental_area.element):
				Utils.Element.NONE: pass
				Utils.Element.AIR: 
					# if Pressing Down, Stop Floating
					if input_dir.y > .5: isFloating=false; print("Dropping!"); #Do an animation
				Utils.Element.FIRE: 
					if Fire>5: pass # Fire Attack?
				Utils.Element.WATER: pass
				Utils.Element.EARTH: pass
				Utils.Element.SPIRIT: pass
				_: pass
				
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Finalize Movement
	if mDir and !meditating:
		velocity.x = mDir.x * SPEED + ElementalAreaInfluence().x
		velocity.z = mDir.z * SPEED + ElementalAreaInfluence().z
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED) + ElementalAreaInfluence().x
		velocity.z = move_toward(velocity.z, 0, SPEED) + ElementalAreaInfluence().z


func _set_pcam_rotation(cam: PhantomCamera3D, dir: Vector2, isJoy: bool) -> void:
	var pcam_rotation_degrees: Vector3
	var sensitivity = joycam_sensitivity if isJoy else mouse_sensitivity
	pcam_rotation_degrees = cam.get_third_person_rotation_degrees()
	
	pcam_rotation_degrees.x -= dir.y * sensitivity
	pcam_rotation_degrees.y -= dir.x * sensitivity
	pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, -89, 50)
	pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, 0, 360)
	cam.set_third_person_rotation_degrees(pcam_rotation_degrees)
	aim=-pcam.global_basis.z
