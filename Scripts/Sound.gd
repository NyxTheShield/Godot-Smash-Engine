extends Node

#####################################
# All-Purpose Audio Management Node
#
# This node handles playback of both music and sound effects by managing an arbitrary number of AudioStreamPlayer nodes.
# To use it, simply call the play(), playsfx() or playmusic() functions.
# Place all your .wav and .ogg files into the AUDIO_DIR specified just below, by default "res://audio/"
# 
# playsfx() and playmusic() only serve as shortcut functions to play(), for easier parameter management.
# All 3 return the SoundChannel object that is playing the requested sound, in case you want to do something to those.
#
# For specific instructions on the play* functions' parameters and how to use them, see their definitions below.
####################################

# The directory that holds the audio files.
const AUDIO_DIR = "res://Sound/"
# Maximum distance you can still hear AudioStreamPlayer2Ds from. 2000 is default.
const MAX_DISTANCE = 2000
# Default volume attenuation in decibels (0 means no change).
const DEFAULT_VOLUME = 0
# Volume attenuation in deibels at which there is no sound.
const MUTE_VOLUME = -80

# Current global volume multipliers.
var master_volume_mult = 1.0
var sfx_volume_mult = 1.0
var music_volume_mult = 1.0

# The ID of the Master bus, for muting.
var master_bus_id = 1

# Types of fades, fading in and fading out.
enum crossfadeTypes {CROSSFADE_IN = 0, CROSSFADE_OUT = 1}

# References to the AudioStreamPlayer children, for ID purposes.
var music_channels = []

# Currently active player on each layer (used for crossfades).
var active_on_layer = {}

# Tween node to animate the volume for crossfades.
var tween = Tween.new()

class SoundChannel:
	# The audio node this wraps around.
	var player
	# The tween node used for crossfades.
	var tween
	# FuncRef that returns the currently active channels on each layer.
	var layer_func
	
	# The base volume multiplier, per-channel. Between 0 and 1.
	var base_volume = 1.0
	# The type volume multipler, eg. SFX or Music. Between 0 and 1.
	var type_volume = 1.0
	# The crossfading volume multiplier that is animated by tween. Between 0 and 1.
	var crossfade_volume = 1.0
	# The product of the above three. If this changes on frame by frame basis, then the player's volume_db is adjusted.
	var total_volume = 1.0
	
	# The crossfade time in seconds. 0 means instant transitions.
	var crossfade = 0.0
	
	# The name of the track currently being played.
	var track_name #string
	# The type of channel, whether SFX or Song. Used by the global volume control.
	var is_sfx #bool
	# Whether the channel is currently active or not
	var is_active = false
	# Whether the channel is a 2D positional player
	var is_positional #bool
	# 2D node to track the position of for positional audio.
	var tracked_node = null
	
	func _init(_is_positional, _tween, _layer_func):
		""" We have to know whether it's positional or not at init as that creates the required node.
		    We also have to be given a Tween node for crossfades. This can be shared between all of them!
		"""
		is_positional = _is_positional
		if _is_positional:
			player = AudioStreamPlayer2D.new()
		else:
			player = AudioStreamPlayer.new()
		player.connect("finished", self, "silence")
		
		tween = _tween
		layer_func = _layer_func
	
	func update():
		""" Moves the connected AudioStreamPlayer2D to the tracked node's position and adjusts volume if it changed.
		"""
		if is_positional and typeof(tracked_node) != TYPE_NIL:
			player.set_global_position(tracked_node.get_global_position())
		
		var new_volume = type_volume * base_volume * crossfade_volume
		if new_volume != total_volume:
			total_volume = new_volume
			player.set_volume_db(get_multiplied_volume(total_volume))
	
	
	func crossfade(_crosstype):
		""" Fades the given channel in or out using the tween child.
		    If it's fading out, it will also silence the channel once it has finished.
		"""
		# Remove silencing tween, since any sort of crossfade means that that has to be readjusted.
		tween.remove(self, "silence")
		
		# Duration is the base crossfade duration multiplied by the inverse crossfade_volume, as that indicates progress so far.
		var duration = crossfade
		
		match _crosstype:
			# Fade in the song
			CROSSFADE_IN:
				# If there is a crossfade duration, start tweening the current volume towards 1.0.
				duration *= (1.0 - crossfade_volume)
				if duration != 0:
					tween.remove(self, "set_crossfade_volume")
					tween.interpolate_method(self, "set_crossfade_volume", crossfade_volume, 1.0, duration, Tween.TRANS_EXPO, Tween.EASE_OUT)
				else:
					set_crossfade_volume(1.0)
				
				# Start playing either way
				if not player.is_playing():
					player.play()
					is_active = true
			
			# Fade out the song
			CROSSFADE_OUT:
				# If there is a crossfade duration, start tweening the current crossfade volume towards 0.0.
				duration *= crossfade_volume
				if duration != 0:
					tween.remove(self, "set_crossfade_volume")
					tween.interpolate_method(self, "set_crossfade_volume", crossfade_volume, 0.0, duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
					tween.interpolate_deferred_callback(self, duration, "silence")
				else:
					silence()
	
	func set_active_on_layer(_layer):
		""" Sets the channel as the dominant one on the given layer and fades out the currently active channel if there was one.
		    Returns true if it muted another channel and false if it did not mute anything.
		"""
		var result = false
		var layers = layer_func.call_func()
		
		if layers.has(_layer):
			# If the currently active channel on the layer already is this one, return
			if layers[_layer] == self:
				return result
			# If it's a different channel, fade the old one out or make it stop and return the desired one to normal volume
			else:
				layers[_layer].crossfade(CROSSFADE_OUT)
				result = true
		
		layers[_layer] = self
		return result
	
	func set_base_volume(_base_volume_mult):
		""" Sets the base multiplier for the channel, set on .play().
		"""
		base_volume = _base_volume_mult
	
	func set_type_volume(_type_volume_mult):
		""" Sets the volume multiplier for the sound type, eg. SFX or Music.
		"""
		type_volume = _type_volume_mult
	
	func set_crossfade_volume(_crossfade_volume_mult):
		""" Sets the volume multiplier for the crossfade tween.
		"""
		crossfade_volume = _crossfade_volume_mult
	
	
	func get_multiplied_volume(_volume_mult):
		""" Returns a volume based on the DEFAULT_VOLUME multiplied by _volume_mult.
		    Since DEFAULT_VOLUME can be 0 or negative, this needs to take into account MUTE_VOLUME.
		"""
		return MUTE_VOLUME + (abs(DEFAULT_VOLUME - MUTE_VOLUME) * _volume_mult)
	
	func silence():
		""" Stops the player and kills all of this channel's attributes, without freeing it, leaving it for reuse.
		"""
		player.stop()
		is_active = false
		if is_positional:
			tracked_node = null


func _ready():
	# Setup tween.
	add_child(tween, true)
	tween.start()
	
	# Find master bus
	for bus_id in AudioServer.get_bus_count():
		if AudioServer.get_bus_name(bus_id) == "Master":
			master_bus_id = bus_id
			break
	
	# Prepare a few audio nodes to avoid loading hiccups.
	add_channel(false)
	add_channel(false)
	add_channel(false)
	add_channel(true)
	add_channel(true)
	add_channel(true)

func _process(delta):
	""" Update all sound channels.
	"""
	for channel in music_channels:
		channel.update()


func playsfx(_track_name, _volume_mult = 1.5, _positional = false, _let_finish = false, _random_pitch = null, _bus = "Master"):
	""" play() alias with simplified parameters for SFX playback. Never uses a layer.
	    You can absolutely play sound effects using play() itself, this is merely a helper.
	      string _track_name: The name of the track to play. Loads .wav and .ogg files from the AUDIO_DIR directory.
	      float _volume_mult: The volume for this track, between 0 and 1.
	      Node _positional: If anything other than false, a 2D player will be used. If it should be 2D, pass the node or a path to the node that should be tracked.
	      bool _let_finish: If this is true, the given track cannot be played/updated unless there are no others of its type playing.
	      float _random_pitch: If this is anything other than null, the sound effect will have its pitch changed randomly by that amount.
	      string _bus: The audio bus to play the track back on. Different mastering effects!
	"""
	return play(_track_name, _volume_mult, _positional, true, _let_finish, _random_pitch, _bus, false, null, 0.0, false, 0)

func playmusic(_track_name, _layer = "main", _volume_mult = 1.0, _positional = false, _crossfade_duration = 0.0, _copy_time = false, _bus = "Master"):
	""" play() alias with simplified parameters for music playback. Always uses a layer.
	    You can absolutely play music tracks using play() itself, this is merely a helper.
	      string _track_name: The name of the track to play. Loads .wav and .ogg files from the AUDIO_DIR directory.
	      float _volume_mult: The volume for this track, between 0 and 1.
	      Node _positional: If anything other than false, a 2D player will be used. If it should be 2D, pass the node or a path to the node that should be tracked.
	      int _layer: Determines which songs to shut off when it begins playing, namely all currently playing songs on its own layer.
	      bool _crossfade_duration: How long the song takes to finish kicking in. 0.0 means instantly and is default.
	      bool _copy_time: If true, the song will copy the time of the song currently playing on its layer and play from there.
	      string _bus: The audio bus to play the track back on. Different mastering effects!
	"""
	return play(_track_name, _volume_mult, _positional, false, false, null, _bus, true, _layer, _crossfade_duration, _copy_time, 1)

func play(_track_name, _volume_mult = 1.0, _positional = false, _is_sfx = true, _let_finish = false, _random_pitch = null, _bus = "Master", _uses_layer = false, _layer = "main", _crossfade_duration = 0.0, _copy_time = false, _loop = 0):
	""" Play a track of the given name. Finding a channel is done automatically.
	      string _track_name: The name of the track to play. Loads .wav and .ogg files from the AUDIO_DIR directory.
	      float _volume_mult: The volume for this track, between 0 and 1.
	      bool _is_sfx: If true, the song will be affected by global SFX volume changes, else it will be affected by global music volume changes.
	      Node _positional: If anything other than false, a 2D player will be used. If it should be 2D, pass the node or a path to the node that should be tracked.
	      bool _let_finish: If this is true, the given track cannot be played/updated unless there are no others of its type playing.
	      float _random_pitch: If this is anything other than null, the sound effect will have its pitch changed randomly by that amount.
	      string _bus: The audio bus to play the track back on. Different mastering effects!
	      bool _uses_layer: If this is true, the song will shut off all other songs playing on its given layer.
	                    Sound effects don't want to be unique. Subsequent parameters are only used if _uses_layer is true.
	        int _layer: Determines which songs to shut off when it begins playing, namely all currently playing songs on its own layer.
	        bool _crossfade_duration: How long the song takes to finish kicking in. 0 means instantly and is default.
	        bool _copy_time: If true, the song will copy the time of the song currently playing on its layer and play from there.
	
	    Returns the channel that the track is playing on, for whatever use that may have.
	"""
	
	# Is set to true whenever we shut down another player in this function
	var faded = false
	
	# If the song is already playing, either ignore this call or update the current focus
	var existing_channel = find_channel_playing_track(_track_name)
	if typeof(existing_channel) != TYPE_BOOL and _random_pitch == null:
		# If we want to let the track finish before playing it again, simply return the channel.
		if _let_finish:
			return existing_channel
		
		# If the song is already playing, refresh it to active status, update the bus and return
		if _uses_layer:
			existing_channel.player.set_bus(_bus)
			# Set it as active, and if we shut off another song in the process, fade back in,
			# since we had to have been fading out to be active while not being active.
			faded = existing_channel.set_active_on_layer(_layer)
			if faded:
				existing_channel.crossfade(CROSSFADE_IN)
			return existing_channel
	
	# Set up positional tracking
	var node_to_track = null
	var use_positional = false
	if typeof(_positional) == TYPE_NODE_PATH or typeof(_positional) == TYPE_STRING:
		node_to_track = get_node(_positional)
	elif typeof(_positional) == TYPE_BOOL:
		use_positional = _positional
	else:
		node_to_track = _positional
		use_positional = true
	
	# Prepare common bindings
	var channel = get_idle_channel(use_positional, _track_name)
	channel.player.set_bus(_bus)
	if use_positional:
		channel.tracked_node = node_to_track
	
	# If the found channel already had our song loaded, do not bother load()ing it up again
	if channel.track_name != _track_name:
		
		var f = File.new()
		var new_audiostream
		var wav_path = "%s%s.wav" % [AUDIO_DIR, _track_name]
		if f.file_exists(wav_path):
			new_audiostream = load(wav_path)
			new_audiostream.loop_mode = _loop
		else:
			var ogg_path = "%s%s.ogg" % [AUDIO_DIR, _track_name]
			if f.file_exists(ogg_path):
				new_audiostream = load(ogg_path)
				new_audiostream.loop = _loop
			else:
				print("There is no audio file named %s" % _track_name)
				
		
		if _random_pitch == null:
			channel.player.set_stream(new_audiostream)
		else:
			var random_stream = AudioStreamRandomPitch.new()
			random_stream.set_audio_stream(new_audiostream)
			random_stream.set_random_pitch(_random_pitch)
			channel.player.set_stream(random_stream)
	
	# Grab the layer and channel
	var layer = null
	if _uses_layer:
		layer = _layer
	
	
	# Keep track of all of this channel's properties
	channel.track_name = _track_name
	channel.crossfade = _crossfade_duration
	channel.is_sfx = _is_sfx
	channel.base_volume = float(_volume_mult)
	
	if _is_sfx:
		channel.type_volume = sfx_volume_mult
	else:
		channel.type_volume = music_volume_mult
	
	# Set this channel as active on the layer
	var playback_position = 0
	if _uses_layer:
		# If we want to copy time, copy time
		if _copy_time and active_on_layer.has(_layer) and active_on_layer[_layer] != channel:
			playback_position = active_on_layer[_layer].player.get_playback_position()
		
		# Set channel as active
		faded = channel.set_active_on_layer(_layer)
	
	# Start playing the track. If we faded out another track, start this one's volume at 0 as well.
	if faded:
		channel.set_crossfade_volume(0)
	channel.crossfade(CROSSFADE_IN)
	
	if faded and playback_position != 0:
		channel.player.seek(playback_position)
	
	return channel


func set_master_volume(_volume_mult = 1.0):
	""" Sets the master volume multiplier, as a float where 1.0 is normal volume.
	"""
	master_volume_mult = max(0.0, _volume_mult)
	AudioServer.set_bus_volume_db(0, get_multiplied_volume(master_volume_mult))
	if _volume_mult <= 0.0:
		set_mute(true)
	else:
		set_mute(false)

func set_sfx_volume(_volume_mult = 1.0):
	""" Set sfx volume multiplier, as a float where 1.0 is normal volume.
	"""
	# Set the multiplier for all subsequent SFX that will be played through playsfx().
	sfx_volume_mult = max(0.0, _volume_mult)
	
	for channel in music_channels:
		if channel.is_active and channel.is_sfx:
			channel.set_type_volume(sfx_volume_mult)

func set_song_volume(_volume_mult = 1.0):
	""" Set music volume multiplier, as a float where 1.0 is normal volume.
	"""
	# Set the multiplier for all subsequent SFX that will be played through playmusic().
	music_volume_mult = max(0.0, _volume_mult)
	
	for channel in music_channels:
		if channel.is_active and not channel.is_sfx:
			channel.set_type_volume(music_volume_mult)

func set_mute(_muted = true):
	""" Mutes or unmutes the master bus.
	"""
	AudioServer.set_bus_mute(master_bus_id, _muted)

func autopsy(_active_only = false):
	""" Prints out a complete set of information about all players.
	    If _active_only is true, only active ones are displayed.
	"""
	# Print global info.
	print("----------------------")
	print("Master | Music |   SFX")
	print("  %3d%% |  %3d%% |  %3d%%" % [master_volume_mult * 100, music_volume_mult * 100, sfx_volume_mult * 100])
	print("----------------------")
	
	# Print for each channel.
	for channel in music_channels:
		if (not _active_only) or channel.is_active:
			var player_type = "AudioStreamPlayer2D" if channel.is_positional else "AudioStreamPlayer"
			var track_name = channel.track_name if channel.is_active else "nothing"
			var sound_type = "SFX" if channel.is_sfx else "song"
			var volume = round(channel.base_volume*channel.crossfade_volume*100)
			var crossfade_duration = channel.crossfade
			
			print("%s is %s." % [player_type, "inactive" if track_name == "nothing" else "playing the %s %s at %s%% volume%s" % [sound_type, track_name, volume, "" if crossfade_duration == 0 else ", crossfade duration: %s seconds" % [crossfade_duration]]])
	print("----------------------")


func get_idle_channel(_positional = false, _preferred_track = null):
	""" Returns a channel ID for a player that is not busy right now and the right player type (2D or not).
	    Will prefer to use one that already has the given track loaded.
	    Creates a new one if none is idle.
	"""
	var preferred_channel = false
	var empty_channel = false
	var any_channel = false
	
	# Scan channels for free ones, immediately pick one that has our track preloaded
	for channel in filter_idle_channels():
		if channel.is_positional == _positional:
			any_channel = channel
			if channel.track_name == _preferred_track:
				preferred_channel = channel
				break
	
	
	if not any_channel:
		# If there are no idle audio players right now, create a new one.
		return add_channel(_positional)
	elif not preferred_channel:
		# If there are idle player but none that have the song loaded, take any of them.
		return any_channel
	else:
		# If a preloaded player exists, use it!
		return preferred_channel

func add_channel(_positional = false):
	""" Creates a new SoundChannel and returns a reference to it.
	    Takes whether it should be a positional AudioStreamPlayer2D or not as an argument, default false.
	"""
	var new_channel = SoundChannel.new(_positional, tween, funcref(self, "get_current_layers"))
	add_child(new_channel.player)
	music_channels.append(new_channel)
	
	return new_channel


func find_channel_playing_track(_track_name):
	""" Returns the first found SoundChannel object playing the given track.
	    If none, returns false.
	"""
	for channel in music_channels:
		if channel.is_active and channel.track_name == _track_name:
			return channel
	return false

func get_current_layers():
	return active_on_layer

func filter_idle_channels():
	""" Returns array of channels that are currently idle.
	"""
	var result = []
	for channel in music_channels:
		if not channel.is_active:
			result.append(channel)
	return result

static func get_multiplied_volume(_volume_mult):
	""" Returns a volume based on the DEFAULT_VOLUME multiplied by _volume_mult.
	    Since DEFAULT_VOLUME can be 0 or negative, this needs to take into account MUTE_VOLUME.
	"""
	return MUTE_VOLUME + (abs(DEFAULT_VOLUME - MUTE_VOLUME) * _volume_mult)