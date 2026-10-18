extends Control

# The customization screen. It holds the chosen appearance as data, makes one
# button per option, and tells CharacterVisual to redraw when a button is pressed.

# Every choice the player can make. Each name matches a picture file:
#   res://assets/character/<part>/<name>.svg
# To add an option, add the picture and add its name here.
var options = {
	"skin": ["light", "medium", "dark"],
	"eyes": ["brown", "blue", "green", "red"],
	"hair": ["black", "brown", "blonde", "red", "white"],
}

# The appearance the player has picked.
var appearance = {"skin": "light", "eyes": "brown", "hair": "black"}

# buttons["hair"]["white"] is the button for white hair.
var buttons = {}

@onready var character = $Layout/Frame/Stage/CharacterVisual
@onready var data_label = $Layout/DataLabel
@onready var rows = $Layout/Rows


func _ready():
	for part in options:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var title = Label.new()
		title.text = part.capitalize()
		title.custom_minimum_size.x = 70
		row.add_child(title)
		buttons[part] = {}
		for choice in options[part]:
			var button = Button.new()
			button.text = choice.capitalize()
			button.toggle_mode = true
			button.custom_minimum_size.x = 96
			button.pressed.connect(choose.bind(part, choice))
			row.add_child(button)
			buttons[part][choice] = button
		rows.add_child(row)
	refresh()


func choose(part, choice):
	appearance[part] = choice
	refresh()


func refresh():
	character.show_appearance(appearance)
	data_label.text = 'skin = "%s"     eyes = "%s"     hair = "%s"' % [
		appearance["skin"], appearance["eyes"], appearance["hair"]]
	# Keep the chosen button of each row pressed in.
	for part in buttons:
		for choice in buttons[part]:
			buttons[part][choice].button_pressed = appearance[part] == choice
