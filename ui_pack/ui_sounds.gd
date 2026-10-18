extends Node
## Soft UI sounds for the whole game.
##
## Setup: Project > Project Settings > Globals > Autoload, add this script with the name UiSounds.
## After that every Button in the game plays the soft tap by itself. No other code is needed.
##
## To give one button a different sound:   button.set_meta("ui_sound", "confirm")
## To silence one button:                  button.set_meta("ui_sound", "")
## To play a sound from code:              UiSounds.play("reward")
##
## Sounds: tap, choice, confirm, back, page, reward

const NAMES = ["tap", "choice", "confirm", "back", "page", "reward"]

var enabled = true          # turn all UI sounds on or off (hook this to your Settings screen)
var volume_db = -6.0        # overall loudness
var press_bounce = true     # buttons shrink a little while held, then spring back

var streams = {}
var players = []
var next_player = 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var folder = get_script().resource_path.get_base_dir() + "/sounds/"
	for sound_name in NAMES:
		var path = folder + "ui_" + sound_name + ".wav"
		if ResourceLoader.exists(path):
			streams[sound_name] = load(path)
		else:
			push_warning("UiSounds: missing " + path)
	# A few players so quick taps can overlap without cutting each other off.
	for i in 4:
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	get_tree().node_added.connect(_on_node_added)


func play(sound_name):
	if not enabled or not streams.has(sound_name):
		return
	var p = players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = streams[sound_name]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.97, 1.03)   # tiny variation so repeated taps do not sound robotic
	p.play()


func _on_node_added(node):
	if node is BaseButton:
		node.pressed.connect(_on_button_pressed.bind(node))
		node.button_down.connect(_on_button_down.bind(node))
		node.button_up.connect(_on_button_up.bind(node))


func _on_button_pressed(button):
	play(str(button.get_meta("ui_sound", "tap")))


func _on_button_down(button):
	if press_bounce:
		button.pivot_offset = button.size / 2
		button.create_tween().tween_property(button, "scale", Vector2(0.97, 0.97), 0.06)


func _on_button_up(button):
	if press_bounce:
		var tween = button.create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.18)
