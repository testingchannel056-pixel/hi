extends RefCounted

# Background, talent growth and life paths. The data is in life_data.gd;
# this script holds the rules. "game" is the main screen (game.gd), which
# does the writing on the page.

const Life = preload("res://scripts/life_data.gd")
const Needs = preload("res://scripts/requirements.gd")

var game


func _init(main_screen):
	game = main_screen


# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------

func background():
	return Life.BACKGROUNDS[game.player.background]


func is_orphan():
	return background().get("orphan", false)


# Sets up the family and the starting stats of a new life, and writes the
# opening lines of the first page.
func be_born():
	var player = game.player
	var info = background()
	if is_orphan():
		var caretaker = game.add_person("Caretaker", randi_range(55, 68), randi_range(55, 80))
		caretaker["occupation"] = "Temple Caretaker"
		game.write("Nobody knows who your parents were. The temple names you %s, and %s takes you in."
			% [player.full_name, caretaker["name"]])
	else:
		var father = game.add_person("Father", randi_range(22, 35), randi_range(60, 90))
		var mother = game.add_person("Mother", randi_range(20, 32), randi_range(70, 95))
		father["occupation"] = info.get("father", "")
		mother["occupation"] = info.get("mother", "")
		game.write("You are born into the murim world as %s, child of %s and %s."
			% [player.full_name, father["name"], mother["name"]])
		game.family.born()
	game.write("%s: %s" % [player.background, info["text"]], game.MUTED)
	# What the background gives you is applied quietly, as part of who you are.
	player.change(info.get("start", {}))
	for item in info.get("items", []):
		player.add_item(item)
	if player.talent != "None":
		game.write("Your talent: %s. %s" % [player.talent_name, player.talent_info["text"]], game.GOLD)


# The first choice of a life, and the choices on your first birthdays.
func birth_scenario():
	return Life.ORPHAN_BIRTH if is_orphan() else game.World.BIRTH


func milestones():
	return Life.ORPHAN_CHILDHOOD if is_orphan() else game.World.CHILDHOOD


# ---------------------------------------------------------------------------
# Talent growth
# ---------------------------------------------------------------------------

# Called on every birthday. The first step of a talent comes by itself once
# its needs are met. The second waits for its awakening scenario.
func check_talent():
	var player = game.player
	var step = player.next_talent_step()
	if step != null and player.talent_level == 0 and Needs.meets(game, step["needs"]):
		grow_talent()


# Moves the talent up one step and tells the player.
func grow_talent():
	var player = game.player
	var step = player.next_talent_step()
	if step == null:
		return
	player.talent_level += 1
	player.max_health += step.get("max_health", 0)
	player.refresh_talent(game.World.TALENTS)
	player.remember("your talent grew into %s." % step["name"])
	game.chime()
	game.write("Your talent grows: %s. %s" % [step["name"], step["text"]], game.GOLD)
	game.write_changes({"Happiness": 8})


# The awakening scenario for the player's talent, if now is the time for it:
# the talent has taken its first step and the needs of the second are met.
func awakening_scenario():
	var player = game.player
	var step = player.next_talent_step()
	if step == null or player.talent_level != 1 or not Needs.meets(game, step["needs"]):
		return null
	return Life.TALENT_SCENARIOS.get(player.talent)


# ---------------------------------------------------------------------------
# Life paths
# ---------------------------------------------------------------------------

func path():
	return Life.LIFE_PATHS.get(game.player.path, {})


# What is still missing before a path can be chosen ("" if nothing is).
# Your background can open a path with nothing but the age.
func path_blocked(path_name):
	var needs = Life.LIFE_PATHS[path_name]["needs"]
	if path_name in background().get("paths", []):
		needs = {"age": needs.get("age", 0)}
	return Needs.missing(game, needs)


# The Life path menu, opened from More.
func show_paths():
	var player = game.player
	var now = player.path if player.path != "" else "none yet"
	game.open_menu("Life path  ·  yours: %s  ·  actions left this month: %d" % [now, game.actions_left])
	for path_name in Life.LIFE_PATHS:
		if path_name == player.path:
			continue
		var blocked = path_blocked(path_name)
		var hint = Life.LIFE_PATHS[path_name]["text"]
		if blocked != "":
			hint = "%s  ·  %s" % [blocked, hint]
		var button = game.add_choice(path_name, hint, choose_path.bind(path_name))
		button.disabled = blocked != ""
	game.disable_without_actions()
	game.add_choice("Back", "", game.show_group.bind("Life"))


func choose_path(path_name):
	var player = game.player
	game.actions_left -= 1
	if player.path == "":
		game.write("You set your feet on a path: %s." % path_name, game.GOLD)
	else:
		game.write("You leave the life of a %s behind and become a %s." % [player.path.to_lower(), path_name.to_lower()], game.GOLD)
	game.write(Life.LIFE_PATHS[path_name]["text"], game.MUTED)
	player.path = path_name
	player.path_years = 0
	player.path_rank = 0
	player.count("paths")
	player.remember("took up the life of a %s." % path_name.to_lower())
	game.write("You start as a %s." % rank_name().to_lower(), game.MUTED)
	game.end_turn()


# Called on every birthday: talent growth, what your path pays, promotion,
# what your property brings, and the cost of living.
func yearly():
	var player = game.player
	check_talent()
	if player.path != "":
		player.path_years += 1
		game.write(path()["year_text"], game.MUTED)
		game.write_changes(yearly_pay())
		check_promotion()
	var income = {}
	for property in player.properties:
		var brings = Life.PROPERTIES[property]["yearly"]
		for stat in brings:
			income[stat] = income.get(stat, 0) + brings[stat]
	if not income.is_empty():
		game.write("Your property: %s." % ", ".join(player.properties), game.MUTED)
		game.write_changes(income)
	pay_living_cost()
	fade()


# The jianghu forgets. Every year a little of your Reputation and your Shame
# wears off. A name has to be kept up with deeds: someone who does a great
# deal still rises, someone who does a little now and then stays where they
# are. Karma does not fade: what you did, you did.
func fade():
	var player = game.player
	if player.age < Life.FADE_AGE:
		return
	for stat in Life.FADE:
		if player.stats[stat] > 0:
			player.stats[stat] = max(player.stats[stat] - 1 - player.stats[stat] / Life.FADE[stat], 0)


# ---------------------------------------------------------------------------
# Careers: ranks, pay and work
# ---------------------------------------------------------------------------

func ranks():
	return Life.CAREER_RANKS.get(game.player.path, [])


# What you are called on your path right now: "Shopkeeper", "Novice"...
func rank_name():
	var all = ranks()
	return all[min(game.player.path_rank, all.size() - 1)]["name"] if not all.is_empty() else ""


# The path's yearly reward, with the Gold raised for your rank.
func yearly_pay():
	var pay = path().get("yearly", {}).duplicate()
	if pay.get("Gold", 0) > 0:
		pay["Gold"] = int(pay["Gold"] * (1.0 + Life.RANK_PAY * game.player.path_rank))
	return pay


# Moves you up a rank once you have the years and meet the needs.
func check_promotion():
	var player = game.player
	var all = ranks()
	if player.path_rank + 1 >= all.size():
		return
	var next = all[player.path_rank + 1]
	if player.path_years >= next["years"] and Needs.meets(game, next.get("needs", {})):
		player.path_rank += 1
		player.count("promotions")
		player.remember("rose to %s." % next["name"])
		game.chime()
		game.write("You are now a %s." % next["name"], game.GOLD)
		game.write_changes(next.get("gain", {}))


# The Work action in More: a month of extra work at your trade.
func work_pay():
	var job = Life.WORK.get(game.player.path, Life.WORK[""])
	return int(job["gold"] * (1.0 + Life.RANK_PAY * game.player.path_rank))


func work():
	game.actions_left -= 1
	game.write(Life.WORK.get(game.player.path, Life.WORK[""])["text"], game.MUTED)
	game.write_changes({"Gold": work_pay()})
	game.player.count("worked")
	game.end_turn()


# ---------------------------------------------------------------------------
# Money: the cost of living, and property
# ---------------------------------------------------------------------------

func pay_living_cost():
	var player = game.player
	if player.age < Life.LIVING_AGE:
		return
	var cost = Life.LIVING_COST
	for child in game.npcs.alive("Child"):
		if child["age"] < 14:
			cost += Life.CHILD_COST
	# The more you have, the more of it goes on taxes, gifts and upkeep.
	if player.stats["Gold"] > Life.TAX_FREE:
		cost += int((player.stats["Gold"] - Life.TAX_FREE) * Life.TAX)
	if player.stats["Gold"] >= cost:
		game.write("A year of rice, rent, firewood and taxes.", game.MUTED)
		game.write_changes({"Gold": -cost})
	else:
		game.write("You cannot pay for a full year of rice and firewood. It is a hard one.", game.BAD)
		player.stats["Gold"] = 0
		game.write_changes(Life.HARD_YEAR)


# The Property menu, opened from the Market.
func show_property():
	var player = game.player
	game.open_menu("Property  ·  you have %d gold" % player.stats["Gold"])
	for property in Life.PROPERTIES:
		var info = Life.PROPERTIES[property]
		if property in player.properties:
			game.add_choice(property, "Yours  ·  %s" % info["text"], buy_property.bind(property)).disabled = true
		else:
			var button = game.add_choice(property, "Costs %d gold  ·  %s" % [info["price"], info["text"]], buy_property.bind(property))
			button.disabled = player.stats["Gold"] < info["price"]
	game.add_choice("Back", "", game.show_group.bind("Money"))


func buy_property(property):
	var player = game.player
	game.write("You put your seal on the deed. The %s is yours." % property.to_lower(), game.GOLD)
	game.write_changes({"Gold": -Life.PROPERTIES[property]["price"]})
	player.properties.append(property)
	game.refresh_screen()
	game.save_life()
	show_property()


# Extra training chance (in %) from your path.
func train_bonus(stat):
	return path().get("train", {}).get(stat, 0)


# Extra chance (in %) of an encounter each month.
func wander_bonus():
	return path().get("wander", 0)
