extends ParallaxBackground

export var speed = Vector2(0,0)
var o = Vector2(0,0)

func _ready():
	set_process(true)
	pass

func _process(delta):
	o+=speed
	set_scroll_offset(o)
