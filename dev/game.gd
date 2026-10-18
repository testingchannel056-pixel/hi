extends Control

# The main screen. It runs the yearly loop and draws everything.
#   scripts/player.gd      - your character: status window, cultivation, faction
#   scripts/sect.gd        - the sect you can found and manage
#   scripts/world_data.gd  - encounters, enemies, sects and activities as data
const PlayerScript = preload("res://scripts/player.gd")
const SectScript = preload("res://scripts/sect.gd")
const World = preload("res://scripts/world_data.gd")

# --- Colours used in the life log ---
const TEXT = "#e8dcc0"
const GOOD = "#8fc785"
const BAD = "#e0736b"
const GOLD = "#d4b06b"
const MUTED = "#9e9685"

# --- Rules you can tweak ---
const ACTIONS_PER_YEAR = 3   # activities / relationship / sect actions per year
const GROWN_UP_AGE = 6       # before this you can only press "+ Age"
const SECT_AGE = 10          # youngest age at which a sect will take you
const QI_BURST_COST = 10       # Qi Burst costs this much per stage (10, 20, 30...)
const FOUND_SECT_COST = 100  # Gold needed to found your own sect...
const FOUND_SECT_STAGE = 2   # ...and the stage needed (2 = Second-Class)
const EXPEL_KARMA = -20      # Orthodox sects expel you below this Karma

var player = PlayerScript.new()
var my_sect = null           # the sect you lead (null until you found one)
var rivals = World.RIVALS.duplicate(true)
var people = []
var actions_left = 0
var known_rank = 0
var last_encounter = null

# --- Avatar pictures (32x32 pixel art) ---
var avatar_baby = preload("res://baby.png")
var avatar_child = preload("res://child.png")
var avatar_youth = preload("res://youth.png")
var avatar_adult = preload("res://adult.png")
var avatar_elder = preload("res://elder.png")

# --- The fight that is happening right now (null when not fighting) ---
var enemy = null
var fight_choice = null
var guarding = false

# --- Links to the nodes in your scene (names must match exactly) ---
@onready var avatar = $Margin/VBox/Top/AvatarFrame/Avatar
@onready var name_label = $Margin/VBox/Top/Info/NameLabel
@onready var date_label = $Margin/VBox/Top/Info/DateRow/DateLabel
@onready var stage_label = $Margin/VBox/Top/Info/DateRow/RealmBadge/RealmLabel
@onready var health_bar = $Margin/VBox/Top/Info/HealthBar
@onready var qi_bar = $Margin/VBox/Top/Info/QiBar
@onready var stats_box = $Margin/VBox/Stats
@onready var world_label = $Margin/VBox/WorldLabel
@onready var log_text = $Margin/VBox/LogCard/Log
@onready var enemy_bar = $Margin/VBox/EnemyBar
@onready var actions_label = $Margin/VBox/ActionsLabel
@onready var choices_box = $Margin/VBox/Choices
@onready var bottom_bar = $Margin/VBox/BottomBar
@onready var activities_button = $Margin/VBox/BottomBar/Menus/ActivitiesButton
@onready var people_button = $Margin/VBox/BottomBar/Menus/PeopleButton
@onready var sect_button = $Margin/VBox/BottomBar/Menus/SectButton
@onready var status_button = $Margin/VBox/BottomBar/Menus/StatusButton
@onready var age_button = $Margin/VBox/BottomBar/AgeButton

# One "chip" for each of these stats. Filled in by _ready().
var chip_stats = ["Strength", "Agility", "Martial Insight"]
var stat_values = {}


func _ready():
	for stat in chip_stats:
		var chip = PanelContainer.new()
		chip.theme_type_variation = "StatChip"
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box = VBoxContainer.new()
		var name_text = Label.new()
		name_text.text = stat
		name_text.theme_type_variation = "StatName"
		name_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var value_text = Label.new()
		value_text.theme_type_variation = "StatValue"
		value_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_text)
		box.add_child(value_text)
		chip.add_child(box)
		stats_box.add_child(chip)
		stat_values[stat] = value_text

	activities_button.pressed.connect(show_activities)
	people_button.pressed.connect(show_people)
	sect_button.pressed.connect(show_sect)
	status_button.pressed.connect(write_status)
	age_button.pressed.connect(age_up)

	var father = add_person("Father", randi_range(22, 35), randi_range(60, 90))
	var mother = add_person("Mother", randi_range(20, 32), randi_range(70, 95))
	write_header("BORN")
	write("You are born into the murim world as %s, child of %s and %s."
		% [player.full_name, father["name"], mother["name"]])
	show_idle()


# Number keys 1-9 press the matching button. Space presses "+ Age".
func _unhandled_key_input(event):
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_SPACE and bottom_bar.visible:
		age_up()
		return
	var index = event.keycode - KEY_1
	if index >= 0 and index < choices_box.get_child_count():
		var button = choices_box.get_child(index)
		if not button.disabled:
			button.pressed.emit()


# ---------------------------------------------------------------------------
# The yearly loop
# ---------------------------------------------------------------------------

func age_up():
	player.grow_older()
	actions_left = ACTIONS_PER_YEAR if player.age >= GROWN_UP_AGE else 0
	write_header("AGE %d" % player.age)
	age_people()
	if player.age >= player.lifespan:
		die("You passed away peacefully of old age.")
		return
	player.change({"Health": 5})
	yearly_upkeep()
	if player.age < GROWN_UP_AGE:
		write(World.CHILDHOOD[min(player.age, World.CHILDHOOD.size()) - 1])
		show_idle()
	else:
		show_encounter(pick_encounter())


# Income, stipends and consequences that arrive once a year.
func yearly_upkeep():
	if my_sect != null:
		var gained = apply({"Gold": my_sect.yearly_income(), "Health": my_sect.yearly_healing()})
		write("%s: %d disciples train under you.   %s" % [my_sect.sect_name, my_sect.disciples, gained], MUTED)
		if player.faction == "Orthodox" and player.stats["Karma"] < EXPEL_KARMA:
			player.faction = "Unorthodox"
			write("Word of your deeds spreads. The Alliance brands the %s unorthodox." % my_sect.sect_name, BAD)
	elif player.sect != "":
		if player.faction == "Orthodox" and player.stats["Karma"] < EXPEL_KARMA:
			write("The elders of %s strike your name from the rolls for your misdeeds." % player.sect, BAD)
			player.faction = ""
			player.sect = ""
		else:
			var gained = apply({"Gold": World.STIPENDS[player.rank()]})
			write("%s pays your stipend.   %s" % [player.sect, gained], MUTED)


func pick_encounter():
	var options = []
	for encounter in World.ENCOUNTERS:
		if player.age < encounter.get("min_age", GROWN_UP_AGE) or encounter == last_encounter:
			continue
		if encounter.has("faction") and encounter["faction"] != player.faction:
			continue
		options.append(encounter)
	last_encounter = options.pick_random()
	return last_encounter


func show_encounter(encounter):
	write(encounter["text"])
	refresh_screen()
	open_choices(1)
	actions_label.hide()
	for choice in encounter["choices"]:
		add_choice(choice["label"], hint_for(choice), choose.bind(choice))


# The screen between encounters: + Age and the four menus.
func show_idle():
	refresh_screen()
	clear_choices()
	enemy_bar.hide()
	actions_label.show()
	bottom_bar.show()


func end_turn():
	if player.stats["Health"] <= 0:
		die("Your injuries were too great. Your life has ended.")
		return
	check_rank()
	show_idle()


func die(reason):
	write(reason, BAD)
	write("You lived %d years and reached the %s stage." % [player.age, player.stage_name()], GOLD)
	if my_sect != null:
		write("The %s carries on your name with %d disciples." % [my_sect.sect_name, my_sect.disciples], GOLD)
	refresh_screen()
	avatar.modulate = Color(0.45, 0.45, 0.5)
	enemy_bar.hide()
	actions_label.hide()
	open_choices(1)
	make_gold(add_choice("Be reborn", "", get_tree().reload_current_scene))


# ---------------------------------------------------------------------------
# Choices and dice
# ---------------------------------------------------------------------------

# Chance (in %) that a choice succeeds.
func chance(choice):
	if choice.has("percent"):
		return choice["percent"]
	if choice.has("train"):
		var bonus = choice.get("bonus", 0) + training_bonus(choice["train"])
		return player.train_chance(choice["train"], bonus)
	if choice.has("stat"):
		return player.check_chance(choice["stat"], choice["difficulty"])
	return 100


# Extra training chance from your sect.
func training_bonus(stat):
	if my_sect != null:
		if stat == "Martial Insight":
			return my_sect.levels["Scripture Library"] * 10
		return my_sect.levels["Training Hall"] * 10
	if player.sect != "" and World.SECTS[player.sect]["trains"] == stat:
		return 15
	return 0


# The small text on the right side of a choice button.
func hint_for(choice):
	if choice.has("fight"):
		return "Duel" if choice.get("friendly", false) else "Fight"
	if choice.has("train") or choice.has("percent"):
		return "%d%%" % chance(choice)
	if choice.has("stat"):
		return "%s  %d%%" % [choice["stat"], chance(choice)]
	return ""


func choose(choice):
	if choice.has("fight"):
		start_fight(choice)
	else:
		finish_choice(choice, randi_range(1, 100) <= chance(choice))


# Hands out the "win" or "lose" rewards of a choice and writes what happened.
func finish_choice(choice, success):
	var result = choice.get("win", {}) if success else choice.get("lose", {})
	var real_fight = choice.has("fight") and not choice.get("friendly", false)
	if success and real_fight and player.faction == "Unorthodox":
		# The Demonic Cult rewards every victory.
		result = result.duplicate()
		result["Merit"] = result.get("Merit", 0) + 3

	var parts = []
	if chance(choice) < 100:
		parts.append("Success!" if success else "You failed...")
	var changed = apply(result)
	if changed != "":
		parts.append(changed)
	if choice.has("person") and (success or choice.has("fight")):
		var person = choice["person"]
		person["bond"] = min(person["bond"] + choice["bond"], 100)
		parts.append("Bond with %s +%d" % [person["name"], choice["bond"]])
	if not parts.is_empty():
		write("   ".join(parts), GOOD if success else BAD)

	if success and choice.has("meet"):
		meet(choice["meet"])
	if choice.has("join"):
		if success:
			join_sect(choice["join"])
		else:
			write("%s turns you away. Come back when you are stronger." % choice["join"], MUTED)
	end_turn()


# Turns {"Qi": 30, "Health": -20} into "Qi +30, Health -20".
func describe(changes):
	var parts = []
	for stat in changes:
		parts.append("%s %+d" % [stat, changes[stat]])
	return ", ".join(parts)


# Changes the player's numbers and describes what really changed,
# for example "Qi +30, Health -20".
func apply(changes):
	var before = player.stats.duplicate()
	var capacity = player.qi_capacity
	player.change(changes)
	var parts = []
	for stat in changes:
		var difference = player.stats.get(stat, 0) - before.get(stat, 0)
		if stat == "Qi Capacity":
			difference = player.qi_capacity - capacity
		if difference != 0:
			parts.append("%s %+d" % [stat, difference])
	return ", ".join(parts)


# ---------------------------------------------------------------------------
# Activities and cultivation
# ---------------------------------------------------------------------------

func show_activities():
	open_choices(2)
	for activity in World.ACTIVITIES:
		if player.age < activity.get("min_age", GROWN_UP_AGE):
			continue
		if activity.has("cultivate"):
			add_choice(activity["label"], "Qi +%d" % player.cultivation_gain(library_bonus()), cultivate)
		else:
			var hint = hint_for(activity)
			if hint == "":
				hint = describe(activity["win"])
			add_choice(activity["label"], hint, do_action.bind(activity))
	if player.can_break_through():
		make_gold(add_choice("Breakthrough", "%d%%" % player.breakthrough_chance(), breakthrough))
	add_choice("Back", "", show_idle)


# Spends one of this year's actions on an activity, a person or your sect.
func do_action(choice):
	actions_left -= 1
	if choice.has("text"):
		write(choice["text"], MUTED)
	choose(choice)


func library_bonus():
	return my_sect.levels["Scripture Library"] * 3 if my_sect != null else 0


# The cultivate loop: sit, gather Qi, repeat. Cultivating every year builds a
# streak that makes each session stronger; skipping a year resets it.
func cultivate():
	actions_left -= 1
	var gained = player.cultivate(library_bonus())
	write("You sit cross-legged and circulate your Qi through the meridians.", MUTED)
	write("Qi +%d   Now %d / %d.   Streak: %d years in a row." %
		[gained, player.stats["Qi"], player.qi_capacity, player.streak], GOOD)
	if player.can_break_through():
		write("You have gathered enough Qi to attempt a breakthrough.", GOLD)
	end_turn()


func breakthrough():
	actions_left -= 1
	write("You seal yourself away and drive your Qi against the barrier.", MUTED)
	if player.attempt_breakthrough():
		write("Breakthrough! You are now %s." % player.stage_name(), GOLD)
		write("All stats +%d   Max Health %d   Qi Capacity %d   Stat limit %d" %
			[player.STAGE_BOOST, player.max_health, player.qi_capacity, player.stat_cap()], GOOD)
	else:
		write("Your Qi runs wild and the breakthrough fails.   Health -25, half your Qi is lost.", BAD)
	end_turn()


# ---------------------------------------------------------------------------
# Factions and sects
# ---------------------------------------------------------------------------

func show_sect():
	if my_sect != null:
		show_my_sect()
		return
	open_choices(2)
	if player.sect == "":
		for sect_name in World.SECTS:
			var info = World.SECTS[sect_name]
			var join = {"join": sect_name, "text": info["text"]}
			if info["faction"] == "Orthodox":
				# The Alliance tests your skill and turns away the wicked.
				join["stat"] = info["trains"]
				join["difficulty"] = 12
				var button = add_choice("Join " + sect_name, "%d%%" % chance(join), do_action.bind(join))
				if player.stats["Karma"] < 0:
					button.get_child(0).text = "Karma 0+"
					button.disabled = true
			else:
				# The Cult only asks whether you can win.
				join["fight"] = "initiate"
				add_choice("Join " + sect_name, "Fight", do_action.bind(join))
	else:
		var mission = World.FACTIONS[player.faction]["mission"]
		add_choice("Sect mission", "Fight", do_action.bind(mission))
		add_choice("Leave " + player.sect, "", leave_sect)
	var found = add_choice("Found a sect", "%d gold" % FOUND_SECT_COST, found_sect)
	disable_without_actions()
	found.disabled = found.disabled or player.stage < FOUND_SECT_STAGE or player.stats["Gold"] < FOUND_SECT_COST
	add_choice("Back", "", show_idle)


func join_sect(sect_name):
	player.sect = sect_name
	player.faction = World.SECTS[sect_name]["faction"]
	known_rank = player.rank()
	var info = World.FACTIONS[player.faction]
	write("%s accepts you. Your rank: %s." % [sect_name, player.RANKS[known_rank]], GOLD)
	write("%s values %s." % [info["name"], info["values"]], MUTED)


func leave_sect():
	write("You bow three times at the gate and leave %s behind.   %s" %
		[player.sect, apply({"Reputation": -5})], MUTED)
	player.sect = ""
	player.faction = ""
	show_idle()


# Writes a line when your Reputation (or Merit) earns you a higher rank.
func check_rank():
	if my_sect != null or player.sect == "":
		return
	var rank = player.rank()
	if rank > known_rank:
		write("You are promoted to %s of %s." % [player.RANKS[rank], player.sect], GOLD)
	known_rank = rank


func found_sect():
	actions_left -= 1
	if player.sect != "":
		write("You leave %s to walk your own path." % player.sect, MUTED)
	if player.faction == "":
		player.faction = "Orthodox" if player.stats["Karma"] >= 0 else "Unorthodox"
	my_sect = SectScript.new()
	my_sect.sect_name = World.SECT_NAMES.pick_random()
	player.sect = my_sect.sect_name
	write("You plant your banner on a quiet mountainside.   %s" % apply({"Gold": -FOUND_SECT_COST}), MUTED)
	write("The %s is founded. %d disciples kneel before you." % [my_sect.sect_name, my_sect.disciples], GOLD)
	write("It stands with %s." % World.FACTIONS[player.faction]["name"], MUTED)
	end_turn()


# ---------------------------------------------------------------------------
# Sect management (once you lead a sect)
# ---------------------------------------------------------------------------

func show_my_sect():
	open_choices(2)
	add_choice("Build", "", show_build)
	var recruit = add_choice("Recruit", "%d gold" % my_sect.RECRUIT_COST, recruit_disciples)
	add_choice("Wage war", "", show_war)
	disable_without_actions()
	recruit.disabled = recruit.disabled or player.stats["Gold"] < my_sect.RECRUIT_COST
	add_choice("Sect report", "", write_sect_report)
	add_choice("Back", "", show_idle)


func show_build():
	open_choices(2)
	for facility in my_sect.levels:
		var level = my_sect.levels[facility]
		if level >= my_sect.MAX_LEVEL:
			add_choice(facility, "Max", build.bind(facility)).disabled = true
		else:
			var cost = my_sect.build_cost(facility)
			var button = add_choice(facility, "%d gold" % cost, build.bind(facility))
			button.disabled = player.stats["Gold"] < cost or actions_left <= 0
	add_choice("Back", "", show_my_sect)


func build(facility):
	actions_left -= 1
	var spent = apply({"Gold": -my_sect.build_cost(facility)})
	my_sect.build(facility)
	write("Carpenters and masons get to work.   %s" % spent, MUTED)
	write("%s is now level %d." % [facility, my_sect.levels[facility]], GOLD)
	write(my_sect.FACILITIES[facility]["text"], MUTED)
	end_turn()


func recruit_disciples():
	actions_left -= 1
	var spent = apply({"Gold": -my_sect.RECRUIT_COST})
	var gained = my_sect.recruit(player.rank_score())
	write("You send word through the villages that the sect is taking disciples.   %s" % spent, MUTED)
	write("%d new disciples join. The %s now has %d." % [gained, my_sect.sect_name, my_sect.disciples], GOOD)
	end_turn()


func show_war():
	open_choices(2)
	for rival in rivals:
		# You cannot attack your own faction.
		if rival["side"] != player.faction:
			var hint = "%d vs %d" % [my_sect.power(player), rival["power"]]
			add_choice(rival["name"], hint, wage_war.bind(rival))
	disable_without_actions()
	add_choice("Back", "", show_my_sect)


func wage_war(rival):
	actions_left -= 1
	var result = my_sect.wage_war(player, rival)
	write("WAR  ·  The %s marches on %s." % [my_sect.sect_name, rival["name"]], GOLD)
	write("Your strength %d  ·  Their strength %d" % [result["ours"], result["theirs"]], MUTED)
	if result["won"]:
		# Attacking the righteous is evil; crushing outlaws and cultists is not.
		var spoils = {"Gold": rival["gold"], "Reputation": rival["power"] / 10}
		spoils["Karma"] = -15 if rival["side"] == "Orthodox" else 5
		if player.faction == "Unorthodox":
			spoils["Merit"] = rival["power"] / 8
		write("Victory! Their gates fall and their banner burns.   %s" % apply(spoils), GOOD)
		rival["power"] = int(rival["power"] * 1.3)
	else:
		write("Defeat. Your disciples are driven back down the mountain.   %s" %
			apply({"Reputation": -10, "Health": -15}), BAD)
	write("Disciples lost: %d  ·  Remaining: %d" % [result["fallen"], my_sect.disciples], MUTED)
	end_turn()


# ---------------------------------------------------------------------------
# Status window
# ---------------------------------------------------------------------------

# Where you stand in the world, as one line.
func standing():
	if player.faction == "":
		return "Wanderer with no sect"
	var side = World.FACTIONS[player.faction]["name"]
	if my_sect != null:
		return "Leader of the %s  ·  %s" % [my_sect.sect_name, side]
	return "%s of %s  ·  %s" % [player.RANKS[player.rank()], player.sect, side]


func write_status():
	write_title("STATUS WINDOW")
	for line in player.status_lines(standing()):
		write(line)


func write_sect_report():
	write_title(my_sect.sect_name.to_upper())
	for line in my_sect.report_lines(player):
		write(line)


# ---------------------------------------------------------------------------
# Relationships
# ---------------------------------------------------------------------------

func add_person(role, person_age, bond):
	var family = player.surname if role == "Father" else player.surnames.pick_random()
	var person = {
		"role": role,
		"name": family + " " + player.given_names.pick_random(),
		"age": person_age,
		"bond": bond,
		"lifespan": person_age + randi_range(30, 60),
	}
	people.append(person)
	return person


func has_person(role):
	for person in people:
		if person["role"] == role:
			return true
	return false


# Called when a choice has "meet". You only ever have one of each role.
func meet(role):
	if has_person(role):
		return
	var person
	if role == "Master":
		person = add_person(role, randi_range(50, 80), 40)
		person["lifespan"] += 80
	else:
		person = add_person(role, player.age + randi_range(-1, 2), 50 if role == "Friend" else 20)
	write("%s is now your %s." % [person["name"], role.to_lower()], GOLD)


# Everyone gets a year older. Bonds fade a little if you ignore people.
func age_people():
	for person in people.duplicate():
		person["age"] += 1
		person["bond"] = max(person["bond"] - 3, 0)
		if person["age"] >= person["lifespan"]:
			people.erase(person)
			write("Your %s, %s, has passed away." % [person["role"].to_lower(), person["name"]], BAD)


func show_people():
	open_choices(1)
	for person in people:
		var title = "%s  ·  %s" % [person["role"], person["name"]]
		var hint = "Age %d  ·  Bond %d" % [person["age"], person["bond"]]
		add_choice(title, hint, show_person.bind(person))
	add_choice("Back", "", show_idle)


func show_person(person):
	var info = World.ROLES[person["role"]]
	var short_name = person["name"]
	open_choices(1)

	var time = {"person": person, "bond": 12,
		"text": "You spend the day with %s." % short_name}
	add_choice("Spend time together", "Bond +12", do_action.bind(time))

	# Guidance works better the closer you are.
	var guidance = {"person": person, "bond": 3, "win": info["guidance"],
		"text": "You ask %s for guidance." % short_name}
	if info.has("train"):
		guidance["train"] = info["train"]
		guidance["bonus"] = person["bond"] / 4
	else:
		guidance["percent"] = person["bond"]
	var teaches = info["guidance"].keys()[0]
	add_choice("Ask for guidance", "%s  ·  %d%%" % [teaches, chance(guidance)], do_action.bind(guidance))

	if player.age >= 10:
		var power = info["power"]
		var spar = {"person": person, "bond": 5, "friendly": true, "win": {"Qi": 5},
			"text": "You bow to %s and take your stance." % short_name,
			"fight": {"name": short_name, "health": int(35 * power), "attack": int(6 * power),
				"defense": int(6 * power), "damage": int(6 * power)}}
		add_choice("Spar", "Duel", do_action.bind(spar))

	disable_without_actions()
	add_choice("Back", "", show_people)


# ---------------------------------------------------------------------------
# Fighting
# ---------------------------------------------------------------------------

func start_fight(choice):
	fight_choice = choice
	var template = choice["fight"]
	if template is String:
		if template == "random":
			template = World.HUNT.pick_random()
		template = World.ENEMIES[template]

	# Enemies are written for a Commoner. They grow with your stage.
	enemy = template.duplicate()
	enemy["health"] = int(enemy["health"] * (1 + player.stage * 0.5))
	enemy["damage"] = int(enemy["damage"] * (1 + player.stage * 0.25))
	enemy["attack"] += player.stage * 6
	enemy["defense"] += player.stage * 6
	enemy["max_health"] = enemy["health"]

	guarding = false
	enemy_bar.max_value = enemy["max_health"]
	enemy_bar.value = enemy["health"]
	write("%s stands before you!" % enemy["name"], GOLD)
	show_fight()


func burst_cost():
	return QI_BURST_COST * (player.stage + 1)


# Agility decides who hits whom.
func strike_chance():
	return clamp(50 + (player.stats["Agility"] - enemy["defense"]) * 5, 10, 95)


func enemy_hit_chance():
	return clamp(50 + (enemy["attack"] - player.stats["Agility"]) * 5, 10, 95)


func flee_chance():
	return clamp(50 + (player.stats["Agility"] - enemy["attack"]) * 5, 10, 95)


func show_fight():
	refresh_screen()
	open_choices(1)
	actions_label.hide()
	enemy_bar.show()
	set_bar(enemy_bar, enemy["name"], enemy["health"], enemy["max_health"])
	add_choice("Strike", "Hit  %d%%" % strike_chance(), strike)
	var burst = add_choice("Qi Burst", "Costs %d Qi, never misses" % burst_cost(), qi_burst)
	burst.disabled = player.stats["Qi"] < burst_cost()
	add_choice("Guard", "Half damage, Qi +5", guard)
	if fight_choice.get("friendly", false):
		add_choice("Yield", "", end_fight.bind(false))
	else:
		add_choice("Flee", "Escape  %d%%" % flee_chance(), flee)


# Strength decides how hard you hit.
func strike():
	if randi_range(1, 100) <= strike_chance():
		hit_enemy(player.stats["Strength"] + randi_range(1, 6), "You strike")
	else:
		write("Your strike misses.", MUTED)
	enemy_turn()


# Martial Insight decides how much damage your Qi does.
func qi_burst():
	player.change({"Qi": -burst_cost()})
	hit_enemy(player.stats["Martial Insight"] * 2 + randi_range(1, 6), "Your Qi blasts")
	enemy_turn()


func guard():
	guarding = true
	player.change({"Qi": 5})
	write("You raise your guard and steady your breathing.", MUTED)
	enemy_turn()


func flee():
	if randi_range(1, 100) <= flee_chance():
		end_fight(false)
	else:
		write("You try to run, but %s cuts you off." % enemy["name"], MUTED)
		enemy_turn()


func hit_enemy(damage, verb):
	enemy["health"] = max(enemy["health"] - damage, 0)
	write("%s %s for %d." % [verb, enemy["name"], damage], GOOD)


func enemy_turn():
	if enemy["health"] <= 0:
		end_fight(true)
		return
	if randi_range(1, 100) <= enemy_hit_chance():
		var damage = enemy["damage"] + randi_range(1, 4)
		if guarding:
			damage = damage / 2
		player.change({"Health": -damage})
		write("%s hits you for %d." % [enemy["name"], damage], BAD)
	else:
		write("%s misses you." % enemy["name"], MUTED)
	guarding = false

	# A friendly duel stops before anyone gets killed.
	var friendly = fight_choice.get("friendly", false)
	if friendly and player.stats["Health"] <= 15:
		player.stats["Health"] = max(player.stats["Health"], 1)
		end_fight(false)
	elif player.stats["Health"] <= 0:
		end_fight(false)
	else:
		show_fight()


func end_fight(won):
	if won:
		write("You defeated %s!" % enemy["name"], GOLD)
	elif player.stats["Health"] > 0:
		write("You withdraw from the fight.", MUTED)
	else:
		write("%s strikes you down." % enemy["name"], BAD)
	enemy = null
	enemy_bar.hide()
	finish_choice(fight_choice, won)


# ---------------------------------------------------------------------------
# Drawing the screen
# ---------------------------------------------------------------------------

# Refresh the avatar, header, bars, stat chips and the faction line.
func refresh_screen():
	if player.age < 4:
		avatar.texture = avatar_baby
	elif player.age < 13:
		avatar.texture = avatar_child
	elif player.age < 20:
		avatar.texture = avatar_youth
	elif player.age < 50 + player.stage * 10:
		avatar.texture = avatar_adult
	else:
		avatar.texture = avatar_elder

	name_label.text = player.full_name
	date_label.text = "Age %d  ·  Year %d" % [player.age, player.year()]
	stage_label.text = player.stage_name()
	set_bar(health_bar, "Health", player.stats["Health"], player.max_health)
	set_bar(qi_bar, "Qi", player.stats["Qi"], player.qi_capacity)
	for stat in stat_values:
		stat_values[stat].text = str(player.stats[stat])
	world_label.text = "%s  ·  Karma %+d  ·  Reputation %d  ·  Merit %d  ·  Gold %d" % [
		player.sect if player.sect != "" else "No sect",
		player.stats["Karma"], player.stats["Reputation"], player.stats["Merit"], player.stats["Gold"]]

	if player.age < GROWN_UP_AGE:
		actions_label.text = "Too young to act on your own. Press + Age."
	else:
		actions_label.text = "Actions left this year: %d" % actions_left
	activities_button.disabled = actions_left <= 0
	sect_button.disabled = player.age < SECT_AGE


func set_bar(bar, title, value, max_value):
	bar.max_value = max_value
	bar.get_node("Text").text = "%s  %d / %d" % [title, value, max_value]
	var tween = create_tween()
	tween.tween_property(bar, "value", value, 0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Adds a line to the life log.
func write(text, color = TEXT):
	log_text.append_text("[color=%s]%s[/color]\n" % [color, text])


# Adds a small "AGE 12 · YEAR 1215" heading to the life log.
func write_header(title):
	write_title("%s  ·  YEAR %d" % [title, player.year()])


func write_title(title):
	log_text.append_text("\n[font_size=17][color=%s]%s[/color][/font_size]\n" % [GOLD, title])


func clear_choices():
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()


# Hides the bottom bar and gets the choice area ready for new buttons.
# Encounters and fights use 1 column; menus with many short buttons use 2.
func open_choices(columns):
	bottom_bar.hide()
	clear_choices()
	choices_box.columns = columns


# Adds a numbered button. "hint" is small text shown on the right side.
func add_choice(text, hint, action):
	var button = Button.new()
	button.text = "%d.  %s" % [choices_box.get_child_count() + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if choices_box.columns > 1:
		button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	choices_box.add_child(button)
	var label = Label.new()
	label.text = hint
	label.theme_type_variation = "HintLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_right = -16
	return button


# Greys out every button added so far when you have no actions left.
func disable_without_actions():
	if actions_left <= 0:
		for button in choices_box.get_children():
			button.disabled = true


func make_gold(button):
	button.theme_type_variation = "GoldButton"
	button.get_child(0).add_theme_color_override("font_color", Color(0.07, 0.08, 0.1))
