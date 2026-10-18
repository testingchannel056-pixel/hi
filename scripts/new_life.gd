extends Control

# The New Life screen. You shape your character here before the game starts:
# name, gender, starting attributes, birth and one talent.
#
# Choose appearance below the aging preview. Looks remains a gameplay stat.
# Four portraits preview your chosen features across a lifetime.
#
# Pressing "Begin this life" sends your choices to the game with the "begin"
# signal. If a saved life exists, a button at the bottom goes back to it
# instead (the "resume" signal).
#
# The layout follows ui_pack/character_creator.gd. The backgrounds, talents
# and attributes are the game's own (life_data.gd and world_data.gd).

signal begin(choices)
signal resume

const PlayerScript = preload("res://scripts/player.gd")
const World = preload("res://scripts/world_data.gd")
const Life = preload("res://scripts/life_data.gd")
const UiTheme = preload("res://ui_pack/murim_theme.gd")
const AppearanceData = preload("res://scripts/character_data.gd")
const Portrait = preload("res://ui_pack/portrait.gd")
const Look = preload("res://scripts/game_theme.gd")

const GENDERS = ["Male", "Female"]
const ATTRIBUTES = ["Health", "Smarts", "Looks", "Happiness"]
# Attributes that are dealt by fate: their sliders cannot be moved by the
# player, only rerolled. Looks is one because it decides your face. Take it
# out of this list (leaving []) to let the player set it like the others.
const FATED = ["Looks"]
const PRIME_AGE = 28   # the big portrait shows you at this age
# The four small portraits: what is written under each, and the age it shows.
const YEARS_TO_COME = [["Young", 15], ["Adult", 28], ["Mature", 42], ["Elder", 65]]
const BIG = -1         # stands for the big portrait in the "to_redraw" list

var appearance = {}
var outfit = "martial"
var backdrop = "plain"
var appearance_values = {}
var appearance_rows = {}
var gender = "Male"
var talent = "None"
var background = "Poor Village"
var face_seed = 0           # which set of faces is yours, once the pack has more than one
var sliders = {}            # sliders["Looks"] is the slider for Looks
var gender_buttons = {}     # gender_buttons["Female"] is the Female button
var background_buttons = {} # background_buttons["Orphan"] is that background's card
var talent_buttons = {}     # talent_buttons["Iron Body"] is that talent's button
var stage_portraits = []    # the four small portraits, youngest first
var to_redraw = []          # the portraits that still have to be redrawn: BIG, or 0 to 3

@onready var name_edit = %NameEdit
@onready var portrait = %Portrait
@onready var looks_word = %LooksWord
@onready var background_hint = %BackgroundHint
@onready var talent_hint = %TalentHint
@onready var begin_button = %BeginButton


func _ready():
	$Background.color = UiTheme.INK
	%RandomNameButton.pressed.connect(random_name)
	%RerollButton.pressed.connect(reroll)
	begin_button.pressed.connect(finish)
	%ResumeButton.pressed.connect(resume.emit)
	# Every button makes a soft tap by itself (see ui_pack/ui_sounds.gd).
	# These three get a sound of their own.
	begin_button.set_meta("ui_sound", "confirm")
	%ResumeButton.set_meta("ui_sound", "confirm")
	%RerollButton.set_meta("ui_sound", "page")

	var group = ButtonGroup.new()
	for option in GENDERS:
		var button = toggle(option, group)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(choose_gender.bind(option))
		%GenderButtons.add_child(button)
		gender_buttons[option] = button

	# One row per attribute: its name, a slider from 0 to 100 and the number.
	for attribute in ATTRIBUTES:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var title = Label.new()
		title.text = attribute
		title.custom_minimum_size.x = 104
		title.add_theme_font_size_override("font_size", 20)
		var slider = HSlider.new()
		slider.max_value = 100
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# The slider fills with the same colour as that stat's bar in the Profile.
		var colour = Look.BAR_COLOURS[attribute]
		slider.add_theme_stylebox_override("grabber_area", UiTheme.box(colour, colour, 3, 3))
		slider.add_theme_stylebox_override("grabber_area_highlight", UiTheme.box(colour, colour, 3, 3))
		var number = Label.new()
		number.custom_minimum_size.x = 36
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.add_theme_font_size_override("font_size", 20)
		slider.value_changed.connect(show_number.bind(number))
		slider.editable = attribute not in FATED
		if attribute == "Looks":
			# Your face follows your Looks.
			slider.value_changed.connect(looks_changed)
		row.add_child(title)
		row.add_child(slider)
		row.add_child(number)
		%Sliders.add_child(row)
		sliders[attribute] = slider

	# The four small portraits, each with its caption.
	for stage in YEARS_TO_COME:
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		var small = Portrait.new()
		small.custom_minimum_size = Vector2(92, 92)
		var caption = Label.new()
		caption.text = stage[0]
		caption.theme_type_variation = "HintLabel"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(small)
		box.add_child(caption)
		%Stages.add_child(box)
		stage_portraits.append(small)

	# One card per background: its name, and what it starts you with.
	group = ButtonGroup.new()
	for option in Life.BACKGROUNDS:
		var card = toggle("", group)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 92
		card.pressed.connect(choose_background.bind(option))
		# Two lines of text inside the button, each with its own size and colour.
		var lines = VBoxContainer.new()
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.add_theme_constant_override("separation", 0)
		card.add_child(lines)
		lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
		lines.add_child(UiTheme.label(option, 22))
		var gifts = UiTheme.label(gifts_of(option), 16, UiTheme.JADE)
		gifts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines.add_child(gifts)
		%Backgrounds.add_child(card)
		background_buttons[option] = card

	# One small button per talent. What the chosen one does is written underneath.
	group = ButtonGroup.new()
	for option in World.TALENTS:
		var chip = toggle(option, group)
		chip.add_theme_font_size_override("font_size", 20)
		chip.pressed.connect(choose_talent.bind(option))
		%Talents.add_child(chip)
		talent_buttons[option] = chip

	build_appearance_picker()
	randomise()


# Redraws one waiting portrait per frame, so a tap never makes the screen
# stutter. Nothing is drawn while the screen is hidden.
func _process(_delta):
	if to_redraw.is_empty() or not is_visible_in_tree():
		return
	var which = to_redraw.pop_front()
	if which == BIG:
		portrait.set_profile(look_at(PRIME_AGE))
		looks_word.text = Portrait.looks_word(sliders["Looks"].value)
		pop(portrait)
	else:
		stage_portraits[which].set_profile(look_at(YEARS_TO_COME[which][1]))


# Shows the button that goes back to a saved life. "who" is something like
# "Baek Mu-jin, age 18"; an empty text hides the button.
func offer_saved_life(who):
	%ResumeButton.visible = who != ""
	%ResumeButton.text = "Back to %s" % who


# Shows a note for the person building the game in place of the first line
# (see picture_note() in game.gd). An empty text changes nothing.
func show_note(text):
	if text != "":
		%Intro.text = text


func show_number(value, label):
	label.text = str(int(value))


func looks_changed(_value):
	refresh_portraits()


func random_name():
	# A fresh Player picks a random name for itself; borrow it.
	name_edit.text = PlayerScript.new().full_name


func choose_gender(option):
	gender = option
	appearance = AppearanceData.complete(appearance, gender, face_seed)
	update_appearance_labels()
	gender_buttons[option].button_pressed = true
	refresh_portraits()


func choose_talent(option):
	talent = option
	talent_buttons[option].button_pressed = true
	talent_hint.text = World.TALENTS[option]["text"]


func choose_background(option):
	background = option
	background_buttons[option].button_pressed = true
	background_hint.text = Life.BACKGROUNDS[option]["text"]


# "Reroll fate": new starting numbers, and with your Looks a new face. Your
# name, gender, birth and talent stay as you chose them.
func reroll():
	face_seed = randi() % 1000000
	appearance = AppearanceData.random_look(face_seed, gender)
	update_appearance_labels()
	for attribute in sliders:
		sliders[attribute].value = randi_range(20, 90)
	refresh_portraits()


# Deals a whole new character. This is what you see when the screen opens.
func randomise():
	random_name()
	choose_gender(GENDERS.pick_random())
	choose_talent(World.TALENTS.keys().pick_random())
	choose_background(Life.BACKGROUNDS.keys().pick_random())
	reroll()


func finish():
	var chosen_name = name_edit.text.strip_edges()
	if chosen_name == "":
		chosen_name = PlayerScript.new().full_name
	var choices = {"name": chosen_name, "gender": gender, "talent": talent,
		"background": background, "seed": face_seed,
		"look": appearance.duplicate(true), "outfit": outfit, "backdrop": backdrop}
	for attribute in sliders:
		choices[attribute] = int(sliders[attribute].value)
	begin.emit(choices)


# ---------------------------------------------------------------------------
# Portraits
# ---------------------------------------------------------------------------

# Asks for every portrait to be redrawn (see _process). The big one shows
# you in your prime; the small ones show the years to come.
func refresh_portraits():
	to_redraw = [BIG]
	for i in stage_portraits.size():
		to_redraw.append(i)


# What a portrait is chosen by at a given age (see ui_pack/portrait.gd).
func look_at(age):
	return {"gender": gender, "age": age, "looks": sliders["Looks"].value, "seed": face_seed,
		"look": appearance, "outfit": outfit, "backdrop": backdrop}


# A quick "pop", so the portrait feels alive when it changes.
func pop(node):
	node.pivot_offset = node.size / 2
	node.scale = Vector2(0.94, 0.94)
	var tween = node.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.25)


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

# A button that stays lit while it is the chosen one of its group.
func toggle(text, group):
	var button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	return button


# What a background starts you with, as one line: "Smarts +5, Gold +40".
func gifts_of(option):
	var start = Life.BACKGROUNDS[option]["start"]
	var parts = []
	for stat in start:
		parts.append("%s %+d" % [stat, start[stat]])
	return ", ".join(parts)


# Appearance is in the real New Life flow, and travels with the save file.
func build_appearance_picker():
	var panel = PanelContainer.new()
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	%Backgrounds.get_parent().add_child(panel)
	%Backgrounds.get_parent().move_child(panel, 0)
	column.add_child(UiTheme.label("YOUR APPEARANCE", 22, UiTheme.GOLD))
	var note = UiTheme.label("Choose your style. Your features stay yours as you age.", 17, UiTheme.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	for part in AppearanceData.PARTS:
		appearance_row(column, part["key"], part["title"])
	appearance_row(column, "outfit", "Outfit")
	appearance_row(column, "backdrop", "Aura")


func appearance_row(column, key, title):
	var row = HBoxContainer.new()
	column.add_child(row)
	var caption = UiTheme.label(title, 19)
	caption.custom_minimum_size.x = 118
	row.add_child(caption)
	for direction in [-1, 1]:
		if direction == 1:
			var value = UiTheme.label("", 18, UiTheme.JADE)
			value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(value)
			appearance_values[key] = value
		var button = Button.new()
		button.text = "‹" if direction < 0 else "›"
		button.custom_minimum_size = Vector2(52, 46)
		button.pressed.connect(change_appearance.bind(key, direction))
		row.add_child(button)
	appearance_rows[key] = row


func change_appearance(key, direction):
	if key == "outfit":
		var names = AppearanceData.OUTFITS.keys()
		outfit = names[wrapi(names.find(outfit) + direction, 0, names.size())]
	elif key == "backdrop":
		var names = AppearanceData.BACKDROPS.keys()
		backdrop = names[wrapi(names.find(backdrop) + direction, 0, names.size())]
	else:
		appearance = AppearanceData.complete(appearance, gender, face_seed)
		appearance[key] = wrapi(appearance[key] + direction, 0, AppearanceData.options(key, gender).size())
	update_appearance_labels()
	refresh_portraits()


func update_appearance_labels():
	for key in appearance_values:
		if key == "outfit":
			appearance_values[key].text = outfit.capitalize()
		elif key == "backdrop":
			appearance_values[key].text = backdrop.capitalize()
		else:
			appearance_values[key].text = AppearanceData.options(key, gender)[appearance.get(key, 0)]
			var swatch = AppearanceData.swatch(key, appearance.get(key, 0))
			appearance_values[key].add_theme_color_override("font_color", swatch.lightened(0.25) if swatch != null else UiTheme.JADE)
	appearance_rows.get("beard", self).visible = gender == "Male"
