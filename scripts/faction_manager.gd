extends RefCounted

# Your name in the jianghu, and what each of the great sects thinks of you
# (their "regard", from -100 to 100, kept in player.regard).
# "game" is the main screen (game.gd).

# What your Reputation is called: [Reputation needed, name].
const RENOWN = [[0, "Unknown"], [10, "Noticed"], [25, "Recognized"], [60, "Respected"], [100, "Famous"], [160, "Legendary"]]
# The same for evil deeds (Karma this low or lower) and for Shame.
const DREAD = [[-15, "feared in a few villages"], [-40, "feared across the province"], [-75, "a calamity of the age"]]
const DISGRACE = [[50, "known as a petty rogue"], [90, "known as a shameless scoundrel"], [150, "the greatest scumbag under heaven"]]

const JOIN_REGARD = 20        # a sect's regard for you rises this much when you join it
const LEAVE_REGARD = -15      # ...and changes this much when you walk out
const WAR_REGARD = -30        # ...and this much when you march on it
const SHARED = 4              # a sect's allies feel a quarter of that, its enemies the opposite
const SHUT_OUT = -20          # at this regard or lower a sect will not take you in
const HUNTED = -40            # at this regard or lower a sect sends people after you
const HUNT_CHANCE = 3         # % chance a month that they find you
const HUNT_REST = 2           # years between two such meetings
const BLOOD_PRICE = 40        # Gold that buys peace with a sect that hunts you

var game


func _init(main_screen):
	game = main_screen


# ---------------------------------------------------------------------------
# Your name in the jianghu
# ---------------------------------------------------------------------------

# One word for how well known you are: "Unknown" up to "Legendary".
func renown():
	var title = RENOWN[0][1]
	for step in RENOWN:
		if game.player.stats["Reputation"] >= step[0]:
			title = step[1]
	return title


# The same, with what else people say about you: "Respected, feared across
# the province".
func name_in_jianghu():
	var player = game.player
	var parts = [renown()]
	var dread = ""
	for step in DREAD:
		if player.stats["Karma"] <= step[0]:
			dread = step[1]
	if dread != "":
		parts.append(dread)
	var disgrace = ""
	for step in DISGRACE:
		if player.stats["Shame"] >= step[0]:
			disgrace = step[1]
	if disgrace != "":
		parts.append(disgrace)
	return ", ".join(parts)


# ---------------------------------------------------------------------------
# What the great sects think of you
# ---------------------------------------------------------------------------

func regard(sect):
	return game.player.regard.get(sect, 0)


# Changes one sect's regard for you. Sects on the same side feel a part of
# it too, and sects on the other side feel the opposite.
func change(sect, amount):
	var player = game.player
	var sects = game.World.SECTS
	if not sects.has(sect):
		return
	for other in sects:
		var share = amount
		if other != sect:
			share = amount / SHARED if sects[other]["faction"] == sects[sect]["faction"] else -amount / SHARED
		player.regard[other] = clamp(regard(other) + share, -100, 100)


# One line for the Sect menu: "Wudang +20  ·  Shaolin +5  ·  Demonic Cult -5".
func regard_line():
	var parts = []
	for sect in game.World.SECTS:
		parts.append("%s %+d" % [sect, regard(sect)])
	return "  ·  ".join(parts)


# ---------------------------------------------------------------------------
# A sect that hunts you
# ---------------------------------------------------------------------------

# Returns a scenario for this month if a sect you have wronged finds you,
# otherwise null.
func special_event():
	var player = game.player
	if player.age < 14 or player.year() < player.counts.get("hunt_rest", 0):
		return null
	if randi_range(1, 100) > HUNT_CHANCE:
		return null
	for sect in game.World.SECTS:
		if regard(sect) <= HUNTED and sect != player.sect:
			player.counts["hunt_rest"] = player.year() + HUNT_REST
			return hunt_scenario(sect)
	return null


# Built here rather than written in a data file because it is about one sect.
func hunt_scenario(sect):
	return {
		"id": "sect_hunt",
		"sect": sect,
		"text": "Disciples of %s block the road. \"You owe our sect a debt. We have come to collect.\"" % sect,
		"image": "mountain",
		"choices": [
			{"label": "Fight your way through", "fight": "duelist", "mercy": true, "regard": [sect, -5],
				"win": {"Reputation": 3}},
			{"label": "Pay the blood price", "needs": {"Gold": BLOOD_PRICE}, "regard": [sect, 25],
				"win": {"Gold": -BLOOD_PRICE},
				"win_text": "They count it twice. \"The debt is settled. Do not make another.\""},
			{"label": "Talk them down", "stat": "Reputation", "difficulty": 40, "regard": [sect, 10],
				"win": {}, "win_text": "Your name does what a sword could not.",
				"lose": {"Health": -15}, "lose_text": "They are not here to talk."},
		],
	}
