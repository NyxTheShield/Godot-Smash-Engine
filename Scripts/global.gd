extends Node

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
const JUMP_SQUAT= 'jump_squat'
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
const LEDGE_JUMP_FAST = 'ledge_jump_fast'
const LEDGE_ROLL_SLOW = 'ledge_climb_slow'
const LEDGE_CLIMB_SLOW = 'ledge_climb_slow'
const LEDGE_JUMP_SLOW = 'ledge_jump_slow'
const NAIR = 'nair'
const FAIR = 'fair'
const UAIR = 'uair'
const BAIR =  'bair'
const DAIR =  'dair'
const TUMBLE =  'tumble'
var current_scene = null
var p1_device = null
#Device,AxisX,AxisY,Keyboard


func _ready():
	var root = get_tree().get_root()
	p1_device = {'device':0,'axisx':0,'axisy':0,'keyboard':false,'joypad':true}
	current_scene = root.get_child( root.get_child_count() -1 )
		

func goto_scene(path):

    # This function will usually be called from a signal callback,
    # or some other function from the running scene.
    # Deleting the current scene at this point might be
    # a bad idea, because it may be inside of a callback or function of it.
    # The worst case will be a crash or unexpected behavior.

    # The way around this is deferring the load to a later time, when
    # it is ensured that no code from the current scene is running:

    call_deferred("_deferred_goto_scene",path)


func _deferred_goto_scene(path):

    # Immediately free the current scene,
    # there is no risk here.
    current_scene.free()

    # Load new scene
    var s = ResourceLoader.load(path)

    # Instance the new scene
    current_scene = s.instance()

    # Add it to the active scene, as child of root
    get_tree().get_root().add_child(current_scene)

    # optional, to make it compatible with the SceneTree.change_scene() API
    get_tree().set_current_scene( current_scene )