extends AudioStreamPlayer

# Plays background music on a loop.
#
# Put your music file in res://assets/music/ and name it "background":
# background.ogg, background.mp3 or background.wav. If there is no file,
# the game simply has no music.

const FILES = [
	"res://assets/music/background.ogg",
	"res://assets/music/background.mp3",
	"res://assets/music/background.wav",
]


func _ready():
	for file in FILES:
		if ResourceLoader.exists(file):
			stream = load(file)
			break
	if stream == null:
		return
	# When the track reaches its end, start it again.
	finished.connect(play)
	play()
