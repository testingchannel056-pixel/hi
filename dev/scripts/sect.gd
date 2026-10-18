extends RefCounted

# The sect you lead. It is created when you found a sect, and you spend Gold
# to build it up: facilities, disciples and wars.

# --- Facilities. "cost" is for level 1; level 2 costs double, level 3 triple. ---
const FACILITIES = {
	"Training Hall": {"cost": 80, "text": "Disciples fight harder in wars. Your Strength and Agility training improves."},
	"Scripture Library": {"cost": 80, "text": "Cultivation gives more Qi. Your Martial Insight training improves."},
	"Herb Garden": {"cost": 60, "text": "Restores 10 Health every year."},
	"Market Stalls": {"cost": 60, "text": "Earns 20 Gold every year."},
}
const MAX_LEVEL = 3
const RECRUIT_COST = 30

var sect_name = ""
var disciples = 3
var levels = {"Training Hall": 0, "Scripture Library": 0, "Herb Garden": 0, "Market Stalls": 0}
var wars_won = 0


func build_cost(facility):
	return FACILITIES[facility]["cost"] * (levels[facility] + 1)


func build(facility):
	levels[facility] += 1


# New disciples from one recruitment drive. Fame brings more of them.
func recruit(fame):
	var gained = randi_range(1, 3) + fame / 40
	disciples += gained
	return gained


# Gold earned each year: tuition from disciples plus the market stalls.
func yearly_income():
	return disciples * 2 + levels["Market Stalls"] * 20


func yearly_healing():
	return levels["Herb Garden"] * 10


# How strong the sect is in a war. The leader counts for a lot.
func power(player):
	var per_disciple = 4 + levels["Training Hall"] * 2
	return disciples * per_disciple + player.stage * 15 + player.stats["Strength"]


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
	return {"won": won, "ours": ours, "theirs": theirs, "fallen": fallen}


# The lines shown in the sect report.
func report_lines(player):
	var lines = ["%d disciples  ·  War strength %d  ·  Wars won %d" % [disciples, power(player), wars_won]]
	for facility in levels:
		lines.append("%s: level %d" % [facility, levels[facility]])
	lines.append("Yearly income: %d Gold" % yearly_income())
	return lines
