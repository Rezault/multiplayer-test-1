extends Node

@onready var input: AudioStreamPlayer = $Input
var index: int
var effect: AudioEffectCapture
var playback: AudioStreamGeneratorPlayback
@export var outputPath: NodePath
var inputThreshold = 0.005
var receiveBuffer := PackedFloat32Array()
var setupDone = false

func _ready():
	pass
	
func setupAudio(id):
	input = $Input
	set_multiplayer_authority(id) # Set the multiplayer authority
	if is_multiplayer_authority(): # We want to make sure we're the current player
		input.stream = AudioStreamMicrophone.new() # Set up a new microphone
		input.play() # Begin capturing
		index = AudioServer.get_bus_index("Record") # Get the index of the "Record" bus
		if index == -1:
			print("Error: 'Record' bus not found!")
			return
			
		effect = AudioServer.get_bus_effect(index, 0) # Get the "Capture" effect at index 0 of the "Record" bus
		if effect == null or !effect is AudioEffectCapture:
			print("Error: 'Record' bus does not have a valid AudioEffectCapture!")
			return

	playback = get_node(outputPath).get_stream_playback()
	setupDone = true

func _process(delta):
	if not setupDone: return
	
	if is_multiplayer_authority():
		processMic() # Process the mic for the current client

	processVoice()
		
func processMic():
	# Read what has been said into the microphone
	var stereoData: PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	if stereoData.size() > 0:
		# We have data, initialise a packed float array
		var data = PackedFloat32Array()
		data.resize(stereoData.size()) # Resize it just incase it's not the right size
		var maxAmplitude := 0.0
		
		for i in range(stereoData.size()):
			# Get the average of the 2d Vector values so we can convert to float
			var value = (stereoData[i].x + stereoData[i].y) / 2
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
		
		# Check if the max amplitude is less than the input threshold
		# i.e. if the person is talking loud enough
		# If they're not, just return
		if maxAmplitude < inputThreshold:
			return
		
		# Send the data to all clients
		sendData.rpc(data)

func processVoice():
	# If there's nothing in the receive buffer, return
	if receiveBuffer.size() <= 0:
		return
	
	# Loop through whichever is smaller: the current frames available from the playback, or the size of receive buffer
	# Just a bit of error checking. If our playback buffer have not finished playing, we don't want to overwrite it
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		# Pass in a Vector2, the reason is because left ear and right ear
		# In this case, we want to apply the same buffer on both sides. We want the same noise
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0) # Remove old info, only process new info

@rpc("any_peer", "call_remote", "unreliable_ordered")
func sendData(data: PackedFloat32Array):
	receiveBuffer.append_array(data)
