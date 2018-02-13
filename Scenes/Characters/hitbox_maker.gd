tool
extends Path2D

export var width = 0
export var height = 0
export var damage = 0
export var angle = 0
export var base_kb = 0
export var kb_scaling  = 0
export var duration = 0
export (String,'normal', 'electric', 'darkness','fire','ice','slash','grounding') var type
export var id = 0
export var hitlag_modifier = 1
export (String,'Export', 'Reset') var Export_Code setget update
export (String, MULTILINE) var code = ''

func _ready():
	set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	pass

func update(value):
	if Engine.is_editor_hint():
		Export_Code = value
		
		if value == 'Export':
			var points = []
			var aux_points = '['
			for i in range(self.curve.get_point_count ( )):
				aux_points+= 'Vector2'+str(self.curve.get_point_position(i))
				if i != self.curve.get_point_count ( ) -1:
					aux_points+=','
			aux_points += ']'
			code = "create_hitbox(%s,%s,%s,%s,%s,%s,%s,'%s',str(%s),%s,%s)" % [width, height, damage,angle,base_kb, kb_scaling,duration,type,id,aux_points,hitlag_modifier]
		else:
			code = ' '
			self.curve.clear_points()