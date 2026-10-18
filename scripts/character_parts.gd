extends Control

# Character parts picker. It shows parts cut from ONE sheet picture, where
# every part (hair, skin, eyes, nose, mouth) has its own panel of cells.
# The < and > buttons step through the cells, and each choice is stored as
# plain data in "appearance".
#
# The parts are shown side by side, not stacked into one face. In this sheet
# the hair cells already contain a whole face, and the eyes, nose and mouth
# cells have skin painted behind them, so they cannot be layered.

# Where the sheet picture may be. The first one that exists is used.
const SHEET_FILES = [
	"res://parts_sheet.png",
	"res://assets/character/parts_sheet.png",
	"res://assets/character/parts_sheet.webp",
	"res://assets/character/parts_sheet.jpg",
]

# The numbers below were measured on a copy of the picture that is 1125
# pixels wide. A bigger or smaller copy still works: they are scaled to fit.
const MEASURED_WIDTH = 1125.0

# Where each part's cells are in the sheet.
#   "columns" - the left edge of each column of cells
#   "rows"    - the top edge of each row of cells
#   "width" and "height" - the size of one cell
#   "zoom"    - how much bigger the cell is drawn on screen
const PARTS = {
	"hair": {"columns": [568, 678, 787, 897, 1006], "rows": [47, 198, 354],
		"width": 110, "height": 150, "zoom": 2.2},
	"skin": {"columns": [15, 97, 175, 254, 333], "rows": [616, 730, 846, 962],
		"width": 79, "height": 112, "zoom": 2.9},
	"eyes": {"columns": [19, 96, 174, 256, 332, 403, 475], "rows": [69, 145, 223, 305, 383, 463],
		"width": 71, "height": 50, "zoom": 3.0},
	"nose": {"columns": [434, 511, 589, 666], "rows": [616, 698, 777, 858, 939],
		"width": 69, "height": 69, "zoom": 2.0},
	"mouth": {"columns": [760, 847, 937, 1031], "rows": [617, 702, 787, 872, 960],
		"width": 80, "height": 77, "zoom": 2.0},
}

# The appearance the player has picked: one cell number per part.
# Cells are counted left to right, top to bottom, starting at 0.
var appearance = {"hair": 0, "skin": 0, "eyes": 0, "nose": 0, "mouth": 0}

var sheet = null
var pictures = {}   # pictures["hair"] is the picture that shows the hair cell
var counters = {}   # counters["hair"] is the "3 / 15" text under it

@onready var grid = $Layout/Grid
@onready var data_label = $Layout/DataLabel


func _ready():
	for file in SHEET_FILES:
		if ResourceLoader.exists(file):
			sheet = load(file)
			break
	if sheet == null:
		data_label.text = "The sheet picture is missing.\nSave it in assets/character and name it parts_sheet (.png, .webp or .jpg)."
		return
	for part in PARTS:
		grid.add_child(make_card(part))
	refresh()


# How many cells a part has.
func count(part):
	return PARTS[part]["columns"].size() * PARTS[part]["rows"].size()


# The rectangle of the sheet that holds one cell of a part.
func cell_region(part, number):
	var info = PARTS[part]
	var column = number % info["columns"].size()
	var row = number / info["columns"].size()
	var ratio = sheet.get_width() / MEASURED_WIDTH
	return Rect2(info["columns"][column] * ratio, info["rows"][row] * ratio,
		info["width"] * ratio, info["height"] * ratio)


# Builds the card for one part: its name, its picture and the < > buttons.
func make_card(part):
	var info = PARTS[part]
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	var title = Label.new()
	title.text = part.capitalize()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	# An AtlasTexture shows just one rectangle of a bigger picture.
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.filter_clip = true
	var picture = TextureRect.new()
	picture.texture = atlas
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.custom_minimum_size = Vector2(info["width"], info["height"]) * info["zoom"]
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picture)
	pictures[part] = picture

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	var previous = Button.new()
	previous.text = "  <  "
	previous.pressed.connect(step.bind(part, -1))
	var counter = Label.new()
	counter.custom_minimum_size.x = 90
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next = Button.new()
	next.text = "  >  "
	next.pressed.connect(step.bind(part, 1))
	buttons.add_child(previous)
	buttons.add_child(counter)
	buttons.add_child(next)
	box.add_child(buttons)
	counters[part] = counter
	return card


# Moves one part to the next or previous cell, wrapping around at the ends.
func step(part, direction):
	appearance[part] = wrapi(appearance[part] + direction, 0, count(part))
	refresh()


# Reads the appearance data and shows the matching cells.
func refresh():
	var words = []
	for part in PARTS:
		pictures[part].texture.region = cell_region(part, appearance[part])
		counters[part].text = "%d / %d" % [appearance[part] + 1, count(part)]
		words.append("%s = %d" % [part, appearance[part]])
	data_label.text = "     ".join(words)
