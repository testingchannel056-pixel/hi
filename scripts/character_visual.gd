extends TextureRect

# A character's portrait on the screen. Give it a character and it shows
# them, drawn by scripts/character_art.gd:
#
#   portrait.show_character({"gender": "Female", "age": 30, "look": look,
#       "outfit": "wudang", "backdrop": "wudang"})
#
#   gender       "Male" or "Female"
#   age          a child, a youth, someone in their prime and an elder are drawn differently
#   cultivation  the cultivation stage (0, 1, 2...); cultivators grow old later
#   look         the chosen skin, hair, eyes and so on (see character_data.gd)
#   seed         a number that makes up a look when "look" is missing or incomplete
#   outfit       what they wear: a name from OUTFITS in character_data.gd
#   backdrop     what is behind them: a name from BACKDROPS
#
# It is safe to call every time something changes: the picture is only
# drawn again when the character really looks different.

const Art = preload("res://scripts/character_art.gd")

var showing = ""   # which portrait is on the screen now


func _init():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_character(character):
	var key = Art.key_of(character)
	if key == showing:
		return
	showing = key
	texture = Art.texture(character)
