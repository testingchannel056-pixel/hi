extends SceneTree
# Run with a disposable user-data profile; see ART_UPDATE.md.
const Player = preload("res://scripts/player.gd")
const World = preload("res://scripts/world_data.gd")
const Art = preload("res://scripts/character_art.gd")
const Fighters = preload("res://scripts/fighter_art.gd")
const Data = preload("res://scripts/character_data.gd")
const Saves = preload("res://scripts/save_manager.gd")
var checks = 0
var failures = []
var landed_count = 0

func _initialize():
	call_deferred("run")

func check(condition, message):
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func landed():
	landed_count += 1

func screenshot(file):
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder = OS.get_environment("MURIM_ART_OUTPUT")
	if folder != "":
		check(root.get_texture().get_image().save_png(folder.path_join(file)) == OK, "Screenshot saved")

func run():
	root.size = Vector2i(720, 1280)
	var profile = {"gender": "Female", "age": 28, "seed": 413, "look": {"skin": 1, "hair": 3, "hair_colour": 0, "eye_colour": 3, "beard": 0}, "outfit": "martial", "backdrop": "wudang"}
	# All actual portrait choices must render, for both genders and life stages.
	for gender in ["Male", "Female"]:
		for age in [8, 17, 28, 70]:
			var who = profile.duplicate(true)
			who["gender"] = gender
			who["age"] = age
			check(Art.texture(who) != null, "Portrait %s age %d" % [gender, age])
		for part in Data.PARTS:
			for index in Data.options(part["key"], gender).size():
				var who = profile.duplicate(true)
				who["gender"] = gender
				who["look"][part["key"]] = index
				check(Art.texture(who) != null, "Appearance option renders")
	var before = Art.texture(profile).get_image().get_data()
	var changed = profile.duplicate(true)
	changed["look"]["skin"] = 5
	check(before != Art.texture(changed).get_image().get_data(), "Skin changes the rendered portrait")
	changed = profile.duplicate(true)
	changed["age"] = 70
	check(before != Art.texture(changed).get_image().get_data(), "Aging changes the rendered portrait")
	for fighter in Fighters.ART:
		for pose in ["idle", "windup", "attack", "qi", "guard", "hurt", "down"]:
			check(Fighters.texture(fighter, pose, profile) != null, "%s %s renders" % [fighter, pose])
	check(Fighters.texture("hero", "idle", profile).get_image().get_data() != Fighters.texture("hero", "attack", profile).get_image().get_data(), "Attack changes the actual limb drawing")
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.2).timeout
	var creation = main.creation
	creation.choose_gender("Female")
	creation.appearance = Data.complete(profile["look"], "Female", 413)
	creation.outfit = "martial"
	creation.backdrop = "wudang"
	creation.update_appearance_labels()
	creation.refresh_portraits()
	await create_timer(0.2).timeout
	var old_hair = creation.appearance["hair"]
	creation.change_appearance("hair", 1)
	check(creation.appearance["hair"] != old_hair, "Live appearance picker works")
	creation.change_appearance("hair", -1)
	check(not creation.appearance_rows["beard"].visible, "Female beard row hidden")
	await create_timer(0.2).timeout
	await screenshot("01-character-creation.png")
	creation.finish()
	check(main.player.appearance == creation.appearance, "Chosen appearance reaches real player")
	check(main.player.portrait_outfit == "martial", "Chosen outfit reaches real player")
	check(not creation.visible, "Begin enters game")
	var restored = Player.new()
	var encoded = JSON.stringify(main.player.to_data())
	restored.from_data(JSON.parse_string(encoded), World.TALENTS)
	check(Data.complete(restored.appearance, restored.gender) == Data.complete(main.player.appearance, main.player.gender), "JSON save round trip preserves appearance")
	check(restored.portrait_backdrop == "wudang", "JSON save preserves aura")
	var old_save = main.player.to_data()
	old_save.erase("appearance")
	old_save.erase("portrait_outfit")
	old_save.erase("portrait_backdrop")
	restored.from_data(old_save, World.TALENTS)
	check(restored.appearance.is_empty(), "Legacy saves load without appearance data")
	main.finish_typing()
	await create_timer(0.1).timeout
	await screenshot("02-gameplay.png")
	main.start_fight({"fight": "duelist", "image": "sect", "friendly": true})
	await process_frame
	check(main.battle.hero.texture != null and main.battle.foe.texture != null, "Actual game battle loads new fighters")
	main.queue_free()
	await process_frame
	var gallery = load("res://art_gallery.tscn").instantiate()
	root.add_child(gallery)
	await create_timer(0.1).timeout
	for i in gallery.SCENES.size():
		gallery.choose_scene(i)
		check(gallery.scenery.texture != null and gallery.scenery.texture.get_width() > 0, "Environment loads: " + gallery.SCENES[i])
	gallery.choose_scene(8)
	var stage = gallery.stage
	stage.speed = 0.05
	for opponent in gallery.FOES:
		gallery.opponent = opponent
		gallery.reset_fight()
		for kind in ["strike", "heavy", "qi"]:
			await stage.strike(true, kind, {"hit": true, "damage": 12}, landed)
			await stage.strike(false, kind, {"hit": false, "damage": 0}, landed)
	check(landed_count == gallery.FOES.size() * 6, "One gameplay callback per blow, hits and misses")
	stage.guard(true, true)
	check(stage.hero_shield.visible, "Guard visible")
	stage.guard(true, false)
	await create_timer(0.8).timeout
	check(stage.effects.bursts.is_empty(), "Transient impact effects expire")
	gallery.opponent = "duelist"
	gallery.reset_fight()
	stage.speed = 0.5
	await screenshot("03-art-studio.png")
	stage.strike(true, "qi", {"hit": true, "damage": 28}, landed)
	await create_timer(0.32).timeout
	await screenshot("04-qi-impact.png")
	await create_timer(0.5).timeout
	stage.fall(false, false)
	await create_timer(0.6).timeout
	check(abs(stage.foe.rotation) > 1.0, "Defeat pose completes")
	gallery.reset_fight()
	check(stage.foe.rotation == 0.0 and not stage.in_action, "New fight resets defeat state")
	stage.speed = 0
	var count_before = landed_count
	await stage.strike(true, "qi", {"hit": true, "damage": 2}, landed)
	check(landed_count == count_before + 1, "Instant combat still delivers callback")
	gallery.queue_free()
	await process_frame
	Art.cache.clear()
	Fighters.cache.clear()
	print("ART SMOKE: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
