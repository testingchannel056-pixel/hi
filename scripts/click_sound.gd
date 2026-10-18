extends AudioStreamPlayer

# Plays a short click whenever any button in the game is pressed.
#
# The sound is built from numbers when the game starts, so there is no audio
# file to ship. To use a sound file of your own instead, set this node's
# Stream in the Inspector and remove the "stream = make_click()" line below.

const SAMPLE_RATE = 44100   # samples per second
const LENGTH = 0.07         # how long the click lasts, in seconds
const PITCH = 720.0         # in Hz; a higher number sounds lighter
const LOUDNESS = 0.5        # 0 to 1


func _ready():
	stream = make_click()
	# Hook every button that exists now, and every button added later.
	hook_all(get_tree().root)
	get_tree().node_added.connect(hook)


func hook_all(node):
	hook(node)
	for child in node.get_children():
		hook_all(child)


func hook(node):
	if node is BaseButton and not node.pressed.is_connected(click):
		node.pressed.connect(click)


func click():
	# A sound can only play while this node is part of the running scene.
	if is_inside_tree():
		play()


# Builds the click: two tones played together that fade out very quickly,
# which sounds like a soft tap on wood.
func make_click():
	var count = int(SAMPLE_RATE * LENGTH)
	var data = PackedByteArray()
	data.resize(count * 2)   # every sample is two bytes
	for i in count:
		var time = float(i) / SAMPLE_RATE
		var fade = exp(-time * 70.0)
		var wave = sin(TAU * PITCH * time) * 0.7 + sin(TAU * PITCH * 2.4 * time) * 0.3
		data.encode_s16(i * 2, int(wave * fade * LOUDNESS * 32767))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SAMPLE_RATE
	sound.stereo = false
	sound.data = data
	return sound
