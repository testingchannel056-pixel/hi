extends RefCounted

# The core Player script. Everything about your character lives here: who they
# are, their status window, how far they have cultivated and which faction they
# belong to. The screen (game.gd) only reads and changes these values.

# --- Cultivation stages, weakest to strongest ---
const STAGES = ["Commoner", "Third-Class", "Second-Class", "First-Class", "Peak", "Transcendent", "Immortal"]

# --- Ranks inside a sect, and the score needed for each ---
# Orthodox sects promote by Reputation. The Demonic Cult promotes by Merit.
const RANKS = ["Outer Disciple", "Inner Disciple", "Core Disciple", "Elder"]
const RANK_SCORES = [0, 30, 80, 160]

# --- Rules you can tweak ---
const QI_PER_STAGE = 50        # Qi for the first breakthrough; later ones need 200, 450, 800...
const STAT_CAP = 15            # highest a stat can go as a commoner...
const STAT_CAP_PER_STAGE = 8   # ...plus this much for every stage above
const STAGE_BOOST = 6          # every stat rises by this much on a breakthrough
const LIFE_PER_STAGE = 15      # extra years of life per breakthrough
const MAX_STREAK = 6           # the cultivation streak stops growing here
const STREAK_BONUS = 0.2       # each streak year adds 20% Qi per session

var surnames = ["Baek", "Namgung", "Jin", "Dan", "Seo", "Yeon", "Tang", "Hwang", "Moyong", "Cheon"]
var given_names = ["Mu-jin", "Ha-rin", "Cheon-ho", "Seol-ah", "Gun-woo", "Yu-na", "Tae-san", "So-hee", "Ryeong", "Hyeon"]
var surname = surnames.pick_random()
var full_name = surname + " " + given_names.pick_random()
var birth_year = randi_range(1100, 1400)
var age = 0
var lifespan = randi_range(65, 85)

# --- Cultivation ---
var stage = 0
var qi_capacity = QI_PER_STAGE
var max_health = 100
var streak = 0                    # years in a row in which you cultivated
var cultivated_this_year = false

# --- The status window ---
# Rewards in encounters use these same names, for example
# {"Strength": 1, "Gold": 20, "Karma": -5}.
var stats = {
	"Health": 100, "Qi": 0,
	"Strength": 5, "Agility": 5, "Martial Insight": 5,
	"Karma": 0, "Reputation": 0, "Merit": 0, "Gold": 0,
}

# --- Faction ---
var faction = ""   # "", "Orthodox" or "Unorthodox"
var sect = ""      # "Mount Hua" for example, or the name of the sect you lead


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
		else:
			stats[stat] += changes[stat]
	for stat in ["Strength", "Agility", "Martial Insight"]:
		stats[stat] = clamp(stats[stat], 1, stat_cap())
	stats["Health"] = clamp(stats["Health"], 0, max_health)
	stats["Qi"] = clamp(stats["Qi"], 0, qi_capacity)
	stats["Karma"] = clamp(stats["Karma"], -100, 100)
	for stat in ["Reputation", "Merit", "Gold"]:
		stats[stat] = max(stats[stat], 0)


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

# Qi gained from one session. Patience pays: every year in a row that you
# keep cultivating makes each session stronger.
func cultivation_gain(bonus = 0):
	var base = 6 + stats["Martial Insight"] / 2 + bonus
	return int(base * (1.0 + streak * STREAK_BONUS))


func cultivate(bonus = 0):
	var gain = cultivation_gain(bonus)
	cultivated_this_year = true
	change({"Qi": gain})
	return gain


# Qi you must gather before you can attempt the next breakthrough.
func qi_needed():
	return QI_PER_STAGE * (stage + 1) * (stage + 1)


func can_break_through():
	return stage < STAGES.size() - 1 and stats["Qi"] >= qi_needed()


func breakthrough_chance():
	var insight_needed = 8 + stage * 8   # the odds are even at this much insight
	return clamp(50 + (stats["Martial Insight"] - insight_needed) * 6, 5, 90)


# Spends the Qi and returns true if you reached the next stage.
func attempt_breakthrough():
	var success = randi_range(1, 100) <= breakthrough_chance()
	if success:
		var spent = qi_needed()
		stats["Qi"] -= spent
		stage += 1
		qi_capacity += qi_needed() - spent
		max_health += 20
		lifespan += LIFE_PER_STAGE
		change({"Strength": STAGE_BOOST, "Agility": STAGE_BOOST, "Martial Insight": STAGE_BOOST, "Health": max_health})
	else:
		stats["Qi"] = stats["Qi"] / 2
		change({"Health": -25})
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


# The lines shown when you press Status.
func status_lines(title):
	return [
		"%s  ·  Age %d  ·  Year %d" % [full_name, age, year()],
		"Stage: %s  ·  Qi %d / %d  ·  Health %d / %d" % [stage_name(), stats["Qi"], qi_capacity, stats["Health"], max_health],
		"Strength %d  ·  Agility %d  ·  Martial Insight %d  (limit %d)" % [stats["Strength"], stats["Agility"], stats["Martial Insight"], stat_cap()],
		"Karma %+d  ·  Reputation %d  ·  Merit %d  ·  Gold %d" % [stats["Karma"], stats["Reputation"], stats["Merit"], stats["Gold"]],
		"Standing: %s" % title,
		"Cultivation streak: %d years  ·  Qi +%d per session" % [streak, cultivation_gain()],
	]
