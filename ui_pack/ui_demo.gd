extends Control
## A small demo that shows the whole pack working together. Not part of the real game.
##
## Run ui_demo.tscn (F6). You get the character creation screen, then a sample game
## screen with the header bar, a story panel and choices. The "Age +6" button exists
## only so you can watch the portrait grow from child to elder.

const UiTheme = preload("murim_theme.gd")
const Creator = preload("character_creator.gd")
const PlayerHeader = preload("player_header.gd")

const STAGES = ["Commoner", "Third-Class", "Second-Class", "First-Class", "Peak", "Transcendent", "Immortal"]

var player = {}
var header
var story
var choices


func _ready():
	theme = UiTheme.make()
	var paper = ColorRect.new()
	paper.color = UiTheme.INK
	add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_show_creator()


func _show_creator():
	var creator = Creator.new()
	add_child(creator)
	creator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	creator.life_chosen.connect(_on_life_chosen.bind(creator))


func _on_life_chosen(profile, creator):
	creator.queue_free()
	player = profile
	player["age"] = 8
	player["max_health"] = 100
	player["qi"] = 0
	player["max_qi"] = 100
	player["faction"] = ""
	_show_game()


func _show_game():
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	header = PlayerHeader.new()
	root.add_child(header)

	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	story = RichTextLabel.new()
	story.bbcode_enabled = true
	story.fit_content = true
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_theme_font_size_override("normal_font_size", 20)
	scroll.add_child(story)

	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	root.add_child(choices)

	# Bottom bar, like the More menu groups in the design.
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	root.add_child(bar)
	for text in ["Life", "Martial", "Age +6", "Jianghu", "More"]:
		var button = Button.new()
		button.text = text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 17)
		if text == "Age +6":
			button.add_theme_color_override("font_color", UiTheme.GOLD)
			button.set_meta("ui_sound", "page")
			button.pressed.connect(_on_age)
		bar.add_child(button)

	_refresh_header()
	_show_event()


func _refresh_header():
	var shown = player.duplicate()
	var place = player["faction"] if player["faction"] != "" else player["background"]
	shown["subtitle"] = "%s  -  %s" % [STAGES[0], place]
	shown["chips"] = [["SMARTS", player["smarts"]], ["LOOKS", player["looks"]], ["HAPPY", player["happiness"]], ["GOLD", player["gold"]]]
	header.set_player(shown)


func _show_event():
	story.clear()
	story.append_text("[font_size=26][color=#c9a961]The Old Beggar[/color][/font_size]\n\n")
	story.append_text("At the edge of the market, an old beggar with clear eyes holds out a [color=#c9a961]strange black pill[/color].\n")
	_set_choices([
		["Eat it\nLuck  -  Difficult", "Warmth floods your meridians. The beggar is gone when you look up.", "qi", 20],
		["Refuse politely", "He chuckles. \"Caution is also a kind of talent.\"", "happiness", 2],
		["Join Mount Hua instead (demo)", "Plum blossoms fall as you put on the white robe.", "faction", "Mount Hua"],
	])


func _set_choices(list):
	for child in choices.get_children():
		child.queue_free()
	for item in list:
		var button = Button.new()
		button.text = item[0]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 60)
		button.set_meta("ui_sound", "choice")
		button.pressed.connect(_on_choice.bind(item))
		choices.add_child(button)


func _on_choice(item):
	story.append_text("\n[color=#8a8676]> %s[/color]\n\n%s\n" % [item[0].get_slice("\n", 0), item[1]])
	if item[2] == "faction":
		player["faction"] = item[3]
	else:
		player[item[2]] = int(player[item[2]]) + int(item[3])
		story.append_text("[color=#5fa88f]+ %s %d[/color]\n" % [str(item[2]).capitalize(), item[3]])
		if get_node_or_null("/root/UiSounds") != null:
			get_node("/root/UiSounds").play("reward")
	_refresh_header()
	_set_choices([["Continue", "", "", 0]])
	choices.get_child(choices.get_child_count() - 1).pressed.connect(_show_event)


func _on_age():
	player["age"] += 6
	story.append_text("\n[center][color=#8a8676]- Age %d -[/color][/center]\n" % player["age"])
	_refresh_header()
