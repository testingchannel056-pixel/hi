extends RefCounted

# Family: brothers and sisters, courtship, marriage and children. The people
# themselves are looked after by npc_manager.gd; this script adds what is
# special about family. "game" is the main screen (game.gd).

const SIBLING_CHANCE = 50     # % chance to be born with an older brother or sister
const YOUNGER_CHANCE = 12     # % chance a year (until you are 12) that a younger one is born
const COURT_BOND = 60         # bond needed before you can court someone
const PROPOSE_BOND = 75       # bond needed before you can propose
const WEDDING_COST = 30       # Gold a wedding costs
const MATCHMAKER_COST = 15    # Gold the matchmaker charges
const MARRY_AGE = 18          # youngest age at which you can marry
const CHILD_CHANCE = 22       # % chance a year that a married couple has a child
const CHILD_LIMIT = 4         # the most children you can have
const PARENT_AGE = 45         # after this age no more children are born
const CALLING_AGE = 14        # the age at which a child chooses what to become

var game


func _init(main_screen):
	game = main_screen


# Called once when a life begins, after the parents exist.
func born():
	if game.npcs.has("Mother") and randi_range(1, 100) <= SIBLING_CHANCE:
		var sibling = game.npcs.make("Sibling", randi_range(1, 8), randi_range(40, 70))
		game.write("%s, your older %s, peers into the cradle." % [sibling["name"], brother_or_sister(sibling)], game.MUTED)


func brother_or_sister(person):
	return "brother" if person["gender"] == "Male" else "sister"


func son_or_daughter(person):
	return "son" if person["gender"] == "Male" else "daughter"


# ---------------------------------------------------------------------------
# The years passing
# ---------------------------------------------------------------------------

# Called on every birthday.
func yearly():
	var player = game.player
	var npcs = game.npcs
	# A younger brother or sister may arrive while you are small.
	var mother = npcs.first("Mother")
	if mother != null and npcs.has("Father") and player.age < 12 and mother["age"] < 42 \
			and npcs.alive("Sibling").size() < 3 and randi_range(1, 100) <= YOUNGER_CHANCE:
		var sibling = npcs.make("Sibling", 0, 50)
		npcs.remember(sibling, "Born.")
		game.write("Your mother gives birth to %s, your little %s." % [sibling["name"], brother_or_sister(sibling)], game.GOLD)
		game.write_changes({"Happiness": 4})
	# A married couple may have a child.
	var spouse = npcs.first("Spouse")
	if spouse != null and player.age <= PARENT_AGE and spouse["age"] <= PARENT_AGE \
			and children().size() < CHILD_LIMIT and randi_range(1, 100) <= CHILD_CHANCE:
		var child = npcs.make("Child", 0, 70, {"study": 0, "training": 0})
		npcs.remember(child, "Born.")
		player.count("children")
		player.remember("had a %s, %s." % [son_or_daughter(child), child["name"]])
		game.write("%s and you have a %s: %s." % [spouse["name"], son_or_daughter(child), child["name"]], game.GOLD)
		game.write_changes({"Happiness": 12})
	# Children choose what to become.
	for child in npcs.alive("Child"):
		if child["age"] == CALLING_AGE and child["occupation"] == "":
			choose_calling(child)


# All your children, living or not.
func children():
	var found = []
	for person in game.people:
		if person["role"] == "Child":
			found.append(person)
	return found


# At fourteen a child chooses a calling. What you taught them decides it.
func choose_calling(child):
	var player = game.player
	var study = child.get("study", 0)
	var training = child.get("training", 0)
	if training >= 3 and training >= study:
		child["occupation"] = "Sect Disciple"
		child["sect"] = player.sect if player.sect != "" else game.World.SECTS.keys().pick_random()
		game.write("%s has chosen the martial path and enters %s as a disciple." % [child["name"], child["sect"]], game.GOLD)
	elif study >= 3:
		child["occupation"] = "Scholar"
		game.write("%s has chosen the brush over the sword and becomes a scholar." % child["name"], game.GOLD)
	else:
		child["occupation"] = game.npcs.Data.OCCUPATIONS.pick_random()
		game.write("%s, left to choose alone, becomes a %s." % [child["name"], child["occupation"].to_lower()], game.MUTED)
	game.npcs.remember(child, "Became a %s." % child["occupation"].to_lower())


# ---------------------------------------------------------------------------
# What you can do with a person, added to their page in Relationships
# ---------------------------------------------------------------------------

func add_actions(person):
	var player = game.player
	var role = person["role"]
	var single = not game.npcs.has("Partner") and not game.npcs.has("Spouse")
	if role in ["Friend", "Acquaintance"] and single and not person["married"] \
			and player.age >= 16 and person["age"] >= 16:
		var odds = clamp(person["bond"] + player.stats["Looks"] / 5 - 30, 5, 95)
		var button = game.add_choice("Court %s" % person["name"], "Needs bond %d  ·  chance %d%%" % [COURT_BOND, odds], court.bind(person, odds))
		button.disabled = person["bond"] < COURT_BOND
	if role == "Partner":
		var button = game.add_choice("Propose marriage", "Needs bond %d, age %d and %d gold for the wedding" %
			[PROPOSE_BOND, MARRY_AGE, WEDDING_COST], propose.bind(person))
		button.disabled = person["bond"] < PROPOSE_BOND or player.age < MARRY_AGE or player.stats["Gold"] < WEDDING_COST
		game.add_choice("Part ways", "You will go back to being friends, if that", part.bind(person))
	if role == "Child" and person["age"] >= 4 and person["age"] < CALLING_AGE:
		game.add_choice("Teach %s letters" % person["name"], "Leans them towards a scholar's life", raise.bind(person, "study"))
		if person["age"] >= 6:
			game.add_choice("Train %s" % person["name"], "Leans them towards the martial path", raise.bind(person, "training"))


func court(person, odds):
	game.actions_left -= 1
	game.write("You tell %s what you have been thinking for a long time." % person["name"], game.MUTED)
	if randi_range(1, 100) <= odds:
		person["role"] = "Partner"
		game.npcs.remember(person, "You became a couple.")
		game.write("%s has been thinking the same thing. You are a couple now." % person["name"], game.GOLD)
		game.write_changes({"Happiness": 10})
	else:
		person["bond"] = max(person["bond"] - 8, 0)
		game.write("%s is kind about it, which is somehow worse." % person["name"], game.BAD)
		game.write_changes({"Happiness": -6})
	game.end_turn()


func propose(person):
	var player = game.player
	game.actions_left -= 1
	person["role"] = "Spouse"
	person["married"] = true
	game.npcs.remember(person, "You married.")
	player.count("marriages")
	player.remember("married %s." % person["name"])
	game.write("You marry %s under red lanterns. Half the village comes for the food." % person["name"], game.GOLD)
	game.write_changes({"Gold": -WEDDING_COST, "Happiness": 15, "Reputation": 2})
	game.end_turn()


func part(person):
	person["role"] = "Friend" if game.npcs.alive("Friend").size() < game.World.ROLES["Friend"].get("most", 1) else "Acquaintance"
	person["bond"] = max(person["bond"] - 30, 0)
	game.npcs.remember(person, "You parted ways.")
	game.write("%s and you part ways. It is nobody's fault, and it hurts anyway." % person["name"], game.MUTED)
	game.write_changes({"Happiness": -8})
	game.end_turn()


# Teaching or training a child: it brings you closer and shapes what they
# will choose to become.
func raise(child, what):
	game.actions_left -= 1
	child[what] = child.get(what, 0) + 1
	child["bond"] = min(child["bond"] + 6, 100)
	if what == "study":
		game.write("You sit with %s over the first thousand characters." % child["name"], game.MUTED)
	else:
		game.write("You show %s how to stand, how to fall, and how to get up." % child["name"], game.MUTED)
	game.write("Bond with %s +6" % child["name"], game.GOOD)
	game.end_turn()


# ---------------------------------------------------------------------------
# The matchmaker (in More, for the unattached)
# ---------------------------------------------------------------------------

func can_visit_matchmaker():
	var npcs = game.npcs
	return game.player.age >= MARRY_AGE and not npcs.has("Partner") and not npcs.has("Spouse") \
		and npcs.alive("Acquaintance").size() < game.World.ROLES["Acquaintance"].get("most", 1)


func visit_matchmaker():
	var player = game.player
	game.actions_left -= 1
	game.write("The matchmaker looks you up and down, sighs, and says she will see what can be done.", game.MUTED)
	game.write_changes({"Gold": -MATCHMAKER_COST})
	var match_gender = "Female" if player.gender == "Male" else "Male"
	var person = game.npcs.make("Acquaintance", max(player.age + randi_range(-4, 3), 17), randi_range(25, 45),
		{"gender": match_gender, "occupation": game.npcs.Data.OCCUPATIONS.pick_random()})
	game.npcs.remember(person, "Introduced by the matchmaker.")
	game.write("She introduces you to %s, a %s, %d years old. The rest is up to the two of you." %
		[person["name"], person["occupation"].to_lower(), person["age"]], game.GOLD)
	game.end_turn()
