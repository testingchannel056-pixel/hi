extends RefCounted

# Stories that last longer than one page: flags (things that have happened),
# scenarios found by their "id", and what a choice can do beyond changing
# numbers. In a "win" or "lose" list these words are handled here:
#   "flag": ["helped_swordsman"]     these things have now happened
#   "unflag": ["wanted"]             these are no longer true
#   "learn": "qi_sense"              you learn this technique
#   "goto": "black_box"              the story carries straight on in that scenario
#   "die": true                      this is where your life ends
# "game" is the main screen (game.gd).

const Pack = preload("res://scripts/pack_import.gd")

# The words above, so the rest of the game can tell them from stats.
const SPECIAL = ["flag", "unflag", "learn", "goto", "die"]

# What the Journal says about a flag while it lasts. Flags that are not
# listed are kept quietly.
const THREADS = {
	"wanted": "The law is looking for you.",
	"owes_debt": "You owe money to people who break fingers.",
	"poisoned": "There is poison in your blood. It needs a cure.",
	"tomb_curse": "A curse followed you out of the tomb.",
	"impostor": "A village believes you are the hero called the Azure Sword.",
	"oath_judge": "You swore to a dying man to kill the Ghost-Faced Judge.",
	"great_pill": "You carry a jade pill that makes your next breakthrough certain.",
	"sword_map": "You hold a map to a legendary sword.",
	"legend_sword": "You carry a legendary sword.",
	"demon_sword": "The sword you carry whispers to you.",
	"spirit_beast": "A spirit beast cub follows you.",
	"demonic_manual": "You carry a manual of the blood arts, unopened.",
	"blood_art": "You practise the blood arts. They want feeding.",
	"blood_demon": "You have become something the stories warn about.",
	"sworn_brother": "Zhao Hu is your sworn brother.",
	"brother_betrayed": "Your sworn brotherhood ended in betrayal.",
	"master_dead": "Your master was murdered.",
	"knows_killer": "You know who killed your master: Elder Mok.",
	"clan_enemy": "You know who burned your clan: Guo Tian.",
	"abandoned_family": "You left your family behind.",
	"exiled": "You were cast out of your sect.",
	"cult_hunted": "The Demonic Cult hunts you as a deserter.",
	"spy": "You are a spy inside the Demonic Cult.",
	"soldier": "You are a soldier in the border army.",
	"assassin": "You wear the mask of the Nightless Pavilion.",
	"bandit": "You ride with the Green Forest bandits.",
	"bandit_chief": "You lead a bandit stronghold.",
	"sect_leader": "You lead your sect.",
	"cult_elder": "You are an elder of the Demonic Cult.",
	"cult_lord": "You sit on the throne of the Heavenly Demon.",
	"war_started": "The great war between the Alliance and the Cult has begun.",
	"side_alliance": "You fight for the Alliance.",
	"side_cult": "You fight for the Cult.",
	"hermit": "You have withdrawn from the world.",
	"evil_faction": "Outcasts and killers follow you.",
	"scum_guild": "You belong to a guild of swindlers.",
	"fake_school": "You run a martial school that teaches nothing.",
}

# Flags that are turning points of a life. The first time one is set, it is
# written into the story told at the end ("At 31, ...").
const MEMORABLE = {
	"wanted": "was declared an outlaw.",
	"married": "married.",
	"has_child": "became a parent.",
	"sworn_brother": "swore brotherhood with Zhao Hu.",
	"brother_betrayed": "was betrayed by a sworn brother.",
	"master_dead": "lost a master to murder.",
	"exiled": "was cast out of the sect.",
	"sect_leader": "became the leader of the sect.",
	"cult_lord": "took the throne of the Heavenly Demon.",
	"cult_reformed": "turned the Demonic Cult from its path.",
	"bandit_chief": "became a bandit chief.",
	"legend_sword": "drew a legendary sword from its tomb.",
	"demon_sword": "picked up a sword that whispers.",
	"blood_art": "began to practise the blood arts.",
	"blood_demon": "became the Blood Demon.",
	"war_started": "saw the great war begin.",
	"war_hero": "ended the great war.",
	"war_villain": "brought down the white banner.",
	"alliance_leader": "was named leader of the Alliance.",
	"hermit": "withdrew from the world.",
	"abandoned_family": "left a family behind.",
	"evil_faction": "gathered a following of outcasts and killers.",
	"ascended": "stepped through the door in the sky.",
}

var game
var by_id = {}   # every scenario that has an "id", by that id


func _init(main_screen):
	game = main_screen


# Remembers scenarios by their id, so "goto" can find them.
func register(scenarios):
	for scenario in scenarios:
		if scenario.has("id"):
			by_id[scenario["id"]] = scenario


# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------

func has_flag(flag):
	return game.player.flags.has(flag) or Pack.derived(game, flag)


func set_flag(flag):
	if MEMORABLE.has(flag) and not has_flag(flag):
		game.player.remember(MEMORABLE[flag])
	Pack.on_set(game, flag)
	if flag not in Pack.NEVER_STORED:
		game.player.flags[flag] = true


func clear_flag(flag):
	Pack.on_clear(game, flag)
	game.player.flags.erase(flag)


# ---------------------------------------------------------------------------
# What a choice does beyond the numbers
# ---------------------------------------------------------------------------

# Applies the "flag", "unflag" and "learn" of a "win" or "lose" list.
# ("goto" and "die" are acted on by game.gd, because they decide what the
# page shows next.)
func apply(outcome):
	var flags = outcome.get("flag", [])
	# Flags that bring a person into your life go first, so that the flags
	# about that person find them there.
	for flag in flags:
		if Pack.PEOPLE.has(flag):
			set_flag(flag)
	for flag in flags:
		if not Pack.PEOPLE.has(flag):
			set_flag(flag)
	for flag in outcome.get("unflag", []):
		clear_flag(flag)
	if outcome.has("learn"):
		game.martial.learn(outcome["learn"])


# Called on every birthday: what some flags cost you while they last.
func yearly():
	for flag in Pack.YEARLY_FLAGS:
		if has_flag(flag):
			game.write(Pack.YEARLY_FLAGS[flag]["text"], game.BAD)
			game.write_changes(Pack.YEARLY_FLAGS[flag]["changes"])


# ---------------------------------------------------------------------------
# The Journal: the stories you are in the middle of
# ---------------------------------------------------------------------------

func threads():
	var lines = []
	for flag in THREADS:
		if has_flag(flag):
			lines.append(THREADS[flag])
	return lines


func show_journal():
	game.open_popup("Journal")
	var lines = threads()
	if lines.is_empty():
		game.popup_line("Nothing is hanging over you. Enjoy it while it lasts.", game.MUTED)
	for line in lines:
		game.popup_line(line, game.TEXT, 20)


# ---------------------------------------------------------------------------
# The checker
# ---------------------------------------------------------------------------

# Returns what is wrong with the special words of a "win" or "lose" list.
func mistakes(outcome, word):
	var found = []
	for key in ["flag", "unflag"]:
		if outcome.has(key) and not outcome[key] is Array:
			found.append("\"%s\" in \"%s\" must be a list between [ and ]." % [key, word])
	if outcome.has("goto") and not by_id.has(outcome["goto"]):
		found.append("\"goto\" in \"%s\" points at \"%s\", and no scenario has that id." % [word, outcome["goto"]])
	if outcome.has("learn") and not game.martial.exists(outcome["learn"]):
		found.append("there is no technique called \"%s\"." % outcome["learn"])
	if outcome.has("die") and not outcome["die"] is bool:
		found.append("\"die\" must be true or false, without quotes.")
	return found
