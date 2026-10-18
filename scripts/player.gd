extends RefCounted

# The core Player script. Everything about your character lives here: who they
# are, their profile, how far they have cultivated and which faction they
# belong to. The screen (game.gd) only reads and changes these values.

# --- Cultivation stages, weakest to strongest ---
const STAGES = ["Commoner", "Third-Class", "Second-Class", "First-Class", "Peak", "Transcendent", "Immortal"]

# --- Ranks inside a sect, and the score needed for each ---
# Orthodox sects promote by Reputation. The Demonic Cult promotes by Merit.
const RANKS = ["Outer Disciple", "Inner Disciple", "Core Disciple", "Elder"]
const RANK_SCORES = [0, 25, 60, 120]

const Life = preload("res://scripts/life_data.gd")

# --- Rules you can tweak ---
const QI_PER_STAGE = 100      # Qi for the first breakthrough; later ones need 400, 900, 1600...
const STAT_CAP = 15            # highest a stat can go as a commoner...
const STAT_CAP_PER_STAGE = 8   # ...plus this much for every stage above
const STAGE_BOOST = 6          # every stat rises by this much on a breakthrough
const LIFE_PER_STAGE = 15      # extra years of life per breakthrough
const MAX_STREAK = 6           # the cultivation streak stops growing here
const STREAK_BONUS = 0.1       # each streak year adds 10% Qi per session
const MEMORY_LIMIT = 40        # the most turning points remembered in one life

var surnames = ["Baek", "Namgung", "Jin", "Dan", "Seo", "Yeon", "Tang", "Hwang", "Moyong", "Cheon"]
var given_names = ["Mu-jin", "Ha-rin", "Cheon-ho", "Seol-ah", "Gun-woo", "Yu-na", "Tae-san", "So-hee", "Ryeong", "Hyeon"]
var surname = surnames.pick_random()
var full_name = surname + " " + given_names.pick_random()
var gender = "Male"
var face_seed = randi() % 1000000 # a number that fixes the face in your portrait (skin, hair) for life
var appearance = {}
var portrait_outfit = "martial"
var portrait_backdrop = "plain"
var background = "Poor Village"   # see BACKGROUNDS in life_data.gd
var path = ""                     # your life path ("" until you choose one; see LIFE_PATHS)
var path_years = 0                # how many years you have walked it
var path_rank = 0                 # how far you have risen on it (see CAREER_RANKS)
var properties = []               # the property you own (see PROPERTIES in life_data.gd)
var talent = "None"               # the talent you were born with (see TALENTS in world_data.gd)
var talent_level = 0              # how often it has grown (see TALENT_STEPS in life_data.gd)
var talent_name = "None"          # what it is called now
var talent_info = {}              # what it does now
var flags = {}                    # things that have happened in this life: flags["helped_swordsman"] = true
var counts = {}                   # how often you have done things: counts["trained"] = 12
var done = {}                     # scenarios marked "once" that you have already seen, by their id
var regard = {}                   # what each great sect thinks of you: regard["Wudang"] = 20
var memories = []                 # the turning points of this life, for the story told at its end
var techniques = {}               # the techniques you know and their level: techniques["qi_sense"] = 1 (see martial_data.gd)
var birth_year = randi_range(1100, 1400)
var age = 0
var month = 1                     # 1 to 12; month 1 is your birthday
var lifespan = randi_range(65, 85)

# --- Cultivation ---
var stage = 0
var qi_capacity = QI_PER_STAGE
var max_health = 100
var streak = 0                    # years in a row in which you cultivated
var cultivated_this_year = false

# --- Everything with a number ---
# Rewards in encounters use these same names, for example
# {"Strength": 1, "Gold": 20, "Happiness": -5}.
# Happiness, Smarts, Looks and Willpower go from 0 to 100.
var stats = {
	"Health": 100, "Qi": 0,
	"Strength": 5, "Agility": 5, "Martial Insight": 5,
	"Happiness": 50, "Smarts": 50, "Looks": 50, "Willpower": 50,
	"Karma": 0, "Reputation": 0, "Merit": 0, "Shame": 0, "Gold": 0,
}
# Karma is how good or evil you are (-100 to 100). Reputation is how well
# known you are for your deeds. Shame is how despised you are as a cheat
# and a coward, which is a different thing from being feared.
# The stats that go from 0 to 100.
const PERCENT_STATS = ["Happiness", "Smarts", "Looks", "Willpower"]

# --- Faction ---
var faction = ""   # "", "Orthodox" or "Unorthodox"
var sect = ""      # "Mount Hua" for example, or the name of the sect you lead

# --- Inventory: the name of each item you carry and how many you have ---
var items = {}


# Applies what was chosen on the New Life screen. "talents" is the TALENTS
# table from world_data.gd.
func setup(choices, talents):
	full_name = choices["name"]
	surname = full_name.split(" ")[0]
	gender = choices["gender"]
	face_seed = choices.get("seed", face_seed)
	appearance = choices.get("look", {}).duplicate(true)
	portrait_outfit = choices.get("outfit", "martial")
	portrait_backdrop = choices.get("backdrop", "plain")
	background = choices.get("background", background)
	talent = choices["talent"]
	refresh_talent(talents)
	max_health += talent_info.get("max_health", 0)
	stats["Health"] = max(choices["Health"], 10)
	stats["Smarts"] = choices["Smarts"]
	stats["Looks"] = choices["Looks"]
	stats["Happiness"] = choices["Happiness"]


# ---------------------------------------------------------------------------
# Saving and loading
# ---------------------------------------------------------------------------

# Everything about the character that must be remembered, as plain data for
# the save file. When you add a new variable above, add it here and in
# from_data() too.
func to_data():
	return {
		"full_name": full_name, "gender": gender, "seed": face_seed, "talent": talent,
		"appearance": appearance.duplicate(true), "portrait_outfit": portrait_outfit,
		"portrait_backdrop": portrait_backdrop,
		"talent_level": talent_level, "background": background,
		"path": path, "path_years": path_years, "path_rank": path_rank,
		"properties": properties.duplicate(),
		"flags": flags.duplicate(), "counts": counts.duplicate(),
		"done": done.duplicate(), "techniques": techniques.duplicate(),
		"regard": regard.duplicate(), "memories": memories.duplicate(),
		"birth_year": birth_year, "age": age, "month": month, "lifespan": lifespan,
		"stage": stage, "qi_capacity": qi_capacity, "max_health": max_health,
		"streak": streak, "cultivated_this_year": cultivated_this_year,
		"stats": stats.duplicate(), "faction": faction, "sect": sect,
		"items": items.duplicate(),
	}


# Fills the character in from a save. Anything the save does not mention
# keeps its starting value, so saves made before a stat existed still load.
func from_data(data, talents):
	full_name = data.get("full_name", full_name)
	surname = full_name.split(" ")[0]
	gender = data.get("gender", gender)
	# A save from before portraits has no face number. It gets one made from
	# the name, so the same person always has the same face.
	face_seed = data.get("seed", absi(hash(full_name)) % 1000000)
	appearance = data.get("appearance", {})
	if not appearance is Dictionary:
		appearance = {}
	portrait_outfit = data.get("portrait_outfit", "martial")
	portrait_backdrop = data.get("portrait_backdrop", "plain")
	talent = data.get("talent", "None")
	if not talents.has(talent):
		talent = "None"
	talent_level = data.get("talent_level", 0)
	refresh_talent(talents)
	background = data.get("background", background)
	path = data.get("path", "")
	path_years = data.get("path_years", 0)
	path_rank = data.get("path_rank", 0)
	properties = data.get("properties", [])
	flags = data.get("flags", {})
	counts = data.get("counts", {})
	done = data.get("done", {})
	techniques = data.get("techniques", {})
	if not techniques is Dictionary:
		techniques = {}
	regard = data.get("regard", {})
	memories = data.get("memories", [])
	birth_year = data.get("birth_year", birth_year)
	age = data.get("age", 0)
	month = data.get("month", 1)
	lifespan = data.get("lifespan", lifespan)
	stage = clamp(data.get("stage", 0), 0, STAGES.size() - 1)
	# You can always hold at least the Qi the next breakthrough asks for (a
	# save from before that amount was raised would otherwise be stuck).
	qi_capacity = max(data.get("qi_capacity", qi_capacity), qi_needed())
	max_health = data.get("max_health", max_health)
	streak = data.get("streak", 0)
	cultivated_this_year = data.get("cultivated_this_year", false)
	var saved_stats = data.get("stats", {})
	for stat in stats:
		stats[stat] = saved_stats.get(stat, stats[stat])
	faction = data.get("faction", "")
	sect = data.get("sect", "")
	items = data.get("items", {})


# Works out what your talent is called and what it does at its current
# level: the talent you were born with, plus every step it has grown.
# "talents" is the TALENTS table from world_data.gd.
func refresh_talent(talents):
	talent_name = talent
	talent_info = talents[talent].duplicate()
	var steps = Life.TALENT_STEPS.get(talent, [])
	talent_level = clamp(talent_level, 0, steps.size())
	for i in talent_level:
		talent_name = steps[i]["name"]
		for key in steps[i]:
			if key != "name" and key != "needs" and key != "max_health":
				talent_info[key] = steps[i][key]


# The next step your talent can grow to, or null if it is fully grown.
func next_talent_step():
	var steps = Life.TALENT_STEPS.get(talent, [])
	return steps[talent_level] if talent_level < steps.size() else null


# Counts something you did, for talent growth and for the story of your life.
func count(thing, amount = 1):
	counts[thing] = counts.get(thing, 0) + amount


# Writes down a turning point of your life, with your age: "At 23, founded
# the Azure Cloud Sect." The story told when you die is made of these.
func remember(what):
	memories.append("At %d, %s" % [age, what])
	if memories.size() > MEMORY_LIMIT:
		memories.pop_front()


func stage_name():
	return STAGES[stage]


func year():
	return birth_year + age


# The highest Strength, Agility and Martial Insight can go at your stage.
func stat_cap():
	return STAT_CAP + stage * STAT_CAP_PER_STAGE


# Adds rewards or penalties like {"Qi": 10, "Health": -5} and keeps every
# number inside its limits.
func change(changes):
	for stat in changes:
		if stat == "Qi Capacity":
			qi_capacity += changes[stat]
		elif stat == "Max Health":
			max_health = max(max_health + changes[stat], 20)
		else:
			stats[stat] += changes[stat]
	for stat in ["Strength", "Agility", "Martial Insight"]:
		stats[stat] = clamp(stats[stat], 1, stat_cap())
	for stat in PERCENT_STATS:
		stats[stat] = clamp(stats[stat], 0, 100)
	stats["Health"] = clamp(stats["Health"], 0, max_health)
	stats["Qi"] = clamp(stats["Qi"], 0, qi_capacity)
	stats["Karma"] = clamp(stats["Karma"], -100, 100)
	for stat in ["Reputation", "Merit", "Shame", "Gold"]:
		stats[stat] = max(stats[stat], 0)


func add_item(item):
	items[item] = items.get(item, 0) + 1


func remove_item(item):
	items[item] -= 1
	if items[item] <= 0:
		items.erase(item)


# Moves the calendar on by one month. Returns true when a new year begins.
func next_month():
	month += 1
	if month <= 12:
		return false
	month = 1
	grow_older()
	return true


# Called once every time a year passes.
func grow_older():
	age += 1
	streak = min(streak + 1, MAX_STREAK) if cultivated_this_year else 0
	cultivated_this_year = false


# ---------------------------------------------------------------------------
# Dice
# ---------------------------------------------------------------------------

# Chance (in %) to pass a check: a 20-sided die + your stat against a
# difficulty. Checks get tougher at higher stages, because the people you
# meet there are stronger too.
func check_chance(stat, difficulty):
	if stat in PERCENT_STATS:
		# These go from 0 to 100, and so does their difficulty: the odds are
		# even when your stat matches it.
		return clamp(50 + stats[stat] - difficulty, 5, 95)
	if stat == "Reputation":
		# Your name against how much name the moment asks for.
		return clamp(50 + (stats[stat] - difficulty) * 2, 5, 95)
	return clamp(21 - difficulty - stage * 6 + stats[stat], 1, 19) * 5


# Chance (in %) that training raises a stat. It gets harder the closer the
# stat is to its cap.
func train_chance(stat, bonus = 0):
	var room = stat_cap() - stats[stat]
	if room <= 0:
		return 0
	return clamp(10 + room * 6 + bonus, 5, 95)


# ---------------------------------------------------------------------------
# Cultivation
# ---------------------------------------------------------------------------

# How your mood changes the Qi you gather: misery slows you, joy helps.
func mood():
	if stats["Happiness"] < 25:
		return 0.8
	if stats["Happiness"] > 75:
		return 1.1
	return 1.0


# Qi gained from one session. Patience pays: every year in a row that you
# keep cultivating makes each session stronger.
func cultivation_gain(bonus = 0):
	var base = 2 + stats["Martial Insight"] / 4 + bonus
	var talent_bonus = 1.0 + talent_info.get("qi_bonus", 0.0)
	return int(base * (1.0 + streak * STREAK_BONUS) * talent_bonus * mood())


func cultivate(bonus = 0):
	var gain = cultivation_gain(bonus)
	cultivated_this_year = true
	change({"Qi": gain})
	return gain


# Qi you must gather before you can attempt the next breakthrough. Each
# stage asks for far more than the last: 100, 800, 2700, 6400, 12500, 21600.
# The top stages are meant to take a lifetime, and most lives never see them.
func qi_needed():
	return QI_PER_STAGE * (stage + 1) * (stage + 1) * (stage + 1)


func can_break_through():
	return stage < STAGES.size() - 1 and stats["Qi"] >= qi_needed()


func breakthrough_chance():
	var insight_needed = 8 + stage * 8   # the odds are even at this much insight
	var odds = 50 + (stats["Martial Insight"] - insight_needed) * 6
	# A steady will helps a little: Willpower 100 adds 10, Willpower 0 takes 10.
	odds += (stats["Willpower"] - 50) / 5 + talent_info.get("break_bonus", 0)
	return clamp(odds, 5, 90)


# Spends the Qi and returns true if you reached the next stage. "certain"
# skips the dice.
func attempt_breakthrough(certain = false):
	var success = certain or randi_range(1, 100) <= breakthrough_chance()
	if success:
		var spent = qi_needed()
		stats["Qi"] -= spent
		stage += 1
		qi_capacity += qi_needed() - spent
		max_health += 20
		lifespan += LIFE_PER_STAGE
		change({"Strength": STAGE_BOOST, "Agility": STAGE_BOOST, "Martial Insight": STAGE_BOOST,
			"Health": max_health, "Happiness": 15})
	else:
		stats["Qi"] = stats["Qi"] / 2
		change({"Health": -25, "Happiness": -10})
	return success


# ---------------------------------------------------------------------------
# Faction and rank
# ---------------------------------------------------------------------------

# The number your faction judges you by.
func rank_score():
	return stats["Merit"] if faction == "Unorthodox" else stats["Reputation"]


func rank():
	var result = 0
	for i in RANKS.size():
		if rank_score() >= RANK_SCORES[i]:
			result = i
	return result
