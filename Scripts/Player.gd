extends KinematicBody2D

#====================================================
#====================================================
#===== Player.gd Explanation
#====================================================
#====================================================
#
#===== Introduction:
#
# Hello! NyxTheShield Here, creator of this engine.  This script is the one that controls 99% of the 
# character behaviour and his interaction with the enviroment. It was coded with modularity in mind, so 
# every character should extend this script. All of the player specific information, like controls, 
# player name (Used to load resources), etc Should be initialized when the character is instanced.
# 
# Most of the base Smash Bros. interactions are already handled, so this script should be edited only
# if you want to tune acdeleration formulas, global frame data (Like Ledge Roll Duration) or to create 
# custom behaviours for characters. 
#
#===== Important variables
#
# The engine is based around a state system, stored on the variable 'state' and a frame counter called 
# 'timer'. Everytime a state changes the timer is resetted to o (Manually with timer = 0). This allows
# to implement complex behaviour in a frame by frame or frame range basis. The other important elements
# are the RayCasts2D rays (2 For landing detection, RayL (left)  and RayR(right)), 2 for wall jump detection
# (ray_wallF and ray_wallB for front and back),and 2 for ledge grabbing, ledge_rayF and ledge rayB.
# They can be called freely with Godot 3 RayCast2D documentation (In the main loop code you will see
# heavy references tot he is_colliding() and get_collider() methods)
#
#===== Logic
#
# The _physics_process function is called every frame and follows this logic.
#
# Main Loop:
#	Check for Current State and Executes its behaviour
#   Moves Character
#   Check for Collisions with The Enviroment
#   Sets the Current Animation
#   Sets the Current Collision
#   Update the Raycasts Positions
#   Increment the Timer
#
#====================================================
#====================================================


#Defining Constants
#Stage
const WALL = 'Wall'
const FLOOR = 'Floor'
const PLATFORM = 'Platform'

#States
const STAND = 'stand'
const DASH= 'dash'
const RUN= 'run'
const CROUCH= 'crouch'
const LANDING= 'landing'
const jump_SQUAT= 'jump_squat'
const SHORT_HOP= 'short_hop'
const FULL_HOP= 'full_hop'
const SKID= 'skid'
const AIR= 'air'
const AIR_DODGE= 'air_dodge'
const FREE_FALL= 'free_fall'
const WALLJUMPLEFT= 'wall_jump_left'
const WALLJUMPRIGHT= 'wall_jump_right'
const LEDGE_CATCH= 'ledge_catch'
const LEDGE_HOLD = 'ledge_hold'
const LEDGE_ROLL_FAST = 'ledge_roll_fast'
const LEDGE_CLIMB_FAST = 'ledge_climb_fast'
const LEDGE_jump_FAST = 'ledge_jump_fast'
const LEDGE_ROLL_SLOW = 'ledge_climb_slow'
const LEDGE_CLIMB_SLOW = 'ledge_climb_slow'
const LEDGE_jump_SLOW = 'ledge_jump_slow'

#Controls
var up = ''
var down = ''
var left  = ''
var right  = ''
var attack  = ''
var special  = ''
var shield  = ''
var grab  = ''
var jump  = ''
var device  = ''

#On Ready Nodes
onready var sprite = get_node("Sprite_Node")
onready var rayL = get_node('Ground_RayL')
onready var rayR = get_node('Ground_RayR')
onready var ray_wallF = get_node('Wall_Jump_RayF')
onready var ray_wallB = get_node('Wall_Jump_RayB')
onready var ledge_rayF = get_node('Ledge_Grab_RayF')
onready var audio = get_node('/root/Audio_Manager')
onready var last_ledge = false

#Global Vars
export var name = 'ProtoChar'
export var state = AIR
export var velocity = Vector2(0,0)
export var facing  = 0
export var run_speed = 400
export var dash_speed = 480
export var max_air_speed = 250
export var fall_speed = 40
export var max_fall_speed = 900
export var air_accel = 21
export var traction = 20
export var jump_speed = 400
export var second_jump_speed = 800
export var next_jump = 0
export var max_air_jumps = 1
export var jumps = 0
export var fast_fall = false
export var landing_frames = 4
#Number of lag frames that will be added on landing
export var lag_frames = 0
#Number of Walljumps
export var wall_jump_counter = 0
#Wall Jump Decay Ratio
export var decay_ratio = 1.05 
#Modifier so Perfect Wavedash isnt obscene
export var perfect_wavedash_modifier = 1.11

#Enviroment Vars
var damage = 0
var timer = 0
var collision = false
var last_platform = false
var buffer_dodge = false
var regrab = 0
var down_buffer = 0

#Move Data
#Char Specific stuff
var dash_duration = 16
var jump_squat_duration = 5
var air_dodge_speed = 730

#sfx
var land_sfx = 0
var dash_sfx = 0
var double_jump_sfx = 0
var jump_sfx = 0

#controls
var keyboard = false
var joypad = true

#Node initializer
func _ready():
	set_physics_process(true)
	pass

#====================================================
#====================================================
#Engine Functions
#====================================================
#====================================================
func ____________________________________________________________________():
	#I am using this as a separator XD
	pass

#Set the Player Controls
func set_controls(array):
	up = array[0]
	down = array[1]
	left = array[2]
	right = array[3]
	attack = array[4]
	special = array[5]
	jump = array[6]
	shield = array[7]
	grab = array[8]
	device = array[9]
	keyboard = array[10]
	joypad = array[11]
	

func audio_path(string):
	return '/SFX/'+name+'/'+string
	

#====================================================
#====================================================
#Gameplay Functions
#====================================================
#====================================================
func _____________________________________________________________________():
	#another dumb separator
	pass
	
#Set the current active animation
func update_animation(state):
	if sprite.get_animation() != state:
		sprite.set_animation(state)
	pass

#Refresh the character's jumps	
func refresh_jumps():
	jumps = 0
	wall_jump_counter = 0

#Reset platforms and restores platform collisions
func reset_platform():
	last_platform = false
	self.set_collision_mask_bit(2,true)

#Reset Ledges
func reset_ledge():
	last_ledge.is_grabbed = false
	last_ledge = false
	
#Flips the character's sprite and raycasts
func turn(direction):
	var dir = 0
	if direction:
		dir = -1
	else:
		dir = 1
	sprite.set_flip_h(direction)
	ray_wallF.set_cast_to(Vector2(dir*abs(ray_wallF.get_cast_to().x),ray_wallF.get_cast_to().y))
	ray_wallB.set_cast_to(Vector2(-dir*abs(ray_wallB.get_cast_to().x),ray_wallB.get_cast_to().y))
	ledge_rayF.set_cast_to(Vector2(dir*abs(ledge_rayF.get_cast_to().x),ledge_rayF.get_cast_to().y))
	pass

#Code to drop through platforms
func drop_platform():
	if state_includes([RUN,CROUCH,DASH]) and down_buffer<10:
		if Input.is_action_pressed(down) and timer > 4 and (rayL.is_colliding() or rayR.is_colliding()):
				if rayL.is_colliding():
					var collider = rayL.get_collider ( )
					if collider.get_node('Type').text == PLATFORM:
						velocity.y = fall_speed
						state=AIR
						self.set_collision_mask_bit(2,false)

						
				elif rayR.is_colliding():
					var collider = rayR.get_collider ( )
					if collider.get_node('Type').text == PLATFORM:
						state=AIR
						self.set_collision_mask_bit(2,false)
						velocity.y = fall_speed

#Function to calculate the number of frames down has been held. Used to calculate buffered actions.
func down_buffer():
	if not Input.is_action_pressed(down):
		down_buffer = 0
	elif Input.is_action_pressed(down):
		down_buffer+=1
		
#Check if all of the states in the array match the current state. Return false in that case, true otherwise.
func state_exception(state_array):
	var each_state
	for each_state in state_array:
		if state == each_state:
			return false
	return true

#Check if any of the states in the array match the current state. Returns true in that case, false otherwise.
func state_includes(state_array):
	var each_state
	for each_state in state_array:
		if state == each_state:
			return true
	return false

#Set the Collision of the current state, based on their name, and disables every other collision object on the player.
func set_collision(new_state):
	for node in get_children():
		if node is CollisionShape2D:
			if node.get_name() != new_state+'_collision':
				node.disabled = true
				node.visible = false
			else:
				node.disabled = false
				node.visible = true

#Return the Shape2D of the current active collision. 
#Used to calculate the Width/Height of the character and Position they Ledge Grab, Wall Jump and Landing raycasts according
func get_collision():
	for node in get_children():
		if node is CollisionShape2D:
			if node.disabled == false:
				#print(node)
				return node

#Returns facing direction
func direction():
	if ledge_rayF.get_cast_to().x > 0:
		return 1
	else:
		return -1

#Udpates Landing, WallJumps and Ledgegrab rays according the new collision ray depending on their shape
func update_rays_positions():

	ledge_rayF.position.x = get_collision().position.x
	ledge_rayF.position.y = get_collision().position.y - get_collision().shape.get_extents().y+2
	
	ray_wallF.position.x = get_collision().position.x
	ray_wallF.position.y = get_collision().position.y
	ray_wallB.position.x = get_collision().position.x
	ray_wallB.position.y = get_collision().position.y
	
	rayL.position.x = get_collision().position.x - get_collision().shape.get_extents().x
	rayL.position.y = get_collision().position.y + get_collision().shape.get_extents().y-2
	
	rayR.position.x = get_collision().position.x + get_collision().shape.get_extents().x
	rayR.position.y = get_collision().position.y + get_collision().shape.get_extents().y-2
	
#Calls every state function to check which one is the current one (basically, a wrapper to clean the main loop)
func state_handler():
	#This is coded like this because in the future, we will need a case-switch kind 
	#of logic restriction to limit the number of state-changes per frame
	air_state()
	air_dodge_state()
	free_fall_state()
	stand_state()
	crouch_state()
	dash_state()
	run_state()
	skid_state()
	jump_squat_state()
	short_hop_state()
	full_hop_state()
	landing_state()
	wall_jump_state()
	ledge_catch_state()
	ledge_hold_state()
	ledge_climb_fast_state()
	ledge_roll_fast_state()
	ledge_jump_fast_state()
	pass

#Handles all the collision checking
func collision_handler():
	#Clamps Velocity to eliminate oscillating behaviour
	if abs(velocity.x) <= 20:
		velocity.x = 0
		
	#====================================================
	#====================================================
	#CORE:MOVE_AND_COLLIDE
	#====================================================
	#====================================================
	
	#Disables Platforms if I am holding down and falling
	if  state_includes([FREE_FALL,AIR]) and Input.is_action_pressed(down):
		self.set_collision_mask_bit(2,false)
	
	var velocity_x = Vector2(velocity.x,0)
	var velocity_y = Vector2(0,velocity.y)
	
	var collision_x = move_and_collide(velocity_x/50)
	var collision_y = move_and_collide(velocity_y/50)


	#====================================================
	#====================================================
	#COLLISION:LANDING
	#====================================================
	#====================================================
	if collision_y != null and (rayL.is_colliding() or rayR.is_colliding()):
		if state_includes([AIR,AIR_DODGE,FREE_FALL,WALLJUMPLEFT,WALLJUMPRIGHT]):
			if collision_y.collider.get_node('Type').text == FLOOR:
				state = LANDING
				timer = 0
				if velocity.y > 0:
					velocity.y = 0
				refresh_jumps()
				reset_platform()
				fast_fall = false
		
			if collision_y.collider.get_node('Type').text == PLATFORM :
				state = LANDING
				timer = 0
				if velocity.y > 0:
					velocity.y = 0
				refresh_jumps()
				reset_platform()
				fast_fall = false
	
	#Reenables Collision with platforms			
	elif velocity.y < 0:
		self.set_collision_mask_bit(2,true)
	
	elif velocity.y > 50:
		self.set_collision_mask_bit(2,true)

	#====================================================
	#====================================================
	#COLLISION:FALLING 
	#====================================================
	#====================================================

	elif not rayL.is_colliding() and not rayR.is_colliding():
		if not state_exception([RUN,STAND,CROUCH,DASH,LANDING,SKID]):
			#print(rayL.get_collider())
			#print('FALLING')
			state = AIR
			#Hack for weird relandings issues
			position.y+=20
			velocity.y = fall_speed
			velocity.x=velocity.x/3
			
	
	#====================================================
	#====================================================
	#COLLISION:WALL_jumpS
	#====================================================
	#====================================================
	if ray_wallF.is_colliding():
		var collider = ray_wallF.get_collider ( )
		if collider.get_node('Type').text == WALL:
			#print('MURO')
			if Input.is_action_just_pressed(left) and state_includes([AIR,WALLJUMPRIGHT ]) and ray_wallF.get_cast_to().x>0:
				state = WALLJUMPLEFT
				timer = 0
				velocity.x=0
				velocity.y=0
			elif Input.is_action_just_pressed(right) and state_includes([AIR,WALLJUMPLEFT]) and ray_wallF.get_cast_to().x<0:
				state = WALLJUMPRIGHT 
				timer = 0
				velocity.x=0
				velocity.y=0
				
	if ray_wallB.is_colliding():
		var collider = ray_wallB.get_collider ( )
		if collider.get_node('Type').text == WALL:
			if Input.is_action_just_pressed(right) and state_includes([AIR]) and ray_wallB.get_cast_to().x<0:
				state = WALLJUMPRIGHT
				timer = 0
				velocity.x=0
				velocity.y=0
			elif Input.is_action_just_pressed(left) and state_includes([AIR]) and ray_wallB.get_cast_to().x>0:
				state = WALLJUMPLEFT 
				timer = 0
				velocity.x=0
				velocity.y=0
	
	#====================================================
	#====================================================
	#COLLISION:LEDGES
	#====================================================
	#====================================================
	if ledge_rayF.is_colliding():
		var collider = ledge_rayF.get_collider ( )
		if collider.get_node('Type').text == 'LedgeL' and state_includes([AIR,FREE_FALL]) and velocity.y > 0 and not Input.is_action_pressed(down) and regrab == 0 and ledge_rayF.get_cast_to().x>0 and not collider.is_grabbed:
			state = LEDGE_CATCH
			audio.playsfx(audio_path('ledge'),0.7)
			timer = 0
			velocity.x=0
			velocity.y=0
			self.position.x = collider.position.x - get_collision().shape.get_extents().x
			self.position.y = collider.position.y + get_collision().shape.get_extents().y
			turn(false)
			refresh_jumps()
			fast_fall = false
			collider.is_grabbed = true
			last_ledge = collider
	
	if ledge_rayF.is_colliding():
		var collider = ledge_rayF.get_collider ( )
		if collider.get_node('Type').text == 'LedgeR' and state_includes([AIR,FREE_FALL]) and velocity.y > 0 and not Input.is_action_pressed(down) and regrab == 0 and ledge_rayF.get_cast_to().x<0 and not collider.is_grabbed:
			state = LEDGE_CATCH
			audio.playsfx(audio_path('ledge'),0.7)
			timer = 0
			velocity.x=0
			velocity.y=0
			self.position.x = collider.position.x + get_collision().shape.get_extents().x
			self.position.y = collider.position.y + get_collision().shape.get_extents().y
			turn(true)
			refresh_jumps()
			fast_fall = false
			collider.is_grabbed = true
			last_ledge = collider
			


#====================================================
#====================================================
#Physics Behaviour
#====================================================
#====================================================
func _________________________________________________________________():
	#I am using this as a separator XD
	pass
	
func air_state():
	if state == AIR:
		if Input.is_action_just_pressed(shield):
			state = AIR_DODGE
			timer = 0
			
		if velocity.y <  max_fall_speed:
			velocity.y +=fall_speed
		
		if Input.is_action_just_pressed(down) and velocity.y > 0 and not fast_fall :
			velocity.y = max_fall_speed
			fast_fall = true
			audio.playsfx(audio_path('fast_fall'),0.6)
			
		if fast_fall == true:
			velocity.y = max_fall_speed
			
		if Input.is_action_just_pressed(jump) and jumps < max_air_jumps:
			audio.playsfx(audio_path('double_jump'),0.74)
			fast_fall = false
			velocity.y = -second_jump_speed
			if Input.is_action_pressed(left):
				velocity.x = -max_air_speed
			elif Input.is_action_pressed(right):
				velocity.x = max_air_speed
			else:
				velocity.x = 0
				
			
			timer = 0
			jumps += 1
		
		if  abs(velocity.x) >=  abs(max_air_speed):
			if velocity.x > 0:
				if Input.is_action_pressed(left):
					velocity.x += -air_accel
				elif Input.is_action_pressed(right):
					velocity.x = velocity.x
			if velocity.x < 0:
				if Input.is_action_pressed(left):
					velocity.x = velocity.x
				elif Input.is_action_pressed(right):
					velocity.x += air_accel
					
				
		elif abs(velocity.x) < abs(max_air_speed):
			if Input.is_action_pressed(left):
				velocity.x += -air_accel
			if Input.is_action_pressed(right):
				velocity.x += air_accel				
		
		if not Input.is_action_pressed(left) and not Input.is_action_pressed(right):
			#print('Air Deaccel')
			if velocity.x < 0:
				velocity.x += air_accel / 10
			elif velocity.x > 0:
				velocity.x += -air_accel / 10
				
			
	pass
	
func air_dodge_state():
	if state == AIR_DODGE:	
		if timer == 1:
			velocity.x =0 
			velocity.y =0
			if keyboard:
				if (Input.is_action_pressed(left) or Input.is_action_just_released(left)) and not Input.is_action_pressed(right): 
					velocity.x = -air_dodge_speed
				if (Input.is_action_pressed(right) or Input.is_action_just_released(right)) and  not Input.is_action_pressed(left):
					velocity.x = air_dodge_speed
				if (Input.is_action_pressed(up) or Input.is_action_just_released(up)) and not Input.is_action_pressed(down):
					velocity.y = -air_dodge_speed
				if (Input.is_action_pressed(down) or Input.is_action_just_released(down)) and not Input.is_action_pressed(up):
					velocity.y = air_dodge_speed
				
			else:
				var deadzone = (Input.get_joy_axis(device, 0) in range(-0.2,0.2) ) and (Input.get_joy_axis(device, 1) in range(-0.2,0.2) )
				var direction = Vector2(Input.get_joy_axis(device, 0), Input.get_joy_axis(device, 1))
				print(direction)
				if deadzone:
					direction = Vector2(0,0)
			
				velocity = air_dodge_speed*direction.normalized()
				
			if abs(velocity.x)==abs(velocity.y):
				velocity.x = velocity.x/1.25
				velocity.y = velocity.y/1.25
			
		if timer >= 4 and timer <= 10:
			if timer == 5:
				audio.playsfx(audio_path('air_dodge'),0.74)
			velocity.x = velocity.x/1.1
			velocity.y = velocity.y/1.1
		if timer >=10 and timer < 20:		
			velocity.x = 0
			velocity.y = 0
		elif timer == 20:
			state = FREE_FALL
			lag_frames = 8
			timer = 0
	pass

func free_fall_state():
	if state==FREE_FALL:
		if velocity.y <  max_fall_speed:
			velocity.y +=fall_speed
		
		if Input.is_action_just_pressed(down) and velocity.y > 0 and not fast_fall :
			velocity.y = max_fall_speed
			fast_fall = true
		
		if  abs(velocity.x) >  abs(max_air_speed):
			if velocity.x > 0:
				if Input.is_action_pressed(left):
					velocity.x += -air_accel
				elif Input.is_action_pressed(right):
					velocity.x = velocity.x
			if velocity.x < 0:
				if Input.is_action_pressed(left):
					velocity.x = velocity.x
				elif Input.is_action_pressed(right):
					velocity.x += air_accel
					
				
		elif abs(velocity.x) <= abs(max_air_speed):
			if Input.is_action_pressed(left):
				velocity.x += -air_accel
			if Input.is_action_pressed(right):
				velocity.x += air_accel				
		
		if not Input.is_action_pressed(left) and not Input.is_action_pressed(right):
			#print('Air Deaccel')
			if velocity.x < 0:
				velocity.x += air_accel / 10
			elif velocity.x > 0:
				velocity.x += -air_accel / 10
	pass

func crouch_state():
	if state == CROUCH:
		if Input.is_action_just_pressed(jump):
			timer = 0
			state = jump_SQUAT 
					
		if Input.is_action_just_released(down):
			state = STAND
			timer = 0
		elif velocity.x > 0:
			if velocity.x>run_speed:		
				velocity.x =  velocity.x - traction*2
			else:	
				velocity.x =  velocity.x - traction
		elif velocity.x < 0:
			if abs(velocity.x)>run_speed:		
				velocity.x =  velocity.x + traction*3
			else:	
				velocity.x =  velocity.x + traction
	pass
	
func stand_state():
	if state == STAND:
		if Input.is_action_just_pressed(down):
			state = CROUCH
			#play_sfx(land_sfx)
			timer = 0
		if Input.is_action_just_pressed(jump):
			timer = 0
			state = jump_SQUAT
			
			
		if Input.is_action_pressed(left):
			velocity.x = -run_speed
			state = DASH
			audio.playsfx(audio_path('dash'),1.1)
			
			turn(true)
			timer = 0
			
		elif Input.is_action_pressed(right):
			velocity.x = run_speed
			state = DASH
			audio.playsfx(audio_path('dash'),1.1)
			turn(false)
			timer = 0
			
		
		if velocity.x > 0 and state == STAND:
			velocity.x =  velocity.x - traction*2
		elif velocity.x < 0 and state == STAND:
			velocity.x =  velocity.x + traction*2
	pass

func short_hop_state():
	if state == SHORT_HOP:
		velocity.y = -jump_speed*1.5
		state = AIR
		timer = 0
		audio.playsfx(audio_path(jump),0.6)
		if Input.is_action_just_pressed(shield):
			state = AIR_DODGE
			timer = 0
	pass

func full_hop_state():
				
	if state == FULL_HOP:
		velocity.y = -jump_speed*2
		state = AIR
		timer = 0
		audio.playsfx(audio_path(jump),0.6)
		if Input.is_action_just_pressed(shield):
			state = AIR_DODGE
			timer = 0
	pass

func jump_squat_state():
	if state ==jump_SQUAT:
		if timer < jump_squat_duration - 1:
			if not buffer_dodge:
				buffer_dodge = Input.is_action_just_pressed(shield)
		if timer == jump_squat_duration - 1:
			#play_sfx(jump_sfx)
			
			if (Input.is_action_just_pressed(shield) or buffer_dodge) and (Input.is_action_pressed(left) or Input.is_action_pressed(right)):
				if Input.is_action_pressed(left):
					velocity.x = -air_dodge_speed/perfect_wavedash_modifier
				if Input.is_action_pressed(right):
					velocity.x = air_dodge_speed/perfect_wavedash_modifier
				state = LANDING
				lag_frames = 6
				timer = 0
				
				
			elif not Input.is_action_pressed(jump):
				state = SHORT_HOP
				
			else:
				state = FULL_HOP

			
			buffer_dodge = false
	pass

func run_state():
	if state == RUN:
		if Input.is_action_just_pressed(jump):
			timer = 0
			state = jump_SQUAT 
		
		if Input.is_action_just_pressed(down):
			state = CROUCH
			timer=0
		
		if Input.is_action_pressed(left):
			if velocity.x <= 0:
				velocity.x = -run_speed
				turn(true)
			else:
				state = SKID
				timer = 0	
		elif Input.is_action_pressed(right):
			if velocity.x >= 0:
				velocity.x = run_speed
				turn(false)
			else:
				state = SKID
				timer = 0
		else:
			if velocity.x > 0:				
				velocity.x =  velocity.x - traction
			elif velocity.x < 0:
				velocity.x =  velocity.x + traction
			else:
				state = STAND
				timer = 0	
	drop_platform()	

func dash_state():
	#Attempt to fix weird relanding behaviour
#	if state == DASH:
#		if Input.is_action_just_pressed(jump):
#				state = jump_SQUAT 
#				timer = 0
#
#		elif Input.is_action_just_pressed(left):
#			if velocity.x > 0:
#				audio.playsfx(audio_path('dash'),1.1)
#				timer = 0
#				velocity.x = -dash_speed
#				turn(true)
#
#		elif Input.is_action_just_pressed(right):
#			if velocity.x < 0:
#				audio.playsfx(audio_path('dash'),1.1)
#				timer = 0
#				velocity.x = dash_speed
#				turn(false)
#
#		elif Input.is_action_pressed(left) and not Input.is_action_just_pressed(left):
#				if timer == dash_duration:
#					state = RUN
#					timer = 0
#				turn(true)
#
#		elif Input.is_action_pressed(right) and not Input.is_action_just_pressed(right):
#				if timer == dash_duration:
#					state = RUN
#					timer = 0
#				turn(false)
#
#		if timer == dash_duration:
#			velocity.x -= velocity.x
#			state=STAND

					
	if state == DASH:
		if Input.is_action_just_pressed(jump):
			state = jump_SQUAT 
			timer = 0

		elif Input.is_action_pressed(left):
			if velocity.x > 0:
				audio.playsfx(audio_path('dash'),1.1)
				timer = 0
			velocity.x = -dash_speed
			if timer <= dash_duration:
				state = DASH
				#play_sfx(dash_sfx)
			else:
				state = RUN
				timer = 0
			turn(true)

		elif Input.is_action_pressed(right):
			if velocity.x < 0:
				audio.playsfx(audio_path('dash'),1.1)
				timer = 0
			velocity.x = dash_speed
			if timer <= dash_duration:
				state = DASH
				#play_sfx(dash_sfx)
			else:
				state = RUN
				timer = 0
			turn(false)

		else:
			if velocity.x > 0:
				velocity.x =  velocity.x - traction
			elif velocity.x < 0:
				velocity.x =  velocity.x + traction
			elif velocity.x == 0:
				if state != jump_SQUAT:
					state = STAND
	
	pass

func skid_state():
	if state == SKID:
		if Input.is_action_just_pressed(jump):
			timer = 0
			state = jump_SQUAT 
		
		if velocity.x > 0:
			turn(true)
			velocity.x =  velocity.x - traction
		elif velocity.x < 0:
			turn(false)
			velocity.x =  velocity.x + traction
		else:
			if not Input.is_action_pressed(left) and not Input.is_action_pressed(right):
				state = STAND
			else:
				state = RUN
			timer = 0
	pass

func landing_state():
	if state ==LANDING:		
		if timer <= landing_frames + lag_frames:
			if timer == 1:
				audio.playsfx(audio_path('land'),1.1)
			#print('Landing')
			
			if velocity.x > 0:
				velocity.x =  velocity.x - traction*2
			elif velocity.x < 0:
				velocity.x =  velocity.x + traction*2
		else:
			if Input.is_action_pressed(down):
				state=CROUCH
			else:
				state =STAND
			lag_frames = 0

func wall_jump_state():
	if state ==WALLJUMPLEFT:
		if timer == 1:
			velocity.x = 0
			velocity.y = 0
		if timer == 5:
			turn(true)
			
			wall_jump_counter +=1
			#print(wall_jump_counter)
			var wall_jump_decay = pow(decay_ratio,wall_jump_counter)
			velocity.x = -jump_speed*2
			velocity.y = -jump_speed/(wall_jump_decay)
			
		elif timer >=6 and timer < 12:
			velocity.x=velocity.x/1.2
		elif timer>12 and timer <44:
			if velocity.y <  max_fall_speed:
				velocity.y +=fall_speed
		elif timer >= 44:
			state =AIR
			timer=0	
		if timer>5:
			if Input.is_action_just_pressed(shield):
				state=AIR_DODGE
				timer = 0
			elif Input.is_action_just_pressed(jump) and jumps < max_air_jumps:
				fast_fall = false
				velocity.y = -second_jump_speed
				
				##play_sfx(double_jump_sfx)
				if Input.is_action_just_pressed(left):
					velocity.x = -max_air_speed
				elif Input.is_action_just_pressed(right):
					velocity.x = max_air_speed
				else:
					velocity.x = 0
				timer = 0
				jumps += 1
				state=AIR

	
	if state ==WALLJUMPRIGHT:
		if timer == 1:
			velocity.x = 0
			velocity.y = 0
			
		if timer == 5:
			wall_jump_counter +=1
			#print(wall_jump_counter)
			turn(false)
			var wall_jump_decay = pow(decay_ratio,wall_jump_counter)
			velocity.x = jump_speed*2
			velocity.y = -jump_speed/(wall_jump_decay)
		elif timer >=6 and timer < 12:
			velocity.x=velocity.x/1.2
		elif timer>12 and timer <44:
			if velocity.y <  max_fall_speed:
				velocity.y +=fall_speed
		elif timer >= 44:
			state =AIR
			timer=0	
		if timer>5:
			if Input.is_action_just_pressed(shield):
				state=AIR_DODGE
				timer = 0
			elif Input.is_action_just_pressed(jump) and jumps < max_air_jumps:
				fast_fall = false
				velocity.y = -second_jump_speed
				
				##play_sfx(double_jump_sfx)
				if Input.is_action_just_pressed(left):
					velocity.x = -max_air_speed
				elif Input.is_action_just_pressed(right):
					velocity.x = max_air_speed
				else:
					velocity.x = 0
				timer = 0
				jumps += 1
				state=AIR

func ledge_catch_state():
	if state==LEDGE_CATCH:
		if timer > 7:
			state = LEDGE_HOLD
			timer = 0
	pass

func ledge_hold_state():
	if state == LEDGE_HOLD:
		if Input.is_action_just_pressed(down):
			state = AIR
			fast_fall = true
			regrab = 30
			reset_ledge()
			#Hack, should be Air dodge collision shape extents.y and halved
			#Feels EXTREMELY nice like this tho
			self.position.y += -25
		#Facing Right
		elif ledge_rayF.get_cast_to().x>0:
			if Input.is_action_just_pressed(left):
				velocity.x = air_accel/2
				state = AIR
				regrab = 30
				reset_ledge()
				#Same as above
				self.position.y += -25
			
			elif Input.is_action_just_pressed(right):
				timer=0
				if damage < 100:
					state = LEDGE_CLIMB_FAST
				else:
					state = LEDGE_CLIMB_SLOW
			
			elif Input.is_action_just_pressed(shield):
				timer=0
				if damage < 100:
					state = LEDGE_ROLL_FAST
				else:
					state = LEDGE_ROLL_SLOW
					
			elif Input.is_action_just_pressed(jump):
				timer = 0
				if damage <100:
					state = LEDGE_jump_FAST
				else:
					state = LEDGE_jump_SLOW
				
					
		#Facing Left
		elif ledge_rayF.get_cast_to().x<0:
			if Input.is_action_just_pressed(right):
				velocity.x = -air_accel/2
				state = AIR
				regrab = 30
				reset_ledge()
				#Same
				self.position.y += -25
				
			elif Input.is_action_just_pressed(left):
				timer = 0
				if damage < 100:
					state = LEDGE_CLIMB_FAST
				else:
					state = LEDGE_CLIMB_SLOW

			elif Input.is_action_just_pressed(shield):
				timer = 0
				if damage < 100:
					state = LEDGE_ROLL_FAST
				else:
					state = LEDGE_CLIMB_SLOW
			elif Input.is_action_just_pressed(jump):
				timer = 0
				if damage <100:
					state = LEDGE_jump_FAST
				else:
					state = LEDGE_jump_SLOW
	pass

func ledge_climb_fast_state():
	if state==LEDGE_CLIMB_FAST:
		if timer == 10:
			position.y -=20
		if timer == 20:
			position.y -=20
		
		if timer == 30:
			position.y -=20	
		
		if timer == 40:
			position.y -=20
			position.x +=50*direction()
			
		if timer==47:
			velocity.y=0
			velocity.x=0
			move_and_collide(Vector2(direction()*20,50))
		if timer==50:
			reset_ledge()
			state=STAND

func ledge_roll_fast_state():
	if state==LEDGE_ROLL_FAST:
		if timer == 10:
			position.y -=20
		if timer == 20:
			position.y -=20
		
		if timer == 25:
			position.y -=20	
		
		if timer == 35:
			position.y -=20
			position.x +=30*direction()
		
		if timer >36 and timer<46:
			position.x +=10*direction()
	
		if timer==47:
			move_and_collide(Vector2(direction()*20,50))
		if timer==50:
			velocity.y=0
			velocity.x=0
			state=STAND
			reset_ledge()

func ledge_jump_fast_state():
	if state==LEDGE_jump_FAST:	
		if timer == 10:
			reset_ledge()
			position.y -=20
		if timer == 15:
			position.y -=20
		
		if timer == 20:
			position.y -=20	
			velocity.y -=jump_speed*2.5
			velocity.x +=220*direction()
		elif timer > 20 and timer <40:
			velocity.y+=fall_speed
		
		if timer==40:
			state=AIR
				

#====================================================
#====================================================
#Attack Behaviour
#====================================================
#====================================================
func ___________________________________________________________________():
	#Dumbness
	pass
	
#Base Functions. Override and Implement them on the player itself.
func nair():
	pass

func fair():
	pass
	
func bair():
	pass

func uair():
	pass

func dair():
	pass

func utilt():
	pass

func ftilt():
	pass

func dtilt():
	pass

func usmash():
	pass
	
func fsmash():
	pass

func dsmash():
	pass

func jab():
	pass

func grab():
	pass
	
func __________________________________________________________________():
	#Another dumb separator
	#Godot should have something like this
	pass
	
#====================================================
#====================================================
#STATE:MAIN ENGINE
#====================================================
#====================================================
func _physics_process(delta):
	
	state_handler()
	collision_handler()
	#Updates the ledge regrab timer
	if regrab > 0:
		regrab-=1
	#Updates everything for the next frame
	timer += round(delta*60)
	update_animation(state)
	down_buffer()
	set_collision(state)
	update_rays_positions()
	
	#debug
	if Input.is_action_just_pressed('ui_select'):
		position =  Vector2(640,360)
	pass
