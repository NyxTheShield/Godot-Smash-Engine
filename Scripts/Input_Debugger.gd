extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var inputs = ['ui_left','ui_right','ui_up','ui_down','shield','jump']

func _ready():
	set_process_input(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _input(ev):
	print(ev)
	#set_process_input(false)
	pass
	
#func _process(delta):#
#	if Input.is_action_just_pressed('ui_left'):
#		set_process_input(true)
		
		
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
