extends RefCounted

# What a character can look like: the choices on the customization screen,
# and what people wear. Plain data, like world_data.gd.
#   scripts/character_art.gd     - draws a portrait from these choices
#   scripts/character_visual.gd  - the picture on the screen
#   scripts/appearance_picker.gd - the < > pickers that change a look
#
# A "look" is a Dictionary of numbers, one per part, each the position of
# the chosen option in its list below (0 is the first one):
#   {"skin": 1, "build": 2, "hair": 0, "hair_colour": 0, "eyes": 0,
#    "eye_colour": 2, "mark": 0, "beard": 0}
# To add an option to a list of colours, add a line to it. Hair styles,
# eye shapes, marks and beards are drawn in character_art.gd, so a new one
# of those needs a drawing there as well.

# --- Colours: [name, colour] ---
const SKINS = [
	["Porcelain", "f7dfd0"], ["Fair", "efc9aa"], ["Golden", "dfae84"],
	["Tan", "c48d61"], ["Bronze", "a06c45"], ["Deep", "74492f"],
]
const HAIR_COLOURS = [
	["Raven", "1b1a21"], ["Dark brown", "3b2719"], ["Chestnut", "70421f"],
	["Crimson", "7d1f22"], ["Silver", "cdd2da"], ["Midnight blue", "1f2e52"],
]
const EYE_COLOURS = [
	["Dark brown", "4a2c18"], ["Black", "1c1c22"], ["Amber", "cf8f2a"],
	["Jade", "3f9c6c"], ["Sky", "4a8fd2"], ["Crimson", "b22c2c"],
]

# --- Shapes: names only (the drawings are in character_art.gd) ---
const BUILDS = ["Lean", "Athletic", "Mighty"]
const HAIR_STYLES = {
	"Male": ["Topknot", "Long and loose", "High ponytail", "Short and wild", "Headband"],
	"Female": ["Bun and hairpin", "Long and flowing", "Twin buns", "High ponytail", "Side braid"],
}
const EYE_SHAPES = ["Sharp", "Calm", "Bright"]
const MARKS = ["None", "Scar", "Beauty mark", "Forehead mark"]
const BEARDS = ["None", "Stubble", "Goatee", "Full beard"]

# --- The pickers on the customization screen, in the order they are shown ---
# "only" leaves a part out for the other gender.
const PARTS = [
	{"key": "skin", "title": "Skin"},
	{"key": "build", "title": "Build"},
	{"key": "hair", "title": "Hair"},
	{"key": "hair_colour", "title": "Hair colour"},
	{"key": "eyes", "title": "Eyes"},
	{"key": "eye_colour", "title": "Eye colour"},
	{"key": "mark", "title": "Mark"},
	{"key": "beard", "title": "Beard", "only": "Male"},
]

# --- Ages ---
const CHILD_UNTIL = 13        # younger than this you are drawn as a child
const YOUTH_UNTIL = 20        # ...and younger than this as a youth
const ELDER_FROM = 50         # from this age you are drawn old...
const ELDER_PER_STAGE = 10    # ...plus this many years for every cultivation stage

# --- What people wear: [robe, trim, inner collar] ---
const OUTFITS = {
	"peasant": ["6d5b45", "8f7d5c", "d2c7ac"],
	"beggar": ["5c5248", "3f3932", "8d8474"],
	"merchant": ["2f6f63", "c9a961", "e6dcc3"],
	"scholar": ["e4e1d7", "2f4a6c", "f5f2eb"],
	"noble": ["4c2f6e", "c9a961", "e6dcc3"],
	"martial": ["202e46", "b5413a", "d9d3c3"],
	"wanderer": ["4c5b4b", "2e3830", "bab39d"],
	"disciple": ["6f94b1", "e6eef2", "f5f2eb"],
	"wudang": ["eef0f3", "1e2b3c", "c9d5dd"],
	"shaolin": ["d98b2c", "7b2f20", "f2c66b"],
	"huashan": ["f2edef", "a94679", "f8e0ea"],
	"cult": ["1c161a", "b5413a", "3c2c32"],
}
# The colours behind a portrait: [middle, edge]. A great sect has its own.
const BACKDROPS = {
	"plain": ["31434d", "0f171b"],
	"wudang": ["3f5d77", "13202c"],
	"shaolin": ["7c5c2b", "281a0b"],
	"huashan": ["7c4b68", "281320"],
	"cult": ["5c2025", "17090b"],
}

# Who wears what. A sect's robe comes first, then your life path, then the
# clothes of the home you were born into.
const SECT_OUTFITS = {
	"Wudang": "wudang", "Shaolin": "shaolin", "Mount Hua": "huashan",
	"Demonic Cult": "cult", "Beggars' Union": "beggar",
}
const PATH_OUTFITS = {
	"Farmer": "peasant", "Martial Disciple": "martial", "Scholar": "scholar",
	"Craftsman": "peasant", "Merchant": "merchant", "Physician": "scholar",
	"Wanderer": "wanderer", "Sect Heir": "disciple", "Jianghu Outlaw": "wanderer",
	"Teacher": "scholar", "Hunter": "wanderer", "Guard": "martial",
}
const BACKGROUND_OUTFITS = {
	"Poor Village": "peasant", "Merchant Family": "merchant", "Martial Clan": "martial",
	"Sect Family": "disciple", "Scholar Family": "scholar", "Noble Family": "noble",
	"Orphan": "beggar", "Wandering Family": "wanderer",
}
# What the people you know wear, by what they do for a living.
const WORK_OUTFITS = {
	"Merchant": "merchant", "Shopkeeper": "merchant", "Innkeeper": "merchant",
	"Scholar": "scholar", "Physician": "scholar", "Teacher": "scholar", "Magistrate": "noble",
	"Lady of the House": "noble", "Hunter": "wanderer", "Storyteller": "wanderer",
	"Travelling Performer": "wanderer", "Herb Seller": "wanderer", "Guard": "martial",
	"Escort Guard": "martial", "Clan Swordsman": "martial", "Clan Swordswoman": "martial",
	"Young Swordsman": "martial", "Wandering Swordsman": "wanderer", "Wandering Master": "wanderer",
	"Sect Disciple": "disciple", "Sect Elder": "noble",
}
const LEADER_OUTFIT = "noble"     # what the leader of their own sect wears
const DEFAULT_OUTFIT = "peasant"  # what everyone else wears


# The names to choose from for one part: options("hair", "Female").
static func options(key, gender):
	if key == "skin":
		return names(SKINS)
	if key == "hair_colour":
		return names(HAIR_COLOURS)
	if key == "eye_colour":
		return names(EYE_COLOURS)
	if key == "build":
		return BUILDS
	if key == "hair":
		return HAIR_STYLES[gender]
	if key == "eyes":
		return EYE_SHAPES
	if key == "mark":
		return MARKS
	return BEARDS


# The colour to show beside a part's name, or null if the part is a shape.
static func swatch(key, number):
	var lists = {"skin": SKINS, "hair_colour": HAIR_COLOURS, "eye_colour": EYE_COLOURS}
	if lists.has(key):
		return Color(lists[key][number][1])
	return null


static func names(list):
	var found = []
	for entry in list:
		found.append(entry[0])
	return found


# Makes up a look from a number. The same number always gives the same look,
# which is how the people you know keep their faces.
static func random_look(number, gender):
	var dice = RandomNumberGenerator.new()
	dice.seed = number
	var look = {}
	for part in PARTS:
		look[part["key"]] = dice.randi() % options(part["key"], gender).size()
	# Most hair is dark, most eyes are brown, and most men are clean-shaven.
	if dice.randi() % 3 > 0:
		look["hair_colour"] = dice.randi() % 3
	if dice.randi() % 2 == 0:
		look["eye_colour"] = dice.randi() % 2
	if dice.randi() % 2 == 0:
		look["mark"] = 0
	if dice.randi() % 2 == 0 or gender != "Male":
		look["beard"] = 0
	return look


# Returns a look with every part present and inside its list. A look from
# an older save, or one with a part missing, is filled in from the number.
static func complete(look, gender, number = 0):
	var whole = random_look(number, gender)
	if look is Dictionary:
		for key in whole:
			if look.has(key):
				whole[key] = clampi(int(look[key]), 0, options(key, gender).size() - 1)
	if gender != "Male":
		whole["beard"] = 0
	return whole


# Which stage of life an age is drawn as: "child", "youth", "adult" or
# "elder". Cultivators stay in their prime for longer.
static func life_stage(age, cultivation = 0):
	if age < CHILD_UNTIL:
		return "child"
	if age < YOUTH_UNTIL:
		return "youth"
	if age < ELDER_FROM + cultivation * ELDER_PER_STAGE:
		return "adult"
	return "elder"
