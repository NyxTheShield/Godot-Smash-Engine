extends Camera2D

func _ready():
	pass

func _process(delta):
	self.position = (get_parent().get_node('Player').position + get_parent().get_node('Stage').get_node('Center').position)/2