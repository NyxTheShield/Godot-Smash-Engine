extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var p1_controls = ['ui_up','ui_down','ui_left','ui_right','attack','special','jump','shield','grab',get_node('/root/global').p1_device['device'],get_node('/root/global').p1_device['keyboard'],get_node('/root/global').p1_device['joypad']]
#var p2_controls = ['p2_up','p2_down','p2_left','p2_right','p2_attack','p2_special','p2_jump','p2_shield','p2_grab',0]

func _ready():
	print()
	var stage =  load('res://Scenes/Battlefield.tscn')
	var camera = load('res://Scenes/Camera.tscn')
	var audio = load('res://Scenes/Audio_Manager.tscn')
	var player = load('res://Scenes/Base_Player.tscn')
	var hud = load('res://Scenes/Debug_HUD.tscn')
	var node = player.instance()
	#var node2 = player.instance()
	node.set_controls(p1_controls)
	#node2.set_controls(p2_controls)
	add_child(stage.instance())
	add_child(audio.instance())
	add_child(camera.instance())
	add_child(node)
	add_child(hud.instance())
	#add_child(node2)
	
	# Called every time the node is added to the scene.
	# Initialization here
	set_process_input(true)
	pass

func _input(event):
	#print(event.device)
	pass
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
