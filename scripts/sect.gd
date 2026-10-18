extends RefCounted

# The sect you lead. It is created when you found a sect, and you spend Gold
# to build it up: facilities, disciples and wars. Scenarios (sect_data.gd)
# can change its "Disciples", "Elders" and "Sect Fame".

# --- Facilities. "cost" is for level 1; level 2 costs double, level 3 triple. ---
const FACILITIES = {
	"Training Hall": {"cost": 80, "text": "Disciples fight harder in wars. Your Strength and Agility training improves."},
	"Scripture Library": {"cost": 80, "text": "Cultivation gives more Qi. Your Martial Insight training improves."},
	"Herb Garden": {"cost": 60, "text": "Restores 10 Health every year."},
	"Market Stalls": {"cost": 60, "text": "Earns 20 Gold every year."},
}
const MAX_LEVEL = 3
const RECRUIT_COST = 30
const ELDER_POWER = 12   # what one elder adds to the sect's strength in a war
# What scenarios can change, and what the sect is called as it grows:
# [disciples and fame together, name].
const STATS = ["Disciples", "Elders", "Sect Fame"]
const STANDINGS = [[0, "A small school"], [25, "A rising sect"], [60, "An established sect"], [120, "A great sect"]]

var sect_name = ""
var disciples = 3
var elders = 0
var fame = 0
var levels = {"Training Hall": 0, "Scripture Library": 0, "Herb Garden": 0, "Market Stalls": 0}
var wars_won = 0


# The sect as plain data for the save file, and back again.
func to_data():
	return {"sect_name": sect_name, "disciples": disciples, "elders": elders, "fame": fame,
		"levels": levels.duplicate(), "wars_won": wars_won}


func from_data(data):
	sect_name = data.get("sect_name", "")
	disciples = data.get("disciples", 3)
	elders = data.get("elders", 0)
	fame = data.get("fame", 0)
	wars_won = data.get("wars_won", 0)
	var saved_levels = data.get("levels", {})
	for facility in levels:
		levels[facility] = clamp(saved_levels.get(facility, 0), 0, MAX_LEVEL)


# Changes "Disciples", "Elders" or "Sect Fame". Returns how much it really
# changed, since none of them can go below zero.
func change(what, amount):
	var before = amount_of(what)
	if what == "Disciples":
		disciples = max(disciples + amount, 0)
	elif what == "Elders":
		elders = max(elders + amount, 0)
	elif what == "Sect Fame":
		fame = max(fame + amount, 0)
	return amount_of(what) - before


func amount_of(what):
	if what == "Disciples":
		return disciples
	if what == "Elders":
		return elders
	return fame


# What the sect is called in the jianghu: "A rising sect"...
func standing():
	var title = STANDINGS[0][1]
	for step in STANDINGS:
		if disciples + fame >= step[0]:
			title = step[1]
	return title


func build_cost(facility):
	return FACILITIES[facility]["cost"] * (levels[facility] + 1)


func build(facility):
	levels[facility] += 1


# New disciples from one recruitment drive. Fame brings more of them: your
# own, and the sect's.
func recruit(player_fame):
	var gained = randi_range(1, 3) + player_fame / 40 + fame / 20
	disciples += gained
	return gained


# Gold earned each year: tuition from disciples, the market stalls, and
# gifts from those who have heard of the sect.
func yearly_income():
	return disciples * 2 + levels["Market Stalls"] * 20 + fame / 5


func yearly_healing():
	return levels["Herb Garden"] * 10


# How strong the sect is in a war. The leader counts for a lot, and so do
# the elders.
func power(player):
	var per_disciple = 4 + levels["Training Hall"] * 2
	return disciples * per_disciple + elders * ELDER_POWER + player.stage * 15 + player.stats["Strength"]


# Fights a war against a rival like {"name": "Black Tiger Gang", "power": 40}.
# Both sides roll around their strength; the higher roll wins.
func wage_war(player, rival):
	var ours = int(power(player) * randf_range(0.8, 1.2))
	var theirs = int(rival["power"] * randf_range(0.8, 1.2))
	var won = ours >= theirs
	var share = randf_range(0.05, 0.2) if won else randf_range(0.25, 0.5)
	var fallen = min(disciples, int(ceil(disciples * share)))
	disciples -= fallen
	if won:
		wars_won += 1
		fame += 5
	else:
		fame = max(fame - 3, 0)
	return {"won": won, "ours": ours, "theirs": theirs, "fallen": fallen}


# The lines shown in the sect report.
func report_lines(player):
	var lines = ["%s  ·  Sect fame %d" % [standing(), fame],
		"Disciples %d  ·  Elders %d  ·  War strength %d  ·  Wars won %d" % [disciples, elders, power(player), wars_won]]
	for facility in levels:
		lines.append("%s: level %d" % [facility, levels[facility]])
	lines.append("Yearly income: %d Gold" % yearly_income())
	return lines
