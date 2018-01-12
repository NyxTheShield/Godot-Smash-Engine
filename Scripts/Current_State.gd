extends Label

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var player = get_node('/root/PlayerInit/Player')

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func _process(delta):
	get_node("State").text = "Current State:  "+str(player.state)
	get_node("Frame").text = "Frame:  "+str(player.timer)
	get_node("Speed").text = "Speed:  "+str(player.velocity)
	get_node("Position").text = "Position:  "+str(player.position)
	get_node("Rays").text = "Wall Jump Rays:  F"+str(player.ray_wallF.get_cast_to()) + '      B:'+str(player.ray_wallB.get_cast_to())
	pass
