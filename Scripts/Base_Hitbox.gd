extends Area2D

var width = 500
var height = 50
var damage = 50
var angle = 90
var base_kb = 100
var kb_scaling  = 2
var duration = 1500
var hitlag_modifier = 1
var type  = 'normal'
onready var hitbox = get_node('hitbox_collision')
onready var path = Path2D.new().get_curve()
var timer  = 0.0
var id = 'test_group'
var player_list = []
var points = []

func disable_multi_hitbox(body):
	if not (body in player_list):
		player_list.append(body)

func on_body_enter(body):
	if not (body in player_list):
		get_tree().call_group_flags(2,id, "disable_multi_hitbox",body)
		print(damage)
		
func _ready():
	hitbox.shape = RectangleShape2D.new()
	set_physics_process(false)
	pass

#Set the hitbox parameters and enables it
func set_parameters(w,h,d,a,b_kb,kb_s,dur,t,i,p,hit=1,parent=get_parent()):
	self.position = Vector2(0,0)
	player_list.append(parent)
	width = w
	height = h
	damage = d
	angle = a
	base_kb = b_kb
	kb_scaling = kb_s
	duration = dur
	type = t
	id = parent.name+i
	for point in p:
		path.add_point(point)
	hitlag_modifier = hit
	add_to_group(id)
	update_extends()
	connect( "body_entered", self, "on_body_enter")
	set_physics_process(true)

#Update the hitbox's extents
func update_extends():
	hitbox.shape.extents = Vector2(width,height)

#Updates the frame counter, moves and deletes the hitbox 
func _physics_process(delta):
	if timer<duration:
		timer += 1
	elif timer == duration:
		free()
		return
	#Move the CollisionShape along the path, using timer/duration.
	if path.get_point_count ( ) >0:
		var lenght_percentage = path.get_baked_length ()*(timer/duration)
		hitbox.position = path.interpolate_baked(lenght_percentage)
	
	if get_parent().state_exception(['nair','uair','dair','fair','bair']):#,DTILT,UTILT,FTILT,DSMASH,USMASH,FSMASH,UPB,DOWNB,SIDE,NEUTRALB,LEDGEATTACK_SLOW,LEDGEATTACK_FAST,JAB]):
		free()
		return
	
	for body in player_list:
		get_tree().call_group(id, "disable_multi_hitbox",body)

	pass
