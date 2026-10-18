extends RefCounted

# The end of a life: the title it is remembered by, the story told about
# it, and what is passed on to a child. Titles come from
# content_pack/endings.json (the first one that fits wins, in the order of
# that file), with this game's own titles placed among them.
# "game" is the main screen (game.gd).

const FILE = "res://content_pack/endings.json"
const Needs = preload("res://scripts/requirements.gd")
const Saves = preload("res://scripts/save_manager.gd")

# This game's own titles. "before" places a title just in front of the pack
# title of that name; without it the title is checked first of all.
# "needs" uses the same format as everywhere else (see requirements.gd).
const OWN_TITLES = [
	{"title": "The Immortal", "needs": {"stage": 6, "not_flag": ["ascended"]}, "before": "The Blood Demon",
		"text": "You did not die so much as stop being seen. Some say you sit on a peak beyond the clouds, waiting for someone worth a conversation."},
	{"title": "Founder of a Great Sect", "needs": {"leads_sect": true, "count": {"sect_size": 120}}, "before": "Venerable Sect Leader",
		"text": "The sect you planted on an empty mountainside now fills the valley. A thousand disciples sweep your grave in turn, and argue about what you would have wanted."},
	{"title": "The Merchant King", "needs": {"path": ["Merchant"], "path_rank": 2}, "before": "The Rich Old Fox",
		"text": "Caravans on four roads carried your seal. It is said that the day you died, the price of silk moved in three provinces."},
	{"title": "The Beloved Physician", "needs": {"path": ["Physician"], "path_rank": 1, "Karma": 30}, "before": "The Divine Doctor",
		"text": "They did not build you a statue. They named their children after you instead, which lasts longer."},
	{"title": "The Grand Scholar", "needs": {"path": ["Scholar", "Teacher"], "path_rank": 2}, "before": "The Hidden Dragon",
		"text": "Your commentaries are copied by students who curse your handwriting and cannot do without your thinking."},
	{"title": "The Master Smith", "needs": {"path": ["Craftsman"], "path_rank": 2}, "before": "The Hidden Dragon",
		"text": "Half the famous swords of the next century carry your mark under the guard. The other half are imitations of them."},
	{"title": "The Failed Sect Master", "needs": {"leads_sect": true, "max": {"sect_size": 3}}, "before": "A Sprout Cut Short",
		"text": "The gate still stands, with your sect's name over it and nobody behind it. Travellers sometimes shelter there from the rain."},
	{"title": "The Wandering Swordsman", "needs": {"path": ["Wanderer"], "path_rank": 1}, "before": "A Local Terror",
		"text": "No home, no grave, no heirs. Only stories, told in a hundred inns, in which a stranger arrives at the right moment and leaves before the thanks."},
	{"title": "Head of a Great House", "needs": {"relation": ["Spouse"], "count": {"children": 3}, "Gold": 300}, "before": "A Quiet Life",
		"text": "Four generations sit down at your table for the last time. The youngest will not remember you. They will remember the house, which is what you meant to leave."},
	{"title": "The Old Soldier of the Roads", "needs": {"path": ["Guard", "Hunter"], "path_rank": 1}, "before": "A Local Hero",
		"text": "You walked more miles than most people dream. The caravans still tell the new guards to do it the way you did."},
	{"title": "The Forgotten Scholar", "needs": {"path": ["Scholar"]}, "before": "A Nameless Grave",
		"text": "Your one book was read by eleven people. One of them, forty years on, will change the world with an idea found in its margins."},
	{"title": "The Honest Farmer", "needs": {"path": ["Farmer"], "Karma": 5}, "before": "A Nameless Grave",
		"text": "The field you cleared feeds people who never knew your name. Of all the things done in the murim this year, it may be the only one that mattered."},
]

const HEIR_AGE = 16           # a child must be this old to carry on after you
const HEIR_GOLD = 0.5         # the share of your Gold a child inherits
const HEIR_REPUTATION = 0.25  # the share of your Reputation that carries over as family name
const MEMORIES_SHOWN = 8      # how many turning points the story at the end lists

var game
var titles = []   # every title in the order it is checked: {"title", "text", "needs"}


func _init(main_screen):
	game = main_screen
	load_titles()


# ---------------------------------------------------------------------------
# Titles
# ---------------------------------------------------------------------------

# Reads endings.json and turns its conditions into this game's "needs".
func load_titles():
	titles = []
	if FileAccess.file_exists(FILE):
		var json = JSON.new()
		if json.parse(FileAccess.get_file_as_string(FILE)) == OK and json.data is Array:
			for ending in Saves.whole_numbers(json.data):
				titles.append({"title": ending["title"], "text": ending["text"], "needs": convert_needs(ending)})
	if titles.is_empty():
		titles.append({"title": "A Nameless Grave", "needs": {},
			"text": "One of ten thousand who entered the murim and left no mark."})
	# Put this game's own titles in their places.
	for own in OWN_TITLES:
		var place = 0
		for i in titles.size():
			if titles[i]["title"] == own.get("before", ""):
				place = i
		titles.insert(place, own)


# The conditions of a pack ending, in this game's words: fame is
# Reputation, infamy is Karma below zero, realm is the stage.
func convert_needs(ending):
	var low = ending.get("min", {})
	var high = ending.get("max", {})
	var needs = {}
	var at_most = {}
	if ending.has("flags"):
		needs["flag"] = ending["flags"]
	if low.has("fame"):
		needs["Reputation"] = low["fame"]
	if low.has("shame"):
		needs["Shame"] = low["shame"]
	if low.has("realm"):
		needs["stage"] = low["realm"]
	if low.has("gold"):
		needs["Gold"] = low["gold"]
	if low.has("infamy"):
		at_most["Karma"] = -low["infamy"]
	if high.has("fame"):
		at_most["Reputation"] = high["fame"]
	if high.has("shame"):
		at_most["Shame"] = high["shame"]
	if high.has("age"):
		at_most["age"] = high["age"]
	if high.has("infamy"):
		needs["Karma"] = -high["infamy"]
	if not at_most.is_empty():
		needs["max"] = at_most
	return needs


# The title this life has earned: the first one whose needs are met.
func title():
	for entry in titles:
		if Needs.meets(game, entry.get("needs", {})):
			return entry
	return titles[-1]


# ---------------------------------------------------------------------------
# The story told at the end
# ---------------------------------------------------------------------------

# Writes the last page of a life and returns the title it earned.
func write_epilogue():
	var player = game.player
	var npcs = game.npcs
	var earned = title()
	game.write_heading(earned["title"])
	game.write(earned["text"])
	game.write("You lived %d years and reached the %s stage." % [player.age, player.stage_name()], game.GOLD)
	game.write("Your name in the jianghu: %s." % game.factions.name_in_jianghu(), game.MUTED)
	var facts = []
	if player.path != "":
		facts.append("%s (%s)" % [player.path, game.life.rank_name()])
	if game.my_sect != null:
		facts.append("leader of the %s, %d disciples" % [game.my_sect.sect_name, game.my_sect.disciples])
	elif player.sect != "":
		facts.append("%s of %s" % [player.RANKS[player.rank()], player.sect])
	var spouse = npcs.first("Spouse")
	if spouse != null:
		facts.append("married to %s" % spouse["name"])
	var children = game.family.children().size()
	if children > 0:
		facts.append("%d %s" % [children, "child" if children == 1 else "children"])
	facts.append("%d gold" % player.stats["Gold"])
	if not player.properties.is_empty():
		facts.append(", ".join(player.properties).to_lower())
	if not player.techniques.is_empty():
		facts.append("%d techniques" % player.techniques.size())
	game.write("  ·  ".join(facts), game.MUTED)
	for memory in player.memories.slice(-MEMORIES_SHOWN):
		game.write(memory, game.MUTED)
	return earned["title"]


# ---------------------------------------------------------------------------
# Living on through a child
# ---------------------------------------------------------------------------

# The child who can carry on after you: the oldest one who is grown, or null.
func heir():
	var oldest = null
	for child in game.npcs.alive("Child"):
		if child["age"] >= HEIR_AGE and (oldest == null or child["age"] > oldest["age"]):
			oldest = child
	return oldest


# Everything the child starts their own life with. It is a part of what you
# had, never all of it, so a new life is not won before it begins.
func inheritance(child):
	var player = game.player
	var best = ""
	for technique in player.techniques:
		if best == "" or player.techniques[technique] > player.techniques[best]:
			best = technique
	var family = []
	for person in game.npcs.alive():
		# "looks" and "seed" go along, so everyone keeps the face they had.
		if person["role"] == "Spouse":
			family.append({"role": "Mother" if person["gender"] == "Female" else "Father", "name": person["name"],
				"age": person["age"], "bond": person["bond"], "gender": person["gender"],
				"looks": person["looks"], "seed": person["seed"]})
		elif person["role"] == "Child" and person != child:
			family.append({"role": "Sibling", "name": person["name"], "age": person["age"], "bond": 50,
				"gender": person["gender"], "occupation": person["occupation"], "sect": person["sect"], "stage": person["stage"],
				"looks": person["looks"], "seed": person["seed"]})
	return {
		"name": child["name"], "gender": child["gender"], "age": child["age"],
		"looks": child["looks"], "seed": child["seed"],
		"parent": player.full_name, "birth_year": player.year() - child["age"],
		"gold": int(player.stats["Gold"] * HEIR_GOLD),
		"reputation": int(player.stats["Reputation"] * HEIR_REPUTATION),
		"properties": player.properties.duplicate(),
		"technique": best,
		"background": "Martial Clan" if player.stage >= 2 or game.my_sect != null else player.background,
		"sect": child["sect"], "stage": child["stage"],
		"family": family,
	}


# Begins the child's life. Called by game.gd on a fresh screen.
func begin_as_heir(data):
	var player = game.player
	# The child keeps the looks and the face they had while you knew them.
	player.setup({"name": data["name"], "gender": data["gender"], "talent": game.World.TALENTS.keys().pick_random(),
		"background": data["background"], "Health": 80, "Smarts": 50, "Looks": data.get("looks", 50), "Happiness": 40,
		"seed": data.get("seed", player.face_seed)}, game.World.TALENTS)
	player.age = data["age"]
	player.birth_year = data["birth_year"]
	player.stage = min(data.get("stage", 0), 1)
	player.change({"Gold": data["gold"], "Reputation": data["reputation"],
		"Strength": 2, "Agility": 2, "Martial Insight": 2})
	player.properties = data["properties"]
	if data.get("sect", "") != "" and game.World.SECTS.has(data["sect"]):
		player.sect = data["sect"]
		player.faction = game.World.SECTS[data["sect"]]["faction"]
	for person in data["family"]:
		var extra = person.duplicate()
		for key in ["role", "age", "bond"]:
			extra.erase(key)
		game.npcs.make(person["role"], person["age"], person["bond"], extra)
	game.new_page("home")
	game.write_title("A NEW GENERATION  ·  YEAR %d" % player.year())
	game.write("You are %s, child of the late %s. The mourning lanterns are still up." % [player.full_name, data["parent"]])
	game.write("You inherit a part of what your parent built: %d gold, a share of the family name%s." %
		[data["gold"], ", and the family property" if not data["properties"].is_empty() else ""], game.MUTED)
	if data.get("technique", "") != "":
		game.martial.learn(data["technique"])
	if player.talent != "None":
		game.write("Your talent: %s. %s" % [player.talent_name, player.talent_info["text"]], game.GOLD)
	player.remember("took up the family name after %s." % data["parent"])
