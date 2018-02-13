extends Control

# Note for the reader:
#
# This demo conveniently uses the same names for actions and for the container nodes
# that hold each remapping button. This allow to get back to the button based simply
# on the name of the corresponding action, but it might not be so simple in your project.
#
# A better approach for large-scale input remapping might be to do the connections between
# buttons and wait_for_input through the code, passing as arguments both the name of the
# action and the node, e.g.:
# button.connect("pressed", self, "wait_for_input", [ button, action ])

# Constants
const INPUT_ACTIONS = [ "ui_up", "ui_down", "ui_left", "ui_right", "jump", 'shield', 'attack', 'special', 'grab', 'cstick_up','cstick_down','cstick_left','cstick_right' ]
const CONFIG_FILE = "res://input.cfg"

# Member variables
var action # To register the action the UI is currently handling
var button # Button node corresponding to the above action
var deadzone = 0.3
var deadzone_flag = false
# Load/save input mapping to a config file
# Changes done while testing the demo will be persistent, saved to CONFIG_FILE

func load_config():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err: # Assuming that file is missing, generate default config
		for action_name in INPUT_ACTIONS:
			var action_list = InputMap.get_action_list(action_name)
			# There could be multiple actions in the list, but we save the first one by default
			var new_event = InputEventKey.new()
			if len(action_list) > 0:
				new_event.scancode = action_list[0].scancode
			config.set_value("input", action_name, new_event)
		config.save(CONFIG_FILE)
	else: # ConfigFile was properly loaded, initialize InputMap
		for action_name in config.get_section_keys("input"):
			var value = config.get_value("input", action_name)
			for old_event in InputMap.get_action_list(action_name):
				InputMap.action_erase_event(action_name, old_event)
			InputMap.action_add_event(action_name, value)
			update_device(value)
			# Create a new event object based on the saved scancode

func save_to_config(section, key, value):
	"""Helper function to redefine a parameter in the settings file"""
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err:
		print("Error code when loading config file: ", err)
	else:
		#Saves the InputEvent object directly to the file
		config.set_value(section, key, value)
		config.save(CONFIG_FILE)


# Input management
func wait_for_input(action_bind):
	action = action_bind
	# See note at the beginning of the script
	button = get_node("bindings").get_node(action).get_node("Button")
	get_node("contextual_help").text = "Press a key to assign to the '" + action + "' action."
	set_process_input(true)

func update_device(event):
	get_node('/root/global').p1_device['device'] = event.device
	if event is InputEventKey:
		get_node('/root/global').p1_device['keyboard'] = true
		get_node('/root/global').p1_device['joypad'] = false
	else:
		get_node('/root/global').p1_device['keyboard'] = false
		get_node('/root/global').p1_device['joypad'] = true
	

func _input(event):
	# Handle the first pressed key
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) > deadzone:
			deadzone_flag = true
	if event is InputEventKey or event is InputEventJoypadButton or deadzone_flag:
		# Register the event as handled and stop polling
		get_tree().set_input_as_handled()
		set_process_input(false)
		# Reinitialise the contextual help label
		get_node("contextual_help").text = "Click a key binding to reassign it."
		if not event.is_action("ui_cancel"):
			# Display the string corresponding to the pressed key
			if event is InputEventKey:
				update_device(event)
				button.text = OS.get_scancode_string(event.scancode)
			if event is InputEventJoypadButton:
				update_device(event)
				
				button.text = 'Button '+ str(event.button_index)
			if event is InputEventJoypadMotion:
				update_device(event)
				var symbol
				if event.axis_value > 0:
					symbol = '+'
				else:
					symbol ='-'
				button.text = 'Axis '+str(event.axis)+':'+symbol

			# Start by removing previously key binding(s)
			for old_event in InputMap.get_action_list(action):
				InputMap.action_erase_event(action, old_event)
			# Add the new key binding
			InputMap.action_add_event(action, event)
			save_to_config("input", action, event)
		deadzone_flag = false


func _ready():
	# Load config if existing, if not it will be generated with default values
	load_config()
	# Initialise each button with the default key binding from InputMap
	for action in INPUT_ACTIONS:
		# We assume that the key binding that we want is the first one (0), if there are several
		var button = get_node("bindings").get_node(action).get_node("Button")
		if len(InputMap.get_action_list(action)) > 0:
			var input_event = InputMap.get_action_list(action)[0]
			# See note at the beginning of the script
			if input_event is InputEventKey:
					button.text = OS.get_scancode_string(input_event.scancode)
			if input_event is InputEventJoypadButton:
					button.text = str(input_event.button_index)
			if input_event is InputEventJoypadMotion:
					var symbol
					if input_event.axis_value > 0:
						symbol = '+'
					else:
						symbol ='-'
					button.text = 'Axis '+str(input_event.axis)+':'+symbol
		else:
			button.text =  'Empty'
		button.connect("pressed", self, "wait_for_input", [action])
	
	# Do not start processing input until a button is pressed
	set_process_input(false)
