extends RefCounted

# Turns the events in content_pack/events.json into this game's scenario
# format when the game starts. The pack was written for another prototype,
# so its stat names and scales differ; the tables below translate them.
# The pack file itself is never changed. To change how an event comes out,
# change the tables here, not events.json.

const FILE = "res://content_pack/events.json"

# Pack events this game does not use, because it has its own version of
# them: choosing a background, resting, quiet months and sect promotions.
const SKIP = ["origin", "healer", "quiet_year", "inner_exam", "become_elder"]

# Pack stat -> this game's stat.
const STATS = {"body": "Strength", "movement": "Agility", "comprehension": "Martial Insight",
	"health": "Health", "max_health": "Max Health", "qi": "Qi", "max_qi": "Qi Capacity",
	"gold": "Gold", "fame": "Reputation", "shame": "Shame"}
const WILLPOWER_PER_DAO = 5    # the pack's Dao Heart runs 0 to 12; Willpower runs 0 to 100
const HAPPINESS_PER_LUCK = 3   # this game has no Luck stat; good luck lifts the mood instead
const KIND_KARMA = 2           # Karma for an outcome that steadies the heart through kindness
# The pack was written for one event a year. This game has several, so what
# an event gives in Gold, Reputation, Karma and Shame is scaled down by this
# much (never below 1), or every life would end rich and famous.
const REWARD_SCALE = 0.5
const SCALED = ["gold", "fame", "infamy", "shame"]

# Pack difficulty -> this game's difficulty for Strength, Agility and Martial
# Insight. A fixed 4 or 5 is easy, 6 moderate, 7 difficult, 8 very difficult.
const FIXED_DIFFICULTY = {4: 10, 5: 11, 6: 14, 7: 17, 8: 20}
# The same for "rel", which is measured against what is normal at your stage.
const RELATIVE_DIFFICULTY = {0: 12, 1: 14, 2: 17, 3: 20}

# Ages. The pack begins at 12 and does not say how young its events can be.
const YOUTH_AGE = 8     # for events that end by 20
const ADULT_AGE = 14    # for all the others
const FIGHT_AGE = 10    # nobody younger is put in a fight

# Opponents by how far above you the pack says they are ("rel"). Each row is
# [highest rel it covers, health, attack, defense, damage]. Like every enemy
# they grow stronger with your stage.
const FOES = [
	[-2, 25, 4, 4, 5],
	[0, 40, 6, 6, 7],
	[1, 45, 7, 7, 8],
	[2, 50, 8, 8, 8],
	[3, 60, 9, 9, 10],
	[4, 70, 10, 10, 11],
	[5, 95, 11, 10, 13],
	[6, 130, 13, 11, 15],
	[99, 160, 15, 13, 17],
]
# A fixed "power" in the pack is only used for weak foes met in childhood.
const WEAK_FOE = [0, 30, 5, 5, 6]

# Which fighter picture an opponent gets, by a word in its name.
const FOE_PICTURES = {"wolf": "wolf", "boar": "wolf", "tiger": "beast", "serpent": "beast", "beast": "beast",
	"bandit": "bandit", "thug": "bandit", "pirate": "bandit", "robber": "bandit", "guard": "bandit",
	"cult": "cultist", "demon": "cultist", "assassin": "initiate", "killer": "initiate",
	"sword": "duelist", "master": "duelist", "judge": "duelist"}

# Which picture a scenario gets, by a word in its title or text. The first
# match wins, so the more telling words come first.
const PICTURES = [
	["fire", ["fire", "burn", "flame", "torch", "blaze", "war ", "battle", "siege"]],
	["cave", ["cave", "cavern", "tomb", "ruins", "underground", "cellar", "pit"]],
	["waterfall", ["waterfall", "river", "lake", "ferry", "pond", "falls", "bridge", "flood"]],
	["tavern", ["inn", "tavern", "tea house", "wine", "dice", "gambl", "banquet", "auction"]],
	["shrine", ["temple", "shrine", "monk", "grave", "stele", "altar"]],
	["sect", ["sect", "disciple", "elder", "wudang", "shaolin", "mount hua", "cult", "tournament", "hall"]],
	["forest", ["forest", "wolf", "tiger", "tree", "woods", "herb", "boar", "beast"]],
	["mountain", ["mountain", "cliff", "pass", "road", "peak", "snow", "caravan"]],
	["home", ["home", "house", "child", "father", "mother", "family", "infant"]],
	["village", ["village", "market", "festival", "street", "town", "lane", "square", "magistrate"]],
]

# The pack's named characters. Each becomes a real person in your life the
# first time its flag is set. "knows" is a flag set at the same moment; the
# later events that mention the name wait for it.
const PEOPLE = {
	"rival": {"role": "Rival", "name": "Wei Lang", "gender": "Male", "bond": 30, "knows": "knows_wei_lang"},
	"has_master": {"role": "Master", "name": "Master Yun", "gender": "Male", "age": 62, "bond": 45, "stage": 4,
		"occupation": "Wandering Master", "knows": "knows_master_yun"},
	"sworn_brother": {"role": "Friend", "name": "Zhao Hu", "gender": "Male", "bond": 70},
	"lover": {"role": "Partner", "name": "Lin Yue", "gender": "Female", "bond": 70, "knows": "knows_lin_yue"},
	"knows_killer": {"role": "Enemy", "name": "Elder Mok", "gender": "Male", "age": 60, "bond": 0, "stage": 4},
	"clan_enemy": {"role": "Enemy", "name": "Guo Tian", "gender": "Male", "age": 58, "bond": 0, "stage": 2},
	"has_disciple": {"role": "Disciple", "bond": 55},
}
const NAME_FLAGS = {"Wei Lang": "knows_wei_lang", "Lin Yue": "knows_lin_yue", "Master Yun": "knows_master_yun"}
# The events in which those three are first met, which must not wait.
const FIRST_MEETINGS = ["meet_rival", "meet_lin_yue", "old_fisher"]

# Pack flags that mean "a member of this sect".
const SECT_FLAGS = {"wudang": "Wudang", "shaolin": "Shaolin", "huashan": "Mount Hua",
	"beggar": "Beggars' Union", "cult": "Demonic Cult"}
# Pack origin flags, by this game's backgrounds.
const ORIGIN_FLAGS = {"o_orphan": "Orphan", "o_farmer": "Poor Village", "o_merchant": "Merchant Family"}

# What some flags add to every blow you land in a fight.
const FIGHT_FLAGS = {"legend_sword": 3, "demon_sword": 4, "spirit_beast": 2, "blood_art": 3}

# What some flags cost you every year while they last.
const YEARLY_FLAGS = {
	"poisoned": {"text": "The poison is still in your blood.", "changes": {"Health": -10}},
	"tomb_curse": {"text": "The curse of the tomb sits on your chest at night.", "changes": {"Health": -5, "Happiness": -3}},
	"owes_debt": {"text": "The moneylenders take their interest.", "changes": {"Gold": -8}},
}


# ---------------------------------------------------------------------------
# Reading and converting the pack
# ---------------------------------------------------------------------------

# Returns every pack event as a scenario. An empty list if the file is
# missing or cannot be read.
static func load_events():
	if not FileAccess.file_exists(FILE):
		return []
	var json = JSON.new()
	if json.parse(FileAccess.get_file_as_string(FILE)) != OK or not json.data is Array:
		return []
	var scenarios = []
	for event in whole_numbers(json.data):
		if event["id"] not in SKIP:
			scenarios.append(convert_event(event))
	return scenarios


static func convert_event(event):
	var low = event.get("min", {})
	var high = event.get("max", {})
	var scenario = {"id": event["id"], "title": event["title"], "text": event["text"],
		"image": picture_for(event["title"] + " " + event["text"])}
	for word in ["once", "repeat", "hidden", "weight"]:
		if event.has(word):
			scenario[word] = event[word]

	# Ages.
	var fights = false
	for choice in event["choices"]:
		fights = fights or choice.has("combat")
	var youngest = low.get("age", YOUTH_AGE if high.get("age", 99) <= 20 else ADULT_AGE)
	scenario["min_age"] = max(youngest, FIGHT_AGE) if fights and not low.has("age") else youngest
	if high.has("age"):
		scenario["max_age"] = high["age"]

	# Everything else the event asks for.
	var needs = {}
	var at_most = {}
	if low.has("realm"):
		needs["stage"] = low["realm"]
	if low.has("fame"):
		needs["Reputation"] = low["fame"]
	if low.has("shame"):
		needs["Shame"] = low["shame"]
	if low.has("infamy"):
		at_most["Karma"] = -low["infamy"]
	if high.has("realm"):
		at_most["stage"] = high["realm"]
	if high.has("gold"):
		at_most["Gold"] = high["gold"]
	if high.has("health"):
		at_most["Health"] = high["health"]
	if not at_most.is_empty():
		needs["max"] = at_most
	var flags = event.get("flags", []).duplicate()
	# An event that speaks of someone by name waits until you have met them.
	if event["id"] not in FIRST_MEETINGS:
		var words = all_text(event)
		for person in NAME_FLAGS:
			if words.contains(person):
				flags.append(NAME_FLAGS[person])
	if not flags.is_empty():
		needs["flag"] = flags
	if event.has("not_flags"):
		needs["not_flag"] = event["not_flags"]
	if event["id"] == "meet_rival":
		needs["no_relation"] = ["Rival"]
	if not needs.is_empty():
		scenario["needs"] = needs

	scenario["choices"] = []
	for choice in event["choices"]:
		scenario["choices"].append(convert_choice(choice))
	return scenario


static func convert_choice(choice):
	var result = {"label": choice["text"]}
	var needs = {}
	if choice.get("min", {}).has("gold"):
		needs["Gold"] = choice["min"]["gold"]
	if choice.has("requires"):
		needs["technique"] = [choice["requires"]]
	if choice.has("flags"):
		needs["flag"] = choice["flags"]
	if choice.has("not_flags"):
		needs["not_flag"] = choice["not_flags"]
	if not needs.is_empty():
		result["needs"] = needs

	var fought = choice.has("combat")
	if fought:
		# A fight from the pack stops before it kills you: losing it is the
		# "fail" outcome, not the end of your life.
		result["fight"] = foe(choice["combat"])
		result["mercy"] = true
	elif choice.has("stat"):
		var stat = choice["stat"]
		var fixed = choice.get("difficulty", 0)
		var rel = choice.get("rel", 0)
		if stat == "luck":
			result["percent"] = clamp(50 + (5 - fixed) * 8 if choice.has("difficulty") else 50 - rel * 8, 5, 95)
		elif stat == "dao_heart":
			result["stat"] = "Willpower"
			result["difficulty"] = 50 + (fixed - 6) * 8 if choice.has("difficulty") else 50 + rel * 8
		elif stat == "fame":
			result["stat"] = "Reputation"
			result["difficulty"] = fixed
		else:
			result["stat"] = STATS[stat]
			if choice.has("difficulty"):
				result["difficulty"] = FIXED_DIFFICULTY.get(fixed, 14 + (fixed - 6) * 3)
			else:
				result["difficulty"] = RELATIVE_DIFFICULTY.get(rel, 14 + (rel - 1) * 3)

	result["win"] = convert_outcome(choice["success"], false)
	result["win_text"] = choice["success"].get("text", "")
	if choice.has("fail"):
		result["lose"] = convert_outcome(choice["fail"], fought)
		result["lose_text"] = choice["fail"].get("text", "")
	return result


# An outcome in the pack -> a "win" or "lose" list in this game.
static func convert_outcome(outcome, after_lost_fight):
	var changes = {}
	for key in outcome:
		var value = outcome[key]
		if key == "health" and value < 0 and after_lost_fight:
			continue   # the fight itself already did the damage
		if key in SCALED:
			value = scaled(value)
		if STATS.has(key):
			add(changes, STATS[key], value)
		elif key == "infamy":
			add(changes, "Karma", -value)
		elif key == "dao_heart":
			add(changes, "Willpower", value * WILLPOWER_PER_DAO)
		elif key == "luck":
			add(changes, "Happiness", value * HAPPINESS_PER_LUCK)
		elif key in ["flag", "unflag", "learn", "goto", "die"]:
			changes[key] = value
	# The pack only gives fame for good deeds. Karma should move too.
	if outcome.get("dao_heart", 0) > 0 and not outcome.has("shame") and not outcome.has("infamy"):
		add(changes, "Karma", KIND_KARMA)
	return changes


static func add(changes, stat, amount):
	changes[stat] = changes.get(stat, 0) + amount


# A reward from the pack, scaled down but never to nothing: 5 -> 3, 1 -> 1,
# -10 -> -5.
static func scaled(amount):
	if amount == 0:
		return 0
	var size = max(int(round(abs(amount) * REWARD_SCALE)), 1)
	return size if amount > 0 else -size


# The opponent for a fight from the pack.
static func foe(combat):
	var row = WEAK_FOE
	if combat.has("rel"):
		for tier in FOES:
			if combat["rel"] <= tier[0]:
				row = tier
				break
	var title = combat["name"]
	var picture = "person"
	for word in FOE_PICTURES:
		if title.to_lower().contains(word):
			picture = FOE_PICTURES[word]
			break
	return {"name": title, "health": row[1], "attack": row[2], "defense": row[3], "damage": row[4],
		"picture": picture}


static func picture_for(words):
	words = words.to_lower()
	for entry in PICTURES:
		for word in entry[1]:
			if words.contains(word):
				return entry[0]
	return "mountain"


# Every sentence of a pack event, joined together.
static func all_text(event):
	var words = event["title"] + " " + event["text"]
	for choice in event["choices"]:
		words += " " + choice["text"] + " " + choice["success"].get("text", "")
		if choice.has("fail"):
			words += " " + choice["fail"].get("text", "")
	return words


# JSON turns every number into a decimal. This turns them back.
static func whole_numbers(value):
	if value is float and value == floor(value):
		return int(value)
	if value is Array:
		for i in value.size():
			value[i] = whole_numbers(value[i])
	if value is Dictionary:
		for key in value:
			value[key] = whole_numbers(value[key])
	return value


# ---------------------------------------------------------------------------
# Flags that are really about the state of the game
# ---------------------------------------------------------------------------

# Some pack flags describe things this game already keeps track of: which
# sect you are in, whether you are married, your rank. Those are read from
# the game itself, so the two can never disagree. Returns true if the flag
# is one of them and it holds right now.
static func derived(game, flag):
	var player = game.player
	var in_great_sect = game.my_sect == null and game.World.SECTS.has(player.sect)
	if SECT_FLAGS.has(flag):
		return in_great_sect and player.sect == SECT_FLAGS[flag]
	if ORIGIN_FLAGS.has(flag):
		return player.background == ORIGIN_FLAGS[flag]
	match flag:
		"affiliated":
			return player.sect != "" or player.flags.has("bandit") or player.flags.has("assassin")
		"orthodox":
			return in_great_sect and player.faction == "Orthodox"
		"inner":
			return in_great_sect and player.faction == "Orthodox" and player.rank() >= 1
		"elder":
			return in_great_sect and player.faction == "Orthodox" and player.rank() >= 3
		"o_clan":
			# Half of all orphans turn out to be the last of a fallen clan.
			return player.background == "Orphan" and player.birth_year % 2 == 0
		"has_master":
			return game.npcs.has("Master")
		"rival":
			return game.npcs.has("Rival")
		"lover":
			return game.npcs.has("Partner")
		"married":
			return game.npcs.has("Spouse")
		"has_child":
			return game.npcs.has("Child")
		"has_disciple":
			return game.npcs.has("Disciple")
		"physician":
			return player.path == "Physician"
		"escort":
			return player.path == "Guard"
		"bandit":
			return player.path == "Jianghu Outlaw"
	return false


# Flags that are never written down, because derived() answers for them.
const NEVER_STORED = ["affiliated", "orthodox", "inner", "elder", "wudang", "shaolin", "huashan", "beggar", "cult",
	"has_master", "rival", "lover", "married", "has_child", "has_disciple"]


# Called when a flag is set, before it is written down: makes the matching
# change in the game. Returns nothing.
static func on_set(game, flag):
	var player = game.player
	var npcs = game.npcs
	if SECT_FLAGS.has(flag):
		if player.sect != SECT_FLAGS[flag]:
			game.my_sect = null
			game.join_sect(SECT_FLAGS[flag])
	elif flag == "married":
		var partner = npcs.first("Partner")
		if partner != null:
			partner["role"] = "Spouse"
			partner["married"] = true
			npcs.remember(partner, "You married.")
	elif flag == "has_child":
		if npcs.has("Spouse"):
			var child = npcs.make("Child", 0, 70, {"study": 0, "training": 0})
			npcs.remember(child, "Born.")
	elif flag == "master_dead":
		var master = npcs.first("Master")
		if master != null:
			master["alive"] = false
			npcs.remember(master, "Killed.")
	elif flag == "rival_friend":
		var rival = npcs.first("Rival")
		if rival != null:
			rival["bond"] = max(rival["bond"], 70)
	elif flag == "rival_enemy":
		var rival = npcs.first("Rival")
		if rival != null:
			rival["bond"] = min(rival["bond"], 10)
	elif flag == "brother_betrayed":
		var brother = named(game, "Zhao Hu")
		if brother != null:
			brother["role"] = "Enemy"
			brother["bond"] = 0
			npcs.remember(brother, "Betrayal.")
	elif flag == "bandit" and player.path == "":
		player.path = "Jianghu Outlaw"
	if PEOPLE.has(flag) and (flag != "has_disciple" or not npcs.has("Disciple")):
		var who = PEOPLE[flag]
		if not who.has("name") or named(game, who["name"]) == null:
			var extra = {}
			for key in ["name", "gender", "stage", "occupation"]:
				if who.has(key):
					extra[key] = who[key]
			var person = npcs.make(who["role"], who.get("age", max(player.age, 12)), who["bond"], extra)
			npcs.remember(person, "You met.")
		if who.has("knows"):
			player.flags[who["knows"]] = true


# Called when a flag is cleared.
static func on_clear(game, flag):
	var player = game.player
	var npcs = game.npcs
	if flag in ["affiliated", "orthodox", "cult"] or SECT_FLAGS.has(flag):
		if game.my_sect == null and player.sect != "":
			player.sect = ""
			player.faction = ""
	elif flag == "married":
		var spouse = npcs.first("Spouse")
		if spouse != null:
			spouse["role"] = "Acquaintance"
			spouse["bond"] = 0
			npcs.remember(spouse, "You left.")
	elif flag == "lover":
		var partner = npcs.first("Partner")
		if partner != null:
			partner["role"] = "Acquaintance"
			partner["bond"] = min(partner["bond"], 20)
	elif flag == "has_child":
		for child in npcs.alive("Child"):
			child["bond"] = 0
			npcs.remember(child, "You left.")
	elif flag == "rival":
		var rival = npcs.first("Rival")
		if rival != null:
			rival["role"] = "Friend" if rival["bond"] >= 50 else "Acquaintance"
	elif flag == "has_disciple":
		var disciple = npcs.first("Disciple")
		if disciple != null:
			disciple["role"] = "Friend"
			npcs.remember(disciple, "Left to walk their own path.")
	elif flag in ["knows_killer", "clan_enemy"]:
		var enemy = named(game, PEOPLE[flag]["name"])
		if enemy != null:
			enemy["alive"] = false
			npcs.remember(enemy, "The matter is settled.")


# The living person with this name, or null.
static func named(game, title):
	for person in game.npcs.alive():
		if person["name"] == title:
			return person
	return null
