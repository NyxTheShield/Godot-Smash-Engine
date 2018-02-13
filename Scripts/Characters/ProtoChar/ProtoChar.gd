extends 'res://Scripts/Player.gd'

func _ready():
	set_physics_process(true)
	#Char Data
	char_name = 'ProtoChar'
	state = AIR
	velocity = Vector2(0,0)
	run_speed = 470
	dash_speed = 540
	max_air_speed = 250
	fall_speed = 40
	max_fall_speed = 900
	air_accel = 21
	traction = 20
	jump_speed = 900
	short_hop_speed = 430*1.5
	second_jump_speed = 900
	next_jump = 0
	max_air_jumps = 1
	jumps = 0
	fast_fall = false
	landing_frames = 4
	dash_duration = 16
	jump_squat_duration = 5
	air_dodge_speed = 850

func nair():
	if timer == 1:
		lag_frames = 5
		create_hitbox(15,15,8,45,0,20,15,'normal',str(10),[Vector2(9.153259, 12.96106),Vector2(18.016663, 2.883484)],1)
		
	if timer == 15:
		create_hitbox(15,15,8,45,0,20,15,'normal',str(11),[Vector2(4.053741, 15.025162),Vector2(13.64566, 11.382645)],1)
		
	if timer == 44:
		state = AIR
		timer = 0
		lag_frames = 0
		
func uair():
	if timer == 1:
		create_hitbox(15,15,8,45,0,20,15,'normal',str(1),[Vector2(26.151581, 17.453491),Vector2(30.886841, -0.273346),Vector2(29.065552, -12.536438),Vector2(20.566406, -22.978271),Vector2(10.488831, -29.777618),Vector2(-4.566833, -31.598862),Vector2(-18.651184, -26.256531),Vector2(-28.971619, -17.878769),Vector2(-33.099762, -8.651093)],1)
		lag_frames = 6
	if timer == 33:
		state = AIR 
		timer = 0
		lag_frames = 0
		
func bair():
	if timer == 1:
		lag_frames = 6
	if timer == 4:
		create_hitbox(15,15,12,50,0,20,15,'normal',str(1),[Vector2(-18.894012, -1.12326)],1)
		
	if timer == 29:
		state = AIR
		timer = 0
		lag_frames = 0
		
func dair():

	if timer == 10:
		
		lag_frames = 5
		create_hitbox(18,25,12,270,0,20,1500,'normal',str(1),[Vector2(2.839569, 13.568146)],1)
		create_hitbox(15,10,20,270,0,20,1600,'fire',str(1),[Vector2(3.446655, -6.951279)],1)
	if timer == 38:
		state = AIR 
		timer = 0
		lag_frames = 0

func fair():
	if timer == 1:
		lag_frames = 7
	if timer == 36:
		state = AIR 
		timer = 0
		lag_frames = 0