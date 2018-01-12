extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var player = get_parent().get_parent().get_node('Player')
var inputs = ['shield','jump','attack','special','grab']
var nodes = ['R','Y','A','B','Z']
var modulated =[false,false,false,false,false]
var stick = ['ui_left','ui_right','ui_up','ui_down']
var stick_pressed = [false,false,false,false]
var aux = 13
var stick_values = [[-aux,0],[aux,0],[0,-aux],[0,aux]]
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	var i = 0
	for i in range(len(inputs)):
		if Input.is_action_pressed(inputs[i]):
			if not modulated[i]:
				var node = get_node(nodes[i])
				#print(node.get_modulate() )
				var r = node.get_modulate() [0]
				var g = node.get_modulate() [1]
				var b = node.get_modulate() [2]
				var a = node.get_modulate() [3]
				node.set_modulate(Color(r,g,b,a-0.50))
				modulated[i] = true
				
		elif not Input.is_action_pressed(inputs[i]):
			if modulated[i]:
				var node = get_node(nodes[i])
				#print(node.get_modulate() )
				var r = node.get_modulate() [0]
				var g = node.get_modulate() [1]
				var b = node.get_modulate() [2]
				var a = node.get_modulate() [3]
				node.set_modulate(Color(r,g,b,a+0.50)) 
				modulated[i] = false
				
	for i in range(len(stick)):
		if player.keyboard:
			if Input.is_action_pressed(stick[i]):
				if not stick_pressed[i]:
					get_node('Stick').position = get_node('Stick').position + Vector2(stick_values[i][0],stick_values[i][1])
					stick_pressed[i]= true
			if not Input.is_action_pressed(stick[i]):
				if stick_pressed[i]:
					get_node('Stick').position = get_node('Stick').position - Vector2(stick_values[i][0],stick_values[i][1])
					stick_pressed[i]= false
		else:
			var direction = Vector2(Input.get_joy_axis(3, 0), Input.get_joy_axis(3, 1))
			#print(direction)
			get_node('Stick').position = direction.normalized()*15 - Vector2(30,0)
	pass
