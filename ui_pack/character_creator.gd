extends Control
## Character creation screen.
##
## The player chooses a name, gender, birth and talent. They never choose a face:
## the portrait is worked out from those choices and changes as they tap.
## "Reroll fate" deals new starting stats and a new look.
##
## When the player presses Begin, the signal life_chosen is emitted with a Dictionary:
##     name, gender, background, talent, seed, age, health, smarts, looks, happiness, gold
## Keep "seed" on your player and pass it to the portrait, so the face stays the same for life.

signal life_chosen(profile)

const UiTheme = preload("murim_theme.gd")
const Portrait = preload("portrait.gd")

# Replace these two lists with your game's own data if you already have it.
const BACKGROUNDS = [
	{"name": "Poor Village", "line": "Hard soil, harder hands.", "bonus": "Health +10", "health": 10, "gold": 5},
	{"name": "Merchant Family", "line": "Raised on an abacus.", "bonus": "Gold +60, Smarts +5", "smarts": 5, "gold": 60},
	{"name": "Martial Clan", "line": "A sword before a spoon.", "bonus": "Health +6, Looks +4", "health": 6, "looks": 4, "gold": 20},
	{"name": "Sect Family", "line": "Born inside the gates.", "bonus": "Smarts +5, Happiness +5", "smarts": 5, "happiness": 5, "gold": 15},
	{"name": "Scholar Family", "line": "An ink-stained cradle.", "bonus": "Smarts +12", "smarts": 12, "gold": 20},
	{"name": "Noble Family", "line": "Silk, and expectations.", "bonus": "Gold +100, Looks +5", "looks": 5, "gold": 100},
	{"name": "Orphan", "line": "The street raised you.", "bonus": "Health +5, Happiness -10", "health": 5, "happiness": -10, "gold": 0},
	{"name": "Wandering Family", "line": "No roof, every road.", "bonus": "Happiness +8, Health +4", "happiness": 8, "health": 4, "gold": 10},
]
const TALENTS = [
	{"name": "None", "line": "An ordinary child. Ordinary can go a long way."},
	{"name": "Iron Body", "line": "Your bones are denser than they have any right to be."},
	{"name": "Wind Step", "line": "You ran before you walked, and nobody could catch you."},
	{"name": "Scholar's Mind", "line": "You read once and remember for ever."},
	{"name": "Heavenly Meridians", "line": "Qi moves through you like a river through a valley."},
	{"name": "Silver Tongue", "line": "People agree with you, then wonder why."},
	{"name": "Fortune's Favourite", "line": "Dropped coins roll towards you."},
]
const SURNAMES = ["Li", "Wang", "Zhao", "Chen", "Liu", "Yun", "Bai", "Mo", "Xiao", "Tang", "Namgung", "Jin"]
const MALE_NAMES = ["Ren", "Feng", "Jian", "Hu", "Long", "Tian", "Shan", "Wei", "Kang", "Yi"]
const FEMALE_NAMES = ["Yue", "Lan", "Xue", "Mei", "Qing", "Hua", "Ling", "Yan", "Rou", "Zhi"]
const STAT_KEYS = ["health", "smarts", "looks", "happiness"]
const STAGE_AGES = [["Child", 8], ["Youth", 15], ["Prime", 28], ["Elder", 65]]

var profile = {"name": "", "gender": "male", "background": "Poor Village", "talent": "None", "seed": 0, "age": 0}
var rolled = {}
var refresh_count = 0

var portrait
var stage_portraits = []
var name_edit
var stat_bars = {}
var talent_line
var gold_label


func _ready():
	randomize()
	theme = UiTheme.make()
	_build()
	profile["name"] = _random_name()
	name_edit.text = profile["name"]
	_reroll(false)


# ------------------------------------------------------------ actions

func _reroll(animate = true):
	profile["seed"] = randi() % 1000000
	for key in STAT_KEYS:
		rolled[key] = randi_range(35, 85)
	_refresh()
	if animate:
		_pop(portrait)


func _refresh():
	var background = _background()
	for key in STAT_KEYS:
		var value = clampi(rolled[key] + int(background.get(key, 0)), 1, 100)
		profile[key] = value
		UiTheme.set_bar(stat_bars[key], key.capitalize(), value, 100, false)
	profile["gold"] = int(background.get("gold", 0))
	gold_label.text = "Starting gold: %d" % profile["gold"]
	# The big portrait shows the character in their prime; the small ones show the years to come.
	var preview = profile.duplicate()
	preview["age"] = 28
	portrait.set_profile(preview)
	_refresh_stages(preview)


## Draws the four small portraits one per frame, so a tap never makes the screen stutter.
func _refresh_stages(preview):
	refresh_count += 1
	var my_turn = refresh_count
	for i in STAGE_AGES.size():
		await get_tree().process_frame
		if my_turn != refresh_count:
			return      # the player tapped again; a newer refresh has taken over
		var staged = preview.duplicate()
		staged["age"] = STAGE_AGES[i][1]
		stage_portraits[i].set_profile(staged)


func _background():
	for background in BACKGROUNDS:
		if background["name"] == profile["background"]:
			return background
	return BACKGROUNDS[0]


func _random_name():
	var given = FEMALE_NAMES if profile["gender"] == "female" else MALE_NAMES
	return "%s %s" % [SURNAMES.pick_random(), given.pick_random()]


func _on_gender(gender):
	profile["gender"] = gender
	_refresh()
	_pop(portrait)


func _on_background(background_name):
	profile["background"] = background_name
	_refresh()
	_pop(portrait)


func _on_talent(talent):
	profile["talent"] = talent["name"]
	talent_line.text = talent["line"]


func _on_random_name():
	profile["name"] = _random_name()
	name_edit.text = profile["name"]


func _on_begin():
	profile["name"] = name_edit.text.strip_edges()
	if profile["name"] == "":
		profile["name"] = _random_name()
	life_chosen.emit(profile.duplicate())


## A quick "pop" so the portrait feels alive when it changes.
func _pop(node):
	node.pivot_offset = node.size / 2
	node.scale = Vector2(0.94, 0.94)
	var tween = node.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.25)


# ------------------------------------------------------------ building the screen

func _build():
	var paper = ColorRect.new()
	paper.color = UiTheme.INK
	add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title = UiTheme.label("A New Life", 34, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var motto = UiTheme.label("Heaven deals the cards. You play them.", 16, UiTheme.DIM)
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(motto)

	root.add_child(_build_top())
	root.add_child(_build_stages())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var options = VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 10)
	scroll.add_child(options)
	options.add_child(UiTheme.label("Birth", 18, UiTheme.GOLD))
	options.add_child(_build_backgrounds())
	options.add_child(UiTheme.label("Talent", 18, UiTheme.GOLD))
	options.add_child(_build_talents())
	talent_line = UiTheme.label(TALENTS[0]["line"], 16, UiTheme.DIM)
	talent_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	options.add_child(talent_line)

	var begin = Button.new()
	begin.text = "Begin this life"
	begin.custom_minimum_size = Vector2(0, 68)
	begin.add_theme_font_size_override("font_size", 24)
	begin.add_theme_color_override("font_color", UiTheme.GOLD)
	begin.add_theme_stylebox_override("normal", UiTheme.box(UiTheme.PANEL_LIGHT, UiTheme.GOLD, 14, 6, 2))
	begin.set_meta("ui_sound", "confirm")
	begin.pressed.connect(_on_begin)
	root.add_child(begin)


## Portrait on the left; name, gender, fate and starting stats on the right.
func _build_top():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	portrait = Portrait.new()
	portrait.custom_minimum_size = Vector2(256, 256)
	row.add_child(portrait)

	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	column.add_child(name_row)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.max_length = 18
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.custom_minimum_size = Vector2(0, 50)
	name_row.add_child(name_edit)
	var dice = Button.new()
	dice.text = "Random"
	dice.custom_minimum_size = Vector2(0, 50)
	dice.add_theme_font_size_override("font_size", 16)
	dice.pressed.connect(_on_random_name)
	name_row.add_child(dice)

	var gender_row = HBoxContainer.new()
	gender_row.add_theme_constant_override("separation", 8)
	column.add_child(gender_row)
	var group = ButtonGroup.new()
	for gender in ["male", "female"]:
		var chip = _toggle(gender.capitalize(), group, gender == profile["gender"])
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.pressed.connect(_on_gender.bind(gender))
		gender_row.add_child(chip)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	var colors = {"health": UiTheme.RED, "smarts": Color("5f86a8"), "looks": Color("a8658c"), "happiness": Color("b08a3c")}
	for key in STAT_KEYS:
		var bar = UiTheme.make_bar(colors[key])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(bar)
		stat_bars[key] = bar

	gold_label = UiTheme.label("", 15, UiTheme.DIM)
	column.add_child(gold_label)

	var reroll = Button.new()
	reroll.text = "Reroll fate"
	reroll.custom_minimum_size = Vector2(0, 50)
	reroll.set_meta("ui_sound", "page")
	reroll.pressed.connect(_reroll)
	column.add_child(reroll)
	return row


## Four small portraits: the same person as a child, a youth, in their prime and old.
func _build_stages():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for stage in STAGE_AGES:
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		var small = Portrait.new()
		small.custom_minimum_size = Vector2(96, 96)
		box.add_child(small)
		stage_portraits.append(small)
		var caption = UiTheme.label(stage[0], 13, UiTheme.DIM)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(caption)
		row.add_child(box)
	return row


func _build_backgrounds():
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var group = ButtonGroup.new()
	for background in BACKGROUNDS:
		var card = _toggle("", group, background["name"] == profile["background"])
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 88)
		card.pressed.connect(_on_background.bind(background["name"]))
		# Three lines of text inside the button, each with its own size and colour.
		var lines = VBoxContainer.new()
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.add_theme_constant_override("separation", 0)
		card.add_child(lines)
		lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
		lines.add_child(UiTheme.label(background["name"], 19))
		lines.add_child(UiTheme.label(background["line"], 14, UiTheme.DIM))
		lines.add_child(UiTheme.label(background["bonus"], 14, UiTheme.JADE))
		grid.add_child(card)
	return grid


func _build_talents():
	var flow = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	var group = ButtonGroup.new()
	for talent in TALENTS:
		var chip = _toggle(talent["name"], group, talent["name"] == profile["talent"])
		chip.add_theme_font_size_override("font_size", 17)
		chip.pressed.connect(_on_talent.bind(talent))
		flow.add_child(chip)
	return flow


## A button that stays lit while it is the selected one in its group.
func _toggle(text, group, selected):
	var button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.button_pressed = selected
	button.custom_minimum_size = Vector2(0, 46)
	return button
