extends RefCounted

# Checks whether the player meets a list of requirements ("needs"). The same
# format is used everywhere: scenarios, choices, talent steps and life paths.
#
#   {"age": 13, "Smarts": 55}                 at least this much
#   {"max": {"Karma": -5, "age": 30}}         at most this much
#   {"stage": 2}                              at least the Second-Class stage
#   {"background": ["Orphan"]}                one of these backgrounds
#   {"talent": ["Iron Body"]}                 one of these talents
#   {"talent_level": 1}                       the talent has grown this often
#   {"path": ["Scholar", "Teacher"]}          one of these life paths
#   {"sect": ["Wudang"]}                      a member of one of these sects
#   {"faction": ["Orthodox"]}                 one of these factions
#   {"relation": ["Master"]}                  all of these people are in your life
#   {"no_relation": ["Rival"]}                none of these people are in your life
#   {"item": ["Fine Robe"]}                   you carry all of these
#   {"technique": ["qi_sense"]}               you know all of these techniques
#   {"flag": ["helped_swordsman"]}            all of these things have happened
#   {"not_flag": ["wanted"]}                  none of these things have happened
#   {"count": {"trained": 25}}                you have done this at least so often
#   {"leads_sect": true}                      you lead a sect of your own
#
# Anything else is read as the name of a stat with a minimum.

# What missing() returns when the reason is part of the story (a flag) and
# should not be told to the player. A choice like that is not shown at all.
const HIDDEN = "hidden"


static func meets(game, needs):
	return missing(game, needs) == ""


# Returns the first requirement that is not met, in words for the player
# ("Needs Smarts 55"), or "" if everything is met.
static func missing(game, needs):
	var player = game.player
	for key in needs:
		var want = needs[key]
		if key == "max":
			for stat in want:
				if amount(game, stat) > want[stat]:
					return "Needs %s %d or lower" % [stat, want[stat]]
		elif key == "stage":
			if player.stage < want:
				return "Needs the %s stage" % player.STAGES[want]
		elif key == "background":
			if player.background not in want:
				return "Needs a different background"
		elif key == "talent":
			if player.talent not in want:
				return "Needs a different talent"
		elif key == "talent_level":
			if player.talent_level < want:
				return "Your talent has not grown enough"
		elif key == "path":
			if player.path not in want:
				return "Needs the life path: %s" % " or ".join(want)
		elif key == "sect":
			if player.sect not in want:
				return "Needs to belong to %s" % " or ".join(want)
		elif key == "faction":
			if player.faction not in want:
				return "Needs to stand with the %s side" % " or ".join(want)
		elif key == "relation":
			for role in want:
				if not game.has_person(role):
					return "Needs a %s" % role.to_lower()
		elif key == "no_relation":
			for role in want:
				if game.has_person(role):
					return HIDDEN
		elif key == "leads_sect":
			if (game.my_sect != null) != want:
				return HIDDEN
		elif key == "item":
			for item in want:
				if not player.items.has(item):
					return "Needs: %s" % item
		elif key == "technique":
			for technique in want:
				if not player.techniques.has(technique):
					return "Needs the technique %s" % game.martial.title(technique)
		elif key == "flag":
			for flag in want:
				if not game.stories.has_flag(flag):
					return HIDDEN
		elif key == "not_flag":
			for flag in want:
				if game.stories.has_flag(flag):
					return HIDDEN
		elif key == "count":
			for thing in want:
				var have = player.counts.get(thing, 0)
				if thing in ["children", "sect_size"]:
					have = amount(game, thing)
				if have < want[thing]:
					return "Needs more experience"
		elif amount(game, key) < want:
			return "Needs %s %d" % [key.capitalize() if key == "age" else key, want]
	return ""


# The number behind a name: a stat, or your age, stage, talent level, rank
# on your life path, number of children or the size of the sect you lead.
static func amount(game, title):
	var player = game.player
	if title == "age":
		return player.age
	if title == "stage":
		return player.stage
	if title == "talent_level":
		return player.talent_level
	if title == "path_rank":
		return player.path_rank
	if title == "children":
		return game.family.children().size()
	if title == "sect_size":
		return game.my_sect.disciples + game.my_sect.fame if game.my_sect != null else 0
	return player.stats.get(title, 0)


# Returns what is wrong with a "needs" list as sentences, for the scenario
# checker. An empty list means it is fine.
static func mistakes(player, needs):
	if not needs is Dictionary:
		return ["\"needs\" must be written between { and }."]
	var found = []
	var lists = ["background", "talent", "path", "sect", "faction", "relation", "no_relation", "item", "technique", "flag", "not_flag"]
	for key in needs:
		var want = needs[key]
		if key in lists:
			if not want is Array:
				found.append("\"%s\" in \"needs\" must be a list between [ and ]." % key)
		elif key == "max" or key == "count":
			if not want is Dictionary:
				found.append("\"%s\" in \"needs\" must be written between { and }." % key)
		elif key == "leads_sect":
			if not want is bool:
				found.append("\"leads_sect\" in \"needs\" must be true or false, without quotes.")
		elif key in ["age", "stage", "talent_level", "path_rank"] or player.stats.has(key):
			if not want is int:
				found.append("\"%s\" in \"needs\" must be a whole number." % key)
		else:
			found.append("\"%s\" is not something \"needs\" can ask for." % key)
	return found
