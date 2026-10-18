extends Node2D

# Shows one character built from three separate pictures stacked on top of
# each other: skin at the bottom, then eyes, then hair.
#
# Every picture is 512x512 with a transparent background and is drawn in the
# same coordinates, so the three Sprite2D nodes just sit at the same position.
# Changing one part only swaps that one sprite's picture.

const FOLDER = "res://assets/character/"
const FILE_TYPE = ".svg"   # change to ".png" if you swap the pictures for PNG files

# The appearance, stored as plain data. Each value is the name of a picture
# in the matching folder, for example res://assets/character/hair/white.svg.
var skin = "light"
var eyes = "brown"
var hair = "black"

@onready var skin_sprite = $SkinSprite
@onready var eyes_sprite = $EyesSprite
@onready var hair_sprite = $HairSprite


func _ready():
	refresh()


# Takes data like {"skin": "dark", "eyes": "blue", "hair": "white"}.
func show_appearance(appearance):
	skin = appearance["skin"]
	eyes = appearance["eyes"]
	hair = appearance["hair"]
	refresh()


# Reads the three values and shows the matching pictures.
func refresh():
	skin_sprite.texture = load(FOLDER + "skin/" + skin + FILE_TYPE)
	eyes_sprite.texture = load(FOLDER + "eyes/" + eyes + FILE_TYPE)
	hair_sprite.texture = load(FOLDER + "hair/" + hair + FILE_TYPE)
