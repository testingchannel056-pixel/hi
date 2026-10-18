extends Control

# The character customization screen, on its own. Open
# character_customization.tscn and press F6 to try looks.
#
# Each part has a picker: a < button, the chosen option, a > button. The
# portrait is drawn by scripts/character_art.gd, and the lists of options
# are in scripts/character_data.gd.
#
# NOTE: this screen is not part of the game yet. The New Life screen still
# has to be given these pickers.

const Data = preload("res://scripts/character_data.gd")
const Visual = preload("res://scripts/character_visual.gd")
const Look = preload("res://scripts/game_theme.gd")
const UiTheme = preload("res://ui_pack/murim_theme.gd")

const AGES = [8, 16, 27, 70]   # the ages the "Age" picker steps through

var gender = "Male"
var age = 27
var look = {}            # the chosen look (see character_data.gd)
var portrait
var value_labels = {}    # value_labels["hair"] is the text between that picker's buttons
var rows = {}            # rows["beard"] is that picker's whole row


func _ready():
	theme = Look.make()
	var back = ColorRect.new()
	back.color = UiTheme.INK
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title = Label.new()
	title.text = "Character Customization"
	title.theme_type_variation = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	portrait = Visual.new()
	portrait.custom_minimum_size = Vector2(380, 380)
	column.add_child(portrait)

	add_picker(column, "gender", "Gender", step_gender)
	add_picker(column, "age", "Age", step_age)
	for part in Data.PARTS:
		add_picker(column, part["key"], part["title"], step.bind(part["key"]))

	var surprise = Button.new()
	surprise.text = "Surprise me"
	surprise.pressed.connect(randomise)
	column.add_child(surprise)
	randomise()


# Adds one row: the part's name, a < button, the chosen option, a > button.
func add_picker(column, key, title_text, action):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title = Label.new()
	title.text = title_text
	title.custom_minimum_size.x = 150
	var previous = Button.new()
	previous.text = "<"
	previous.custom_minimum_size.x = 64
	previous.pressed.connect(action.bind(-1))
	var value = Label.new()
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", UiTheme.GOLD)
	var next = Button.new()
	next.text = ">"
	next.custom_minimum_size.x = 64
	next.pressed.connect(action.bind(1))
	for piece in [title, previous, value, next]:
		row.add_child(piece)
	column.add_child(row)
	value_labels[key] = value
	rows[key] = row


# Moves one part to the next or previous option, wrapping around at the ends.
func step(direction, key):
	look[key] = wrapi(look[key] + direction, 0, Data.options(key, gender).size())
	refresh()


func step_gender(_direction):
	gender = "Female" if gender == "Male" else "Male"
	look = Data.complete(look, gender)
	refresh()


func step_age(direction):
	age = AGES[wrapi(AGES.find(age) + direction, 0, AGES.size())]
	refresh()


func randomise():
	look = Data.random_look(randi(), gender)
	refresh()


# Draws the portrait again and writes the chosen options into the pickers.
func refresh():
	portrait.show_character({"gender": gender, "age": age, "look": look, "outfit": "martial"})
	value_labels["gender"].text = gender
	value_labels["age"].text = str(age)
	for part in Data.PARTS:
		var key = part["key"]
		var names = Data.options(key, gender)
		value_labels[key].text = "%s   %d / %d" % [names[look[key]], look[key] + 1, names.size()]
		rows[key].visible = not part.has("only") or part["only"] == gender
