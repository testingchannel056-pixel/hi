extends RefCounted

# The people in your life. Each one is a Dictionary, for example:
#   {"id": 3, "role": "Friend", "name": "Jin Ha-rin", "gender": "Female",
#    "age": 14, "lifespan": 71, "bond": 55, "personality": "Cheerful",
#    "occupation": "Weaver", "sect": "", "stage": 0, "alive": true,
#    "married": false, "history": ["Year 1304: You met."],
#    "looks": 62, "seed": 481516}
# "looks" (0 to 100) and "seed" choose their portrait, the same way your own
# Looks choose yours (see ui_pack/portrait.gd).
# They are kept in game.people, dead or alive, and are saved with the life.
# "game" is the main screen (game.gd), which does the writing on the page.

const Data = preload("res://scripts/npc_data.gd")

const MARTIAL_GROWTH = 8      # % chance a year that a martial artist reaches the next stage
const RIVAL_GROWTH = 18       # the same for your rival while they are not ahead of you
const MARRY_CHANCE = 7        # % chance a year that an unmarried adult you know marries
const JOIN_SECT_CHANCE = 6    # % chance a year that a young friend or sibling joins a sect
const DUEL_CHANCE = 4         # % chance a month that your rival comes looking for you
const DUEL_REST = 3           # years between two such challenges
const AMBUSH_CHANCE = 3       # % chance a month that an enemy finds you
const NEWS_LINES = 2          # the most lines of news about other people on one birthday
const LOOKS_RANGE = [15, 95]  # a new person's Looks is somewhere between these

var game


func _init(main_screen):
	game = main_screen


# ---------------------------------------------------------------------------
# Creating and finding people
# ---------------------------------------------------------------------------

# Adds a person to your life and returns them. "extra" can set anything in
# the Dictionary, for example {"occupation": "Farmer", "stage": 2}.
func make(role, age, bond, extra = {}):
	var player = game.player
	var info = game.World.ROLES[role]
	var family_name = player.surname if info.get("surname", false) else player.surnames.pick_random()
	var person = {
		"id": next_id(),
		"role": role,
		"name": family_name + " " + player.given_names.pick_random(),
		"gender": info.get("gender", ["Male", "Female"].pick_random()),
		"age": age,
		"lifespan": max(age + randi_range(15, 40), randi_range(58, 88)),
		"bond": bond,
		"personality": Data.PERSONALITIES.keys().pick_random(),
		"occupation": "",
		"sect": "",
		"stage": 0,
		"alive": true,
		"married": false,
		"history": [],
		"looks": randi_range(LOOKS_RANGE[0], LOOKS_RANGE[1]),
		"seed": randi() % 1000000,
	}
	for key in extra:
		person[key] = extra[key]
	# Cultivation lengthens a life.
	person["lifespan"] += person["stage"] * 15
	game.people.append(person)
	return person


func next_id():
	var highest = 0
	for person in game.people:
		highest = max(highest, person.get("id", 0))
	return highest + 1


# Fills in anything a person from an older save does not have yet.
func upgrade(person):
	var fresh = {"id": next_id(), "gender": ["Male", "Female"].pick_random(), "personality": "Quiet",
		"occupation": "", "sect": "", "stage": 0, "alive": true, "married": false, "history": [],
		"age": 30, "bond": 30, "lifespan": 70, "name": "Someone",
		"looks": randi_range(LOOKS_RANGE[0], LOOKS_RANGE[1]), "seed": randi() % 1000000}
	for key in fresh:
		if not person.has(key):
			person[key] = fresh[key]
	return person


# What a person's portrait is chosen by: their looks, age and gender, like yours.
func profile(person):
	return {"name": person["name"], "gender": person["gender"], "age": person["age"],
		"looks": person["looks"], "seed": person["seed"]}


# Everyone who is alive, or only those with one role.
func alive(role = ""):
	var found = []
	for person in game.people:
		if person["alive"] and (role == "" or person["role"] == role):
			found.append(person)
	return found


func departed():
	var found = []
	for person in game.people:
		if not person["alive"]:
			found.append(person)
	return found


# The living person with this role you are closest to, or null.
func first(role):
	var best = null
	for person in alive(role):
		if best == null or person["bond"] > best["bond"]:
			best = person
	return best


func has(role):
	return first(role) != null


# Writes a line into a person's history, with the year.
func remember(person, text):
	person["history"].append("Year %d: %s" % [game.player.year(), text])
	if person["history"].size() > Data.HISTORY_LENGTH:
		person["history"].pop_front()


# What your bond with someone is called: "Close friend", "Distant"...
func tier(person):
	var names = Data.FAMILY_BOND_NAMES if game.World.ROLES[person["role"]].get("family", false) else Data.BOND_NAMES
	var title = names[0][1]
	for step in names:
		if person["bond"] >= step[0]:
			title = step[1]
	return title


# What someone does, in a few words: "Weaver", or "Mount Hua, Second-Class".
func calling(person):
	var parts = []
	if person["sect"] != "":
		parts.append(person["sect"])
	elif person["occupation"] != "":
		parts.append(person["occupation"])
	if person["stage"] > 0:
		parts.append(game.player.STAGES[person["stage"]])
	return ", ".join(parts) if not parts.is_empty() else ("Child" if person["age"] < 14 else "No trade")


# How much faster (or slower) a bond with this person grows.
func warmth(person):
	return Data.PERSONALITIES.get(person["personality"], {}).get("warmth", 0)


# Called when a choice has "meet". Returns the new person, or null if you
# already know as many people of that kind as you can.
func meet(role):
	var player = game.player
	var info = game.World.ROLES[role]
	if alive(role).size() >= info.get("most", 1):
		return null
	var person
	if role == "Master":
		person = make(role, randi_range(45, 70), 40,
			{"stage": clamp(player.stage + 2, 2, 5), "occupation": "Wandering Master"})
	elif role == "Rival":
		person = make(role, max(player.age + randi_range(-1, 2), 6), 20,
			{"stage": player.stage, "occupation": "Young Swordsman", "personality": "Proud"})
	else:
		person = make(role, max(player.age + randi_range(-1, 2), 1), 50 if role == "Friend" else 20)
	remember(person, "You met.")
	game.write("%s is now your %s." % [person["name"], role.to_lower()], game.GOLD)
	return person


# ---------------------------------------------------------------------------
# The years passing
# ---------------------------------------------------------------------------

# Called on every birthday: everyone gets a year older, bonds fade a little
# if you ignore people, and their own lives move on.
func yearly():
	var news = []
	for person in alive():
		person["age"] += 1
		person["bond"] = max(person["bond"] - game.World.ROLES[person["role"]].get("fade", 3), 0)
		if person["age"] >= person["lifespan"]:
			pass_away(person, "has passed away")
		else:
			grow(person, news)
	for line in news.slice(0, NEWS_LINES):
		game.write(line, game.MUTED)


func pass_away(person, how):
	person["alive"] = false
	remember(person, "Died at %d." % person["age"])
	if game.World.ROLES[person["role"]].get("family", false) or person["bond"] >= 60:
		game.player.remember("lost %s, your %s." % [person["name"], person["role"].to_lower()])
	game.write("Your %s, %s, %s." % [person["role"].to_lower(), person["name"], how], game.BAD)
	# The closer you were, the more it hurts.
	game.write_changes({"Happiness": -5 - person["bond"] / 5})


# One year in someone else's life. Anything worth telling is added to "news".
func grow(person, news):
	var player = game.player
	var role = person["role"]
	var known = "Your %s %s" % [role.to_lower(), person["name"]]
	# A child grows into a trade (your own children choose theirs elsewhere).
	if person["age"] == 14 and person["occupation"] == "" and role != "Child":
		person["occupation"] = Data.OCCUPATIONS.pick_random()
		remember(person, "Became a %s." % person["occupation"].to_lower())
	# Those who live by the sword grow stronger.
	var martial = person["stage"] > 0 or person["sect"] != "" or person["occupation"] in Data.MARTIAL_OCCUPATIONS
	if martial and person["age"] >= 14 and person["stage"] < 5:
		var odds = RIVAL_GROWTH if role == "Rival" and person["stage"] <= player.stage else MARTIAL_GROWTH
		if randi_range(1, 100) <= odds:
			person["stage"] += 1
			person["lifespan"] += 15
			remember(person, "Reached the %s stage." % player.STAGES[person["stage"]])
			news.append("%s has reached the %s stage." % [known, player.STAGES[person["stage"]]])
	# The young join sects.
	if person["sect"] == "" and person["age"] >= 12 and person["age"] <= 20 and role in ["Friend", "Sibling", "Rival"]:
		if randi_range(1, 100) <= JOIN_SECT_CHANCE:
			person["sect"] = game.World.SECTS.keys().pick_random()
			person["occupation"] = "Sect Disciple"
			remember(person, "Joined %s." % person["sect"])
			news.append("%s has joined %s." % [known, person["sect"]])
	# People marry.
	if not person["married"] and person["age"] >= 18 and person["age"] <= 35 \
			and role in ["Friend", "Sibling", "Rival", "Acquaintance", "Disciple"]:
		if randi_range(1, 100) <= MARRY_CHANCE:
			person["married"] = true
			remember(person, "Married.")
			news.append("%s has married." % known)
	# A rival you have grown close to becomes a friend. One you have let
	# sour completely becomes an enemy.
	if role == "Rival" and person["bond"] >= 80 and alive("Friend").size() < game.World.ROLES["Friend"].get("most", 1):
		person["role"] = "Friend"
		remember(person, "Your rivalry became friendship.")
		news.push_front("%s and you are rivals no longer. You are friends." % person["name"])
	elif role == "Rival" and person["bond"] <= 0 and person["age"] >= 16:
		person["role"] = "Enemy"
		remember(person, "Your rivalry turned to hatred.")
		news.push_front("%s no longer calls you a rival. The word they use now is enemy." % person["name"])


# ---------------------------------------------------------------------------
# Your rival comes looking for you
# ---------------------------------------------------------------------------

# Now and then your rival turns up to test you. Returns a scenario for this
# month, or null.
func special_event():
	var player = game.player
	# An enemy comes to finish it.
	var enemy = first("Enemy")
	if enemy != null and player.age >= 14 and player.year() >= enemy.get("next_duel", 0) \
			and randi_range(1, 100) <= AMBUSH_CHANCE:
		enemy["next_duel"] = player.year() + DUEL_REST
		return ambush_scenario(enemy)
	# A rival comes to test you.
	var rival = first("Rival")
	if rival == null or player.age < 12 or rival["age"] < 12:
		return null
	if player.year() < rival.get("next_duel", 0) or randi_range(1, 100) > DUEL_CHANCE:
		return null
	rival["next_duel"] = player.year() + DUEL_REST
	return duel_scenario(rival)


# The scenario in which an enemy catches up with you. This fight is real:
# one of you may not walk away.
func ambush_scenario(enemy):
	return {
		"id": "enemy_ambush",
		"text": "%s steps out of the dark with a drawn blade. \"I have waited a long time for this.\"" % enemy["name"],
		"image": "forest",
		"choices": [
			{"label": "Finish it", "fight": fighter(enemy), "slay": enemy, "win": {"Reputation": 4}},
			{"label": "Offer peace", "percent": 35, "peace": enemy,
				"win": {"Karma": 3}, "win_text": "Something in your voice reaches them. The blade lowers.",
				"lose": {"Health": -15}, "lose_text": "The answer is steel. You get away bleeding."},
			{"label": "Slip away", "stat": "Agility", "difficulty": 15,
				"win": {}, "lose": {"Health": -15}},
		],
	}


# An enemy you have beaten in a real fight is dead.
func slay(enemy):
	enemy["alive"] = false
	remember(enemy, "Fell to your blade.")
	game.player.remember("killed %s, an old enemy." % enemy["name"])


# An enemy who accepts peace becomes someone you merely know.
func make_peace(enemy):
	enemy["role"] = "Acquaintance"
	enemy["bond"] = 15
	remember(enemy, "You made peace.")


# The scenario in which your rival challenges you. It is built here rather
# than written in a data file because it is about one particular person.
func duel_scenario(rival):
	return {
		"id": "rival_duel",
		"text": "%s is waiting for you at the crossroads, one hand on the hilt. \"Show me what you have learned.\"" % rival["name"],
		"image": "mountain",
		"choices": [
			{"label": "Accept the duel", "fight": fighter(rival), "friendly": true, "person": rival, "bond": 6,
				"win": {"Reputation": 5}},
			{"label": "Share a drink instead", "person": rival, "bond": 10, "win": {"Happiness": 5},
				"win_text": "You talk until the jar is empty. Neither of you mentions swords."},
			{"label": "Walk past without a word", "win": {"Rival": -8, "Reputation": -2}},
		],
	}


# A person as an opponent in a friendly duel. They are stronger or weaker
# than you according to how their cultivation compares to yours.
func fighter(person):
	var power = game.World.ROLES[person["role"]].get("power", 1.0)
	power *= 1.0 + 0.2 * clamp(person["stage"] - game.player.stage, -2, 3)
	return {"name": person["name"], "health": int(35 * power), "attack": int(6 * power),
		"defense": int(6 * power), "damage": int(6 * power)}


# Remembers how a duel with someone went.
func after_duel(person, you_won):
	remember(person, "You beat them in a duel." if you_won else "They beat you in a duel.")


# ---------------------------------------------------------------------------
# The Relationships menu
# ---------------------------------------------------------------------------

func show_people():
	game.open_menu("Relationships  ·  actions left this month: %d" % game.actions_left)
	for person in alive():
		var title = "%s  ·  %s" % [person["role"], person["name"]]
		var hint = "Age %d  ·  %s  ·  %s (%d)" % [person["age"], calling(person), tier(person), person["bond"]]
		game.add_choice(title, hint, show_person.bind(person))
	if not departed().is_empty():
		game.add_choice("Those who are gone", "%d people you remember" % departed().size(), show_departed)
	game.add_choice("Back", "", game.show_group.bind("People"))


func show_departed():
	game.open_menu("Those who are gone")
	for person in departed():
		var last = person["history"][-1] if not person["history"].is_empty() else ""
		game.add_caption("%s, your %s.  %s" % [person["name"], person["role"].to_lower(), last])
	game.add_choice("Back", "", show_people)


func show_person(person):
	var info = game.World.ROLES[person["role"]]
	var player = game.player
	var short_name = person["name"]
	game.open_menu("%s  ·  %s  ·  %s (%d)  ·  actions left: %d" %
		[short_name, person["role"], tier(person), person["bond"], game.actions_left])
	game.add_portrait(profile(person))
	var about ="Age %d  ·  %s  ·  %s  ·  %s" % [person["age"], person["gender"], person["personality"], calling(person)]
	if person["married"] and person["role"] != "Spouse":
		about += "  ·  Married"
	game.add_caption(about)
	for line in person["history"].slice(-3):
		game.add_caption(line)

	# With an enemy there is only one thing to do.
	if person["role"] == "Enemy":
		var peace = {"peace": person, "percent": 30, "win": {"Karma": 2}, "lose": {"Happiness": -3},
			"text": "You send word to %s that you want an end to it." % short_name,
			"win_text": "The answer comes back in one line: \"Agreed.\"",
			"lose_text": "The messenger returns with your letter torn in half."}
		game.add_choice("Offer peace", game.hint_for(peace), game.do_action.bind(peace))
		game.disable_without_actions()
		game.add_choice("Back", "", show_people)
		return

	var time = {"person": person, "bond": 12, "win": {"Happiness": 5},
		"text": "You spend the day with %s." % short_name}
	game.add_choice("Spend time together", "Bond +%d" % (12 + game.bond_bonus() + warmth(person)), game.do_action.bind(time))

	# Guidance works better the closer you are.
	if info.has("guidance") and person["age"] >= 14:
		var guidance = {"person": person, "bond": 3, "win": info["guidance"],
			"text": "You ask %s for guidance." % short_name}
		if info.has("train"):
			guidance["train"] = info["train"]
			guidance["bonus"] = person["bond"] / 4
		else:
			guidance["percent"] = person["bond"]
		game.add_choice("Ask for guidance", "%s  ·  %s" %
			[game.describe(info["guidance"]), game.difficulty_word(game.chance(guidance))], game.do_action.bind(guidance))

	if player.age >= 10 and person["age"] >= 10:
		var spar = {"person": person, "bond": 5, "friendly": true, "win": {"Qi": 5},
			"text": "You bow to %s and take your stance." % short_name,
			"image": "home" if info.get("family", false) else "sect",
			"fight": fighter(person)}
		game.add_choice("Spar", game.hint_for(spar), game.do_action.bind(spar))

	game.family.add_actions(person)
	game.martial.add_master_lessons(person)
	game.disable_without_actions()
	game.add_choice("Back", "", show_people)
