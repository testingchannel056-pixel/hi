extends Control

# The picture of a fight, drawn on top of the page's illustration: you on the
# left, your opponent on the right. game.gd rolls the dice and tells this
# script what happened. This script only shows it.
#
# The fighters are the pictures in assets/fighters, all drawn facing right.
# To use your own art, put a PNG with the same name in that folder: wolf.png
# is used instead of wolf.svg.

const FighterArt = preload("res://scripts/fighter_art.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")

const PICTURE_SHAPE = 640.0 / 384.0   # the shape of the pictures in assets/scenes
const FIGHTER_SHAPE = 200.0 / 240.0   # the shape of the pictures in assets/fighters
const FIGHTER_HEIGHT = 0.66           # how tall a fighter stands, as a share of the picture
const GROUND = 0.95                   # where the feet are, as a share of the picture height
const HURT = Color(1.0, 0.45, 0.4)    # the flash of someone who was just hit
const GLOW = Color(0.55, 0.9, 1.0)    # Qi and guards
const PLAN_NAMES = {"": "", "strike": "Strike", "heavy": "Heavy blow!", "guard": "Guarding"}

var hero_profile = {}
var foe_name = "bandit"
var effects = CombatEffects.new()
var ground_art = CombatEffects.new()
var in_action = false
var active_tweens = []
var guarded = [false, false]

var speed = 0.35              # seconds one blow takes (0 skips the movement)
var box = Control.new()       # the part of this node that the picture covers
var flash = Panel.new()
var flash_style = StyleBoxFlat.new()
var hero = TextureRect.new()
var foe = TextureRect.new()
var hero_shield = Panel.new()
var foe_shield = Panel.new()
var aura = Panel.new()
var plan_label = Label.new()
var hero_home = Vector2.ZERO  # where each fighter stands between blows
var foe_home = Vector2.ZERO
var foe_tint = Color.WHITE    # the foe turns a little red while winding up
var small_hero = false        # a young hero is drawn smaller
var breathing = null


func _ready():
	box.clip_contents = true
	box.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(box)
	ground_art.ground_only = true
	box.add_child(ground_art)

	flash_style.bg_color = Color.WHITE
	flash.add_theme_stylebox_override("panel", flash_style)
	flash.modulate.a = 0.0
	flash.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(flash)

	for shield in [hero_shield, foe_shield]:
		var ring = StyleBoxFlat.new()
		ring.bg_color = Color(GLOW, 0.14)
		ring.border_color = Color(GLOW, 0.85)
		ring.set_border_width_all(3)
		ring.set_corner_radius_all(400)
		ring.corner_detail = 16
		shield.add_theme_stylebox_override("panel", ring)
		shield.mouse_filter = MOUSE_FILTER_IGNORE
		shield.hide()
		box.add_child(shield)

	for fighter in [hero, foe]:
		fighter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fighter.stretch_mode = TextureRect.STRETCH_SCALE
		fighter.mouse_filter = MOUSE_FILTER_IGNORE
		box.add_child(fighter)
	foe.flip_h = true   # the pictures face right; your opponent faces you

	# The glow behind you during a Qi strike. It is part of the hero, so it
	# moves with them.
	var glow = StyleBoxFlat.new()
	glow.bg_color = Color(GLOW, 0.3)
	glow.set_corner_radius_all(400)
	glow.corner_detail = 16
	glow.shadow_color = Color(GLOW, 0.35)
	glow.shadow_size = 14
	aura.add_theme_stylebox_override("panel", glow)
	aura.set_anchors_preset(PRESET_FULL_RECT)
	aura.show_behind_parent = true
	aura.mouse_filter = MOUSE_FILTER_IGNORE
	aura.hide()
	hero.add_child(aura)

	var plate = StyleBoxFlat.new()
	plate.bg_color = Color(0.05, 0.065, 0.08, 0.82)
	plate.set_corner_radius_all(8)
	plate.content_margin_left = 10
	plate.content_margin_right = 10
	plate.content_margin_top = 2
	plate.content_margin_bottom = 2
	plan_label.add_theme_stylebox_override("normal", plate)
	plan_label.add_theme_font_size_override("font_size", 18)
	plan_label.hide()
	box.add_child(plan_label)

	effects.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(effects)
	resized.connect(place)
	visibility_changed.connect(breathe)


# Sets the scene for a new fight.
func begin(hero_picture, foe_picture, young):
	for tween in active_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	active_tweens.clear()
	in_action = false
	guarded = [false, false]
	effects.clear()
	small_hero = young
	hero.texture = FighterArt.texture("hero", "idle", hero_profile) if not hero_profile.is_empty() else hero_picture
	foe.texture = FighterArt.texture(foe_name, "idle") if not hero_profile.is_empty() else foe_picture
	foe_tint = Color.WHITE
	for fighter in [hero, foe]:
		fighter.modulate = Color.WHITE
		fighter.rotation = 0.0
		fighter.scale = Vector2.ONE
	guard(true, false)
	aura.hide()
	show_plan("")
	show()
	place()
	breathe()


# Stands both fighters in their places. It runs again whenever the page
# changes size.
func place():
	var width = min(size.x, size.y * PICTURE_SHAPE)
	box.size = Vector2(width, width / PICTURE_SHAPE)
	box.position = (size - box.size) / 2
	effects.size = box.size
	ground_art.size = box.size
	ground_art.queue_redraw()
	flash.size = box.size
	flash_style.set_corner_radius_all(int(width * 5.0 / 160.0))
	var tall = box.size.y * FIGHTER_HEIGHT
	var ground = box.size.y * GROUND
	hero_home = stand(hero, hero_shield, box.size.x * 0.27, ground, tall * (0.8 if small_hero else 1.0))
	foe_home = stand(foe, foe_shield, box.size.x * 0.73, ground, tall)
	place_plan()


func stand(fighter, shield, x, ground, tall):
	fighter.size = Vector2(tall * FIGHTER_SHAPE, tall)
	fighter.position = Vector2(x - fighter.size.x / 2, ground - tall)
	fighter.pivot_offset = Vector2(fighter.size.x / 2, tall)   # turn and stretch from the feet
	shield.size = fighter.size * Vector2(0.92, 1.0)
	shield.position = fighter.position + Vector2(fighter.size.x * 0.04, 0)
	return fighter.position


# A slow rise and fall, so the fighters do not look frozen.
func breathe():
	if breathing != null:
		breathing.kill()
		breathing = null
	if not is_visible_in_tree() or in_action:
		return
	breathing = create_tween().set_loops()
	breathing.tween_property(hero, "scale:y", 1.03, 0.9).set_trans(Tween.TRANS_SINE)
	breathing.parallel().tween_property(foe, "scale:y", 1.03, 0.9).set_trans(Tween.TRANS_SINE).set_delay(0.3)
	breathing.tween_property(hero, "scale:y", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	breathing.parallel().tween_property(foe, "scale:y", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_delay(0.3)


# Shows what your opponent is about to do, above their head ("" hides it).
func show_plan(plan):
	plan_label.text = PLAN_NAMES[plan]
	plan_label.visible = plan != ""
	plan_label.add_theme_color_override("font_color", HURT if plan == "heavy" else Color("e8e2d2"))
	foe_tint = Color(1.0, 0.78, 0.72) if plan == "heavy" else Color.WHITE
	foe.modulate = foe_tint
	guard(false, plan == "guard")
	place_plan()


func place_plan():
	plan_label.reset_size()
	plan_label.position = Vector2(foe_home.x + foe.size.x / 2 - plan_label.size.x / 2,
		max(foe_home.y - plan_label.size.y - 4, 8))


# Raises or lowers the glowing guard around a fighter. "you" is true for
# your own.
func guard(you, on):
	guarded[0 if you else 1] = on
	(hero_shield if you else foe_shield).visible = on
	if not in_action:
		set_pose(you, "guard" if on else "idle")



# Plays one blow and waits until it is over.
#   you     - true when you are the one attacking
#   kind    - "strike", "heavy" or "qi"
#   blow    - {"hit": true, "damage": 12}, as rolled by game.gd
#   landed  - a function to call at the moment the blow lands (game.gd uses
#             it to move the health bars)
func strike(you, kind, blow, landed):
	if speed <= 0 or not is_visible_in_tree():
		landed.call()
		return
	in_action = true
	breathe()
	for fighter in [hero, foe]:
		fighter.scale = Vector2.ONE
	set_pose(you, "windup")
	var attacker = hero if you else foe
	var target = foe if you else hero
	var home = hero_home if you else foe_home
	var target_home = foe_home if you else hero_home
	var forward = 1.0 if you else -1.0
	var reach = (foe_home.x - hero_home.x) * 0.55 * forward
	var big = kind != "strike"
	plan_label.hide()

	# A small step back, then the lunge.
	aura.visible = kind == "qi"
	var lunge = create_tween()
	lunge.tween_property(attacker, "position:x", home.x - reach * 0.12, speed * 0.25)
	lunge.tween_property(attacker, "position:x", home.x + reach, speed * 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_tweens.append(lunge)
	lunge.tween_callback(set_pose.bind(you, "qi" if kind == "qi" else "attack"))
	await lunge.finished

	# The moment the blow lands, or does not.
	landed.call()
	var shove = forward * (26 if big else 14)
	if blow["hit"]:
		set_pose(not you, "hurt")
		effects.burst(target.position + target.size * Vector2(0.5, 0.55), forward, kind)
		slash(target, forward, GLOW if kind == "qi" else Color("ffe6a4"), big)
		if big:
			shake(7.0 if kind == "qi" else 4.0)
		await get_tree().create_timer(min(speed * 0.12, 0.045)).timeout
		float_text("-%d" % blow["damage"], target, Color.WHITE if you else HURT, 40 if big else 30)
		target.modulate = HURT
		if big:
			flash.modulate.a = 0.4
			create_tween().tween_property(flash, "modulate:a", 0.0, 0.3)
	else:
		float_text("Miss", target, Color("e8e2d2"), 26)
		shove = forward * 22
	var recoil = create_tween()
	recoil.tween_property(target, "position:x", target_home.x + shove, speed * 0.2)
	recoil.tween_property(target, "position:x", target_home.x, speed * 0.3)
	recoil.parallel().tween_property(target, "modulate", foe_tint if you else Color.WHITE, speed * 0.3)

	var back = create_tween()
	back.tween_property(attacker, "position:x", home.x, speed * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tweens.append(recoil)
	active_tweens.append(back)
	await back.finished
	aura.hide()
	in_action = false
	hero.position = hero_home
	foe.position = foe_home
	set_pose(true, "guard" if guarded[0] else "idle")
	set_pose(false, "guard" if guarded[1] else "idle")
	active_tweens.clear()
	breathe()


# A number (or "Miss") that rises from a fighter and fades away.
func float_text(text, fighter, color, font_size):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08))
	label.add_theme_constant_override("outline_size", font_size / 5)
	box.add_child(label)
	label.reset_size()
	label.position = fighter.position + Vector2(fighter.size.x / 2 - label.size.x / 2, -8)
	var rise = create_tween()
	rise.tween_property(label, "position:y", label.position.y - 54, 0.75) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise.parallel().tween_property(label, "modulate:a", 0.0, 0.75) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rise.tween_callback(label.queue_free)


# A quick curved cut across a fighter.
func slash(fighter, forward, color, big):
	var cut = Line2D.new()
	var taper = Curve.new()
	taper.add_point(Vector2(0.0, 0.0))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.0))
	cut.width_curve = taper
	cut.width = 14 if big else 9
	cut.default_color = color
	var centre = fighter.position + fighter.size * Vector2(0.5, 0.6)
	var length = fighter.size.y * (0.42 if big else 0.32)
	var start = centre + Vector2(-length * 0.7 * forward, -length)
	var bend = centre + Vector2(length * 0.9 * forward, -length * 0.3)
	var end = centre + Vector2(length * 0.4 * forward, length)
	for step in 9:
		var t = step / 8.0
		cut.add_point(start.lerp(bend, t).lerp(bend.lerp(end, t), t))
	box.add_child(cut)
	var fade = create_tween()
	fade.tween_property(cut, "modulate:a", 0.0, 0.28)
	fade.tween_callback(cut.queue_free)


# The loser goes down at the winner's feet. "gently" is for a friendly duel:
# they only bow.
func fall(you, gently):
	in_action = true
	breathe()
	set_pose(you, "guard" if gently else "down")
	var loser = hero if you else foe
	var winner = foe if you else hero
	var turn = (1.0 if you else -1.0) * (0.3 if gently else 1.3)
	var fade = 0.9 if gently else 0.6
	# Draw the loser first, so they lie behind the winner.
	if loser.get_index() > winner.get_index():
		box.move_child(loser, winner.get_index())
	if speed <= 0 or not is_visible_in_tree():
		loser.rotation = turn
		loser.modulate.a = fade
		return
	var drop = create_tween()
	drop.tween_property(loser, "rotation", turn, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.parallel().tween_property(loser, "modulate:a", fade, 0.5)


func set_profiles(profile, opponent):
	hero_profile = profile.duplicate(true)
	foe_name = opponent


func set_pose(you, pose):
	if hero_profile.is_empty():
		return
	var fighter = hero if you else foe
	fighter.texture = FighterArt.texture("hero" if you else foe_name, pose, hero_profile if you else {})


func shake(strength):
	var home = box.position
	var tween = create_tween()
	for i in 4:
		var amount = strength * (1.0 - i / 4.0)
		tween.tween_property(box, "position", home + Vector2(amount * (-1 if i % 2 else 1), amount * 0.3), 0.025)
	tween.tween_property(box, "position", home, 0.04)
	active_tweens.append(tween)
