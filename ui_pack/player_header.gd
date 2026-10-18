extends PanelContainer
## The top bar of the game screen: portrait, name, Health and Qi bars, and a row of stats.
##
## Use:
##     const PlayerHeader = preload("res://ui_pack/player_header.gd")
##     var header = PlayerHeader.new()
##     add_child(header)
##     header.set_player({
##         "name": "Ren", "gender": "male", "age": 17, "background": "Martial Clan", "faction": "",
##         "seed": 1234, "subtitle": "Third-Class  -  Martial Clan",
##         "health": 80, "max_health": 100, "qi": 30, "max_qi": 100,
##         "chips": [["STR", 12], ["AGI", 9], ["INS", 7], ["GOLD", 40]],
##     })
## Call set_player again whenever anything changes.

const UiTheme = preload("murim_theme.gd")
const Portrait = preload("portrait.gd")

var portrait
var name_label
var age_label
var subtitle_label
var health_bar
var qi_bar
var chip_row
var chip_labels = []      # one [value label, caption label] pair per chip


func _init():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	portrait = Portrait.new()
	portrait.custom_minimum_size = Vector2(132, 132)
	row.add_child(portrait)

	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	row.add_child(column)

	var top = HBoxContainer.new()
	column.add_child(top)
	name_label = UiTheme.label("", 26, UiTheme.GOLD)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	top.add_child(name_label)
	age_label = UiTheme.label("", 18, UiTheme.DIM)
	top.add_child(age_label)

	subtitle_label = UiTheme.label("", 15, UiTheme.DIM)
	subtitle_label.clip_text = true
	column.add_child(subtitle_label)

	health_bar = UiTheme.make_bar(UiTheme.RED, 22)
	column.add_child(health_bar)
	qi_bar = UiTheme.make_bar(UiTheme.JADE, 22)
	column.add_child(qi_bar)

	chip_row = HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 6)
	column.add_child(chip_row)


func set_player(player):
	portrait.set_profile(player)
	name_label.text = str(player.get("name", ""))
	age_label.text = "Age %d" % int(player.get("age", 0))
	subtitle_label.text = str(player.get("subtitle", ""))
	UiTheme.set_bar(health_bar, "Health", int(player.get("health", 0)), int(player.get("max_health", 100)))
	UiTheme.set_bar(qi_bar, "Qi", int(player.get("qi", 0)), int(player.get("max_qi", 100)))
	_set_chips(player.get("chips", []))


## Small "value over name" tiles. Rebuilt only when the number of chips changes.
func _set_chips(chips):
	if chip_labels.size() != chips.size():
		for child in chip_row.get_children():
			chip_row.remove_child(child)
			child.queue_free()
		chip_labels.clear()
		for chip in chips:
			var tile = PanelContainer.new()
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.INK, Color(UiTheme.GOLD, 0.20), 4, 5))
			var box = VBoxContainer.new()
			box.add_theme_constant_override("separation", -2)
			tile.add_child(box)
			var value = UiTheme.label("", 17)
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(value)
			var caption = UiTheme.label("", 11, UiTheme.DIM)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(caption)
			chip_row.add_child(tile)
			chip_labels.append([value, caption])
	for i in chips.size():
		chip_labels[i][0].text = str(chips[i][1])
		chip_labels[i][1].text = str(chips[i][0])
