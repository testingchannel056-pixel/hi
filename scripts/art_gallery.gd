extends Control
# Open art_gallery.tscn and press F6 to inspect the art and replay combat.
const ThemeArt = preload("res://scripts/game_theme.gd")
const Portrait = preload("res://ui_pack/portrait.gd")
const Stage = preload("res://scripts/battle_stage.gd")
const FighterArt = preload("res://scripts/fighter_art.gd")
const Data = preload("res://scripts/character_data.gd")
const Ui = preload("res://ui_pack/murim_theme.gd")
const SCENES = ["forest", "village", "mountain", "waterfall", "tavern", "shrine", "fire", "cave", "sect", "home"]
const FOES = ["bandit", "initiate", "duelist", "cultist", "person", "wolf", "beast"]
var stage
var scenery
var scene_picker
var status
var profile = {"gender": "Female", "age": 27, "seed": 413, "look": {"skin": 1, "hair": 3, "hair_colour": 0, "eye_colour": 3, "beard": 0}, "outfit": "martial", "backdrop": "wudang"}
var opponent = "duelist"
var busy = false
var selectors = []

func _ready():
	theme = ThemeArt.make()
	var back = ColorRect.new()
	back.color = Ui.INK
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	back.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column = VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	column.add_child(Ui.label("MURIM LIFE  /  ART STUDIO", 32, Ui.GOLD))
	var subtitle = Ui.label("Anime wuxia • appearance, environments & combat", 18, Ui.JADE)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)
	var portraits = HBoxContainer.new()
	portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(portraits)
	for age in [8, 17, 28, 70]:
		var stack = VBoxContainer.new()
		portraits.add_child(stack)
		var portrait = Portrait.new()
		portrait.custom_minimum_size = Vector2(142, 142)
		stack.add_child(portrait)
		var who = profile.duplicate(true)
		who["age"] = age
		portrait.set_profile(who)
		var label = Ui.label("Age %d" % age, 18, Ui.DIM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(label)
	var scene_choice = OptionButton.new()
	scene_picker = scene_choice
	for location in SCENES:
		scene_choice.add_item(location.capitalize())
	column.add_child(scene_choice)
	scene_choice.item_selected.connect(choose_scene)
	selectors.append(scene_choice)
	var frame = AspectRatioContainer.new()
	frame.ratio = 5.0 / 3.0
	frame.custom_minimum_size.y = 360
	column.add_child(frame)
	scenery = TextureRect.new()
	scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenery.stretch_mode = TextureRect.STRETCH_SCALE
	frame.add_child(scenery)
	stage = Stage.new()
	scenery.add_child(stage)
	stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stage.speed = 0.5
	choose_scene(0)
	var foe_choice = OptionButton.new()
	for fighter in FOES:
		foe_choice.add_item(fighter.capitalize())
	foe_choice.select(2)
	foe_choice.item_selected.connect(func(index): opponent = FOES[index]; reset_fight())
	column.add_child(foe_choice)
	selectors.append(foe_choice)
	var actions = HBoxContainer.new()
	column.add_child(actions)
	for kind in ["strike", "heavy", "qi"]:
		var button = Button.new()
		button.text = kind.capitalize()
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(play_move.bind(kind))
		actions.add_child(button)
		selectors.append(button)
	var extra = HBoxContainer.new()
	column.add_child(extra)
	for label in ["Guard", "Dodge", "Defeat", "Reset"]:
		var button = Button.new()
		button.text = label
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(extra_action.bind(label))
		extra.add_child(button)
		selectors.append(button)
	status = Ui.label("Choose a move to preview the animation.", 20, Ui.JADE)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var strip = HBoxContainer.new()
	column.add_child(strip)
	for name in ["hero", "bandit", "initiate", "duelist", "cultist", "wolf", "beast"]:
		var fighter = TextureRect.new()
		fighter.texture = FighterArt.texture(name, "idle", profile if name == "hero" else {})
		fighter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fighter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fighter.custom_minimum_size = Vector2(80, 128)
		strip.add_child(fighter)
	column.add_child(Ui.label("Each fighter has 7 poses. All 10 environments share one atlas.", 17, Ui.DIM))
	reset_fight()

func choose_scene(index):
	scene_picker.select(index)
	scenery.texture = load("res://assets/scenes/%s.tres" % SCENES[index])

func reset_fight():
	stage.set_profiles(profile, opponent)
	stage.begin(FighterArt.texture("hero", "idle", profile), FighterArt.texture(opponent), false)

func set_busy(value):
	busy = value
	for selector in selectors:
		selector.disabled = value

func play_move(kind):
	if busy:
		return
	set_busy(true)
	await stage.strike(true, kind, {"hit": true, "damage": 24 if kind == "qi" else 12}, func(): status.text = "%s landed • drawn pose + impact + recoil" % kind.capitalize())
	await get_tree().create_timer(0.25).timeout
	await stage.strike(false, "strike", {"hit": true, "damage": 8}, func(): status.text = "Opponent counterattack")
	set_busy(false)

func extra_action(action):
	if busy:
		return
	match action:
		"Reset": reset_fight(); status.text = "Ready."
		"Guard": stage.guard(true, not stage.hero_shield.visible); status.text = "Guard stance."
		"Defeat": stage.fall(false, false); status.text = "Defeat. Press Reset to replay."
		"Dodge":
			set_busy(true)
			await stage.strike(false, "strike", {"hit": false, "damage": 0}, func(): status.text = "Miss • evasive recoil")
			set_busy(false)
