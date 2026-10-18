extends RefCounted

# Martial techniques: learning them, practising them, and what they add to
# a fight. The data is in martial_data.gd. "game" is the main screen.

const Data = preload("res://scripts/martial_data.gd")
const Needs = preload("res://scripts/requirements.gd")

var game


func _init(main_screen):
	game = main_screen


func exists(technique):
	return Data.TECHNIQUES.has(technique)


func knows(technique):
	return game.player.techniques.has(technique)


func level(technique):
	return game.player.techniques.get(technique, 0)


func title(technique):
	return Data.TECHNIQUES[technique]["name"] if exists(technique) else technique.capitalize()


# Learns a technique, or deepens one you already know. Tells the player.
func learn(technique):
	var player = game.player
	if not exists(technique):
		return
	if not knows(technique):
		player.techniques[technique] = 1
		player.count("techniques")
		game.chime()
		game.write("You learn a technique: %s. %s" % [title(technique), Data.TECHNIQUES[technique]["text"]], game.GOLD)
	elif level(technique) < Data.MAX_LEVEL:
		player.techniques[technique] += 1
		game.chime()
		game.write("Your %s deepens. It is now level %d." % [title(technique), level(technique)], game.GOLD)


# Adds up one kind of effect over everything you know: bonus("damage")
# is the damage all your techniques add to a blow.
func bonus(effect):
	var total = 0.0
	for technique in game.player.techniques:
		if exists(technique):
			total += Data.TECHNIQUES[technique].get(effect, 0) * level(technique)
	return total


# What your techniques bring on a birthday.
func yearly():
	for technique in game.player.techniques:
		if exists(technique) and Data.TECHNIQUES[technique].has("yearly"):
			game.write_changes(Data.TECHNIQUES[technique]["yearly"])


# ---------------------------------------------------------------------------
# Fight moves from techniques
# ---------------------------------------------------------------------------

# The extra moves you have in a fight: a list of [technique, move] pairs.
func moves():
	var found = []
	for technique in game.player.techniques:
		if exists(technique) and Data.TECHNIQUES[technique].has("move"):
			found.append([technique, Data.MOVES[Data.TECHNIQUES[technique]["move"]]])
	return found


# What a Qi strike costs you, after techniques that make it cheaper.
func qi_strike_cost(base):
	return max(base - int(bonus("qi_saving")), 1)


# ---------------------------------------------------------------------------
# The Martial arts menu (in More): what you know, and practising it
# ---------------------------------------------------------------------------

func show_techniques():
	var player = game.player
	game.open_menu("Martial arts  ·  actions left this month: %d" % game.actions_left)
	if player.techniques.is_empty():
		game.add_caption("You know no techniques yet. Masters, sects, manuals and strange encounters teach them.")
	for technique in player.techniques:
		if not exists(technique):
			continue
		var info = Data.TECHNIQUES[technique]
		var now = level(technique)
		var hint = "%s  ·  level %d  ·  %s" % [info["type"], now, info["text"]]
		if now < Data.MAX_LEVEL:
			hint += "  ·  practice: %d%% to reach level %d" % [practice_chance(technique), now + 1]
		var button = game.add_choice("Practise %s" % info["name"], hint, practise.bind(technique))
		button.disabled = now >= Data.MAX_LEVEL or game.actions_left <= 0
	game.add_choice("Back", "", game.show_group.bind("Martial"))


func practice_chance(technique):
	var base = Data.PRACTICE_CHANCE[clamp(level(technique) - 1, 0, Data.PRACTICE_CHANCE.size() - 1)]
	return clamp(base + game.player.stats["Martial Insight"] / 2, 5, 95)


func practise(technique):
	game.actions_left -= 1
	game.write("You go through the forms of %s until your body stops arguing." % title(technique), game.MUTED)
	if randi_range(1, 100) <= practice_chance(technique):
		learn(technique)
	else:
		game.write("No breakthrough this month. The forms are a little smoother.", game.MUTED)
	game.player.count("trained")
	game.end_turn()


# ---------------------------------------------------------------------------
# Learning from a master or from your sect
# ---------------------------------------------------------------------------

# Adds "Learn ..." choices to a master's page in Relationships.
func add_master_lessons(master):
	var player = game.player
	if master["role"] != "Master":
		return
	for technique in Data.MASTER_TEACHES:
		if knows(technique):
			continue
		var info = Data.TECHNIQUES[technique]
		var blocked = Needs.missing(game, info.get("needs", {}))
		if blocked == "" and master["bond"] < Data.TEACH_BOND:
			blocked = "Needs bond %d" % Data.TEACH_BOND
		if blocked == "" and player.stats["Gold"] < Data.TEACH_COST:
			blocked = "Needs %d gold for a gift" % Data.TEACH_COST
		var hint = "%s  ·  %s" % [blocked if blocked != "" else "A gift of %d gold" % Data.TEACH_COST, info["text"]]
		var button = game.add_choice("Learn %s" % info["name"], hint, take_lesson.bind(technique, Data.TEACH_COST, master))
		button.disabled = blocked != ""


# The techniques your sect will teach you now: a list of [technique, why not].
func sect_lessons():
	var player = game.player
	var found = []
	var taught = Data.SECT_TEACHES.get(player.sect, {})
	for technique in taught:
		if knows(technique):
			continue
		var blocked = Needs.missing(game, Data.TECHNIQUES[technique].get("needs", {}))
		if player.rank() < taught[technique]:
			blocked = "Needs the rank of %s" % player.RANKS[taught[technique]]
		elif blocked == "" and player.stats["Gold"] < Data.SECT_TEACH_COST:
			blocked = "Needs %d gold" % Data.SECT_TEACH_COST
		found.append([technique, blocked])
	return found


# Adds "Learn ..." choices to the Sect menu.
func add_sect_lessons():
	for lesson in sect_lessons():
		var info = Data.TECHNIQUES[lesson[0]]
		var hint = "%s  ·  %s" % [lesson[1] if lesson[1] != "" else "Costs %d gold" % Data.SECT_TEACH_COST, info["text"]]
		var button = game.add_choice("Learn %s" % info["name"], hint, take_lesson.bind(lesson[0], Data.SECT_TEACH_COST, null))
		button.disabled = lesson[1] != ""


func take_lesson(technique, cost, master):
	game.actions_left -= 1
	if master != null:
		game.write("%s watches you fail for a month, corrects one finger, and suddenly it works." % master["name"], game.MUTED)
		game.npcs.remember(master, "Taught you %s." % title(technique))
	else:
		game.write("The instructors of %s drill it into you until you could do it asleep." % game.player.sect, game.MUTED)
	game.write_changes({"Gold": -cost})
	learn(technique)
	game.end_turn()
