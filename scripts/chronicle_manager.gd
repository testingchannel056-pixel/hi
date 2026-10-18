extends RefCounted

# The Jianghu Chronicle: what you have seen and done across all your lives.
# It is kept in its own file (user://chronicle.json), apart from the saved
# life, so it survives death and "New life". Nothing in it makes a new life
# stronger; it is a record, and a reason to try a different kind of life.
# "game" is the main screen (game.gd).

const FILE = "user://chronicle.json"
const NEW_FILE = "user://chronicle_new.json"
const Needs = preload("res://scripts/requirements.gd")
const Saves = preload("res://scripts/save_manager.gd")

const LIVES_KEPT = 30    # the most past lives remembered in detail
const LIVES_SHOWN = 5    # how many of them the Chronicle page lists

# Achievements. Each is earned the first time its "needs" are met, in any
# life (same format as everywhere else; see requirements.gd).
const ACHIEVEMENTS = [
	{"id": "first_blood", "name": "First Blood", "text": "Win a fight.", "needs": {"count": {"fights_won": 1}}},
	{"id": "hundred_fights", "name": "A Hundred Fights", "text": "Win a hundred fights in one life.", "needs": {"count": {"fights_won": 100}}},
	{"id": "first_step", "name": "The First Step", "text": "Reach the Third-Class stage.", "needs": {"stage": 1}},
	{"id": "peak", "name": "The View From the Peak", "text": "Reach the Peak stage.", "needs": {"stage": 4}},
	{"id": "immortal", "name": "Beyond the Clouds", "text": "Reach the Immortal stage.", "needs": {"stage": 6}},
	{"id": "householder", "name": "Householder", "text": "Marry.", "needs": {"relation": ["Spouse"]}},
	{"id": "parent", "name": "A Stubborn Chin", "text": "Have a child.", "needs": {"count": {"children": 1}}},
	{"id": "full_house", "name": "A Full House", "text": "Have four children.", "needs": {"count": {"children": 4}}},
	{"id": "founder", "name": "Founder", "text": "Found a sect of your own.", "needs": {"leads_sect": true}},
	{"id": "great_sect", "name": "A Thousand Disciples", "text": "Lead a great sect.", "needs": {"leads_sect": true, "count": {"sect_size": 120}}},
	{"id": "teacher", "name": "Pass It On", "text": "Take a disciple.", "needs": {"relation": ["Disciple"]}},
	{"id": "polymath", "name": "Five Arts", "text": "Know five techniques.", "needs": {"count": {"techniques": 5}}},
	{"id": "awakened", "name": "Fully Awakened", "text": "Grow a talent to its last step.", "needs": {"talent_level": 2}},
	{"id": "rich", "name": "A Thousand Gold", "text": "Hold a thousand Gold.", "needs": {"Gold": 1000}},
	{"id": "landed", "name": "Lord of the Manor", "text": "Own an Estate.", "needs": {"property": ["Estate"]}},
	{"id": "top_of_trade", "name": "Top of the Trade", "text": "Reach the highest rank of a life path.", "needs": {"path_rank": 2}},
	{"id": "hero", "name": "A Name That Travels", "text": "Reach 100 Reputation.", "needs": {"Reputation": 100}},
	{"id": "villain", "name": "The Dark Years", "text": "Sink to -75 Karma.", "needs": {"max": {"Karma": -75}}},
	{"id": "saint", "name": "Clean Hands", "text": "Reach 75 Karma.", "needs": {"Karma": 75}},
	{"id": "scoundrel", "name": "A Very Famous Latrine", "text": "Reach 150 Shame.", "needs": {"Shame": 150}},
	{"id": "centenarian", "name": "A Hundred Winters", "text": "Live to a hundred.", "needs": {"age": 100}},
	{"id": "iron_will", "name": "An Unmoved Heart", "text": "Reach 100 Willpower.", "needs": {"Willpower": 100}},
]

var game
var data = {}   # the whole Chronicle, as it is saved


func _init(main_screen):
	game = main_screen
	load_chronicle()


# ---------------------------------------------------------------------------
# The file
# ---------------------------------------------------------------------------

func load_chronicle():
	data = {"lives": [], "titles": {}, "techniques": [], "people": [], "paths": [], "achievements": [],
		"totals": {"lives": 0, "years": 0, "fights_won": 0, "highest_stage": 0, "oldest": 0, "most_gold": 0}}
	if not FileAccess.file_exists(FILE):
		return
	var json = JSON.new()
	if json.parse(FileAccess.get_file_as_string(FILE)) != OK or not json.data is Dictionary:
		return
	var saved = Saves.whole_numbers(json.data)
	# Anything an older Chronicle does not have keeps its empty start.
	for key in data:
		if saved.has(key) and typeof(saved[key]) == typeof(data[key]):
			data[key] = saved[key]
	for key in ["lives", "years", "fights_won", "highest_stage", "oldest", "most_gold"]:
		if not data["totals"].has(key):
			data["totals"][key] = 0


# Written to a spare file first, so a save that is cut short cannot destroy
# the Chronicle that was already there.
func save_chronicle():
	var file = FileAccess.open(NEW_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var folder = DirAccess.open("user://")
	if folder.file_exists("chronicle.json"):
		folder.remove("chronicle.json")
	folder.rename("chronicle_new.json", "chronicle.json")


# ---------------------------------------------------------------------------
# Recording
# ---------------------------------------------------------------------------

# Adds something to one of the lists if it is not there yet. Returns true
# if it was new.
func discover(list, thing):
	if thing in data[list]:
		return false
	data[list].append(thing)
	return true


# Called on every birthday: notes what this life has discovered so far and
# hands out achievements.
func yearly():
	var player = game.player
	var changed = false
	for technique in player.techniques:
		changed = discover("techniques", technique) or changed
	if player.path != "":
		changed = discover("paths", player.path) or changed
	for person in game.people:
		# Only the people with a story of their own, who are met by name.
		if person["name"] in ["Wei Lang", "Master Yun", "Zhao Hu", "Lin Yue", "Elder Mok", "Guo Tian"]:
			changed = discover("people", person["name"]) or changed
	for achievement in ACHIEVEMENTS:
		if achievement["id"] not in data["achievements"] and earned(achievement):
			data["achievements"].append(achievement["id"])
			changed = true
			game.chime()
			game.write("Achievement: %s. %s" % [achievement["name"], achievement["text"]], game.GOLD)
	if changed:
		save_chronicle()


func earned(achievement):
	var needs = achievement["needs"].duplicate()
	# "property" is only asked for here, so it is checked here.
	if needs.has("property"):
		for property in needs["property"]:
			if property not in game.player.properties:
				return false
		needs.erase("property")
	return Needs.meets(game, needs)


# Called when a life ends, with the title it earned.
func record_life(title):
	var player = game.player
	yearly()
	data["lives"].append({"name": player.full_name, "born": player.birth_year, "age": player.age,
		"stage": player.stage_name(), "title": title, "path": player.path, "background": player.background})
	while data["lives"].size() > LIVES_KEPT:
		data["lives"].pop_front()
	data["titles"][title] = data["titles"].get(title, 0) + 1
	var totals = data["totals"]
	totals["lives"] += 1
	totals["years"] += player.age
	totals["fights_won"] += player.counts.get("fights_won", 0)
	totals["highest_stage"] = max(totals["highest_stage"], player.stage)
	totals["oldest"] = max(totals["oldest"], player.age)
	totals["most_gold"] = max(totals["most_gold"], player.stats["Gold"])
	save_chronicle()


# ---------------------------------------------------------------------------
# The Chronicle page
# ---------------------------------------------------------------------------

func show_chronicle():
	var player = game.player
	var totals = data["totals"]
	game.open_popup("Jianghu Chronicle")
	game.popup_line("%d %s lived  ·  %d years in all  ·  %d fights won" %
		[totals["lives"], "life" if totals["lives"] == 1 else "lives", totals["years"], totals["fights_won"]], game.TEXT, 20)
	game.popup_line("Furthest stage: %s  ·  oldest: %d  ·  richest: %d gold" %
		[player.STAGES[clamp(totals["highest_stage"], 0, player.STAGES.size() - 1)], totals["oldest"], totals["most_gold"]], game.MUTED, 18)

	game.popup_line("Endings found: %d of %d" % [data["titles"].size(), game.legacy.titles.size()], game.GOLD, 20)
	if not data["titles"].is_empty():
		game.popup_line("  ·  ".join(data["titles"].keys()), game.MUTED, 16)

	game.popup_line("Achievements: %d of %d" % [data["achievements"].size(), ACHIEVEMENTS.size()], game.GOLD, 20)
	var names = []
	for achievement in ACHIEVEMENTS:
		if achievement["id"] in data["achievements"]:
			names.append(achievement["name"])
	if not names.is_empty():
		game.popup_line("  ·  ".join(names), game.MUTED, 16)

	game.popup_line("Techniques discovered: %d of %d  ·  life paths walked: %d  ·  people of legend met: %d" %
		[data["techniques"].size(), game.martial.Data.TECHNIQUES.size(), data["paths"].size(), data["people"].size()], game.TEXT, 18)

	if not data["lives"].is_empty():
		game.popup_line("Past lives", game.GOLD, 20)
		var recent = data["lives"].slice(-LIVES_SHOWN)
		recent.reverse()
		for life in recent:
			game.popup_line("%s, %s  ·  died at %d, %s" % [life["name"], life["title"], life["age"], life["stage"]], game.MUTED, 16)
