extends Control

# The main screen. Each month is one page: a framed picture, the story typed
# out underneath, then your choices.
#   scripts/player.gd      - your character: profile, cultivation, faction
#   scripts/sect.gd        - the sect you can found and manage
#   scripts/world_data.gd  - encounters, enemies, sects, talents and activities
#   scripts/my_scenarios.gd - the scenarios you write yourself, with templates
#   scripts/save_manager.gd - writes a life to a file and reads it back
#   scripts/life_data.gd   - backgrounds, talent growth and life paths (data)
#   scripts/life_manager.gd - the rules for those
#   scripts/requirements.gd - checks "needs" lists such as {"age": 13, "Smarts": 55}
#   scripts/npc_manager.gd - the people in your life: how they age, change and die
#   scripts/family_manager.gd - siblings, courtship, marriage and children
#   scripts/story_manager.gd - flags, stories in several stages, and the Journal
#   scripts/martial_manager.gd - martial techniques (the data is in martial_data.gd)
#   scripts/pack_import.gd - turns content_pack/events.json into scenarios
#   scripts/faction_manager.gd - your renown, and what each great sect thinks of you
#   scripts/legacy_manager.gd - the title and story at the end of a life, and heirs
#   scripts/chronicle_manager.gd - the Jianghu Chronicle, kept across all your lives
#   scripts/new_life.gd    - the screen where you shape your character
#   scripts/battle_stage.gd - the picture of a fight: the two fighters and their blows
#   assets/fighters/       - the pictures of you and your opponents in a fight
#   assets/scenes/         - the pictures shown at the top of a page
#   assets/ui/             - the small icons
const PlayerScript = preload("res://scripts/player.gd")
const SectScript = preload("res://scripts/sect.gd")
const World = preload("res://scripts/world_data.gd")
const Mine = preload("res://scripts/my_scenarios.gd")
const Saves = preload("res://scripts/save_manager.gd")
const Life = preload("res://scripts/life_data.gd")
const LifeManager = preload("res://scripts/life_manager.gd")
const Needs = preload("res://scripts/requirements.gd")
const NpcManager = preload("res://scripts/npc_manager.gd")
const FamilyManager = preload("res://scripts/family_manager.gd")
const FamilyData = preload("res://scripts/family_data.gd")
const CareerData = preload("res://scripts/career_data.gd")
const StoryManager = preload("res://scripts/story_manager.gd")
const MartialManager = preload("res://scripts/martial_manager.gd")
const Pack = preload("res://scripts/pack_import.gd")
const FactionManager = preload("res://scripts/faction_manager.gd")
const SectData = preload("res://scripts/sect_data.gd")
const LegacyManager = preload("res://scripts/legacy_manager.gd")
const ChronicleManager = preload("res://scripts/chronicle_manager.gd")
#   ui_pack/               - soft button sounds, the theme's colours and the portraits
#   scripts/game_theme.gd  - the look of the game, built on ui_pack/murim_theme.gd
const UiTheme = preload("res://ui_pack/murim_theme.gd")
const Portrait = preload("res://ui_pack/portrait.gd")
const Look = preload("res://scripts/game_theme.gd")

# --- Colours used in the text on the page ---
# These are the theme's colours (ui_pack/murim_theme.gd) written as text,
# which is what [color=...] in the story needs.
var TEXT = Look.hex(UiTheme.PAPER)
var GOOD = Look.hex(UiTheme.JADE)
var BAD = Look.hex(UiTheme.RED.lightened(0.3))   # the theme's red, lightened so it can be read as text
var GOLD = Look.hex(UiTheme.GOLD)
var MUTED = Look.hex(UiTheme.DIM)

# --- Rules you can tweak ---
const ACTIONS_PER_MONTH = 1  # activities / relationship / sect actions per month
const GROWN_UP_AGE = 6       # before this you are too small for the activities in More
const SECT_AGE = 10          # youngest age at which a sect will take you
const PATH_AGE = 13          # youngest age at which you can choose a life path
const PROFILE_PORTRAIT = 176 # how large your portrait is in the Profile (the pictures are 128 pixels, so larger looks soft)
const PERSON_PORTRAIT = 150  # how large someone else's portrait is on their page
const POPUP_HEIGHT = 0.7     # the tallest a pop-up's contents get, as a share of the screen, before they scroll
const DEVIATION_DAMAGE = 30  # Health lost when your Willpower reaches 0 and your Qi runs wild
const WILL_AFTER_DEVIATION = 20   # where your Willpower stands afterwards
const QI_BURST_COST = 15     # a Qi strike costs this much Qi per stage
const FOUND_SECT_COST = 100  # Gold needed to found your own sect...
const FOUND_SECT_STAGE = 2   # ...and the stage needed (2 = Second-Class)
const EXPEL_KARMA = -20      # Orthodox sects expel you below this Karma
const MAX_ROUNDS = 30        # a fight that lasts this long ends with no winner
const UNIQUE_CHANCE = 4      # % of months that bring a once-in-a-lifetime encounter
const ENCOUNTER_CHANCE = 25  # % of months that bring an ordinary encounter
const AGE_UP_CHANCE = 80     # % of "+ Age" birthdays that bring one (it skips eleven months of chances)
const NO_REPEAT = 5          # an encounter cannot come back until this many others have passed
const QUIET_MONTH = {"text": "A quiet month.", "image": "home"}   # when nothing else fits

# --- The words a scenario and a choice may use (see scripts/my_scenarios.gd) ---
const SCENARIO_WORDS = ["text", "image", "min_age", "max_age", "faction", "unique", "choices", "needs",
	"id", "title", "once", "repeat", "hidden", "weight"]
const CHOICE_WORDS = ["label", "stat", "difficulty", "percent", "fight", "friendly", "meet", "item",
	"win", "lose", "win_text", "lose_text", "talent_up", "needs", "mercy", "regard"]
const CHECK_STATS = ["Strength", "Agility", "Martial Insight", "Smarts", "Looks", "Happiness", "Willpower", "Reputation"]

# --- Fights (turn by turn) ---
const HEAVY_DAMAGE = 1.6     # your heavy blow hits this much harder...
const HEAVY_AIM = 25         # ...but is this much (in %) less likely to land
const FOE_HEAVY_DAMAGE = 1.7 # an opponent's heavy blow hits this much harder
const GUARD_BLOCK = 0.5      # a guard lets only this share of the damage through
const YOUNG_FIGHTER = 14     # younger than this, you are drawn smaller in a fight
# What an opponent may do in a turn, and how likely each is (out of 100).
const FOE_PLANS = {"strike": 60, "heavy": 20, "guard": 20}
const PLAN_TEXT = {
	"strike": "Next: %s will strike.",
	"heavy": "Next: %s will throw a heavy blow!",
	"guard": "Next: %s will guard.",
}
const MOVE_NAMES = {"strike": "strike", "heavy": "heavy blow", "qi": "Qi strike"}

# --- Fortune sticks, drawn once in a fight ---
# "edge" 0.2 means you hit 20% harder and are hurt 20% less in that fight.
# "weight" is how likely the stick is compared to the others.
const FORTUNES = [
	{"name": "Great fortune", "edge": 0.2, "weight": 10},
	{"name": "Good fortune", "edge": 0.1, "weight": 25},
	{"name": "Plain fortune", "edge": 0.0, "weight": 30},
	{"name": "Ill fortune", "edge": -0.1, "weight": 25},
	{"name": "Great misfortune", "edge": -0.2, "weight": 10},
]

# --- Settings (the gear button). They are remembered between games. ---
const SETTINGS_FILE = "user://settings.cfg"
const TEXT_SPEEDS = {"Slow": 70.0, "Normal": 160.0, "Fast": 400.0, "Instant": 0.0}
const FIGHT_SPEEDS = {"Slow": 0.6, "Normal": 0.35, "Fast": 0.12}
const SOUND_LEVELS = {"Off": 0.0, "Quiet": 0.35, "Normal": 1.0}
const MUSIC_SWITCH = {"On": 1.0, "Off": 0.0}
const MUSIC_LEVELS = {"Quiet": 0.25, "Normal": 0.5, "Loud": 1.0}
const BUTTON_SOUND_DB = -6.0 # how loud the button sounds are at "Normal", in decibels
# Choices with a sound of their own, by what is written on them. The sounds
# are tap, choice, confirm, back, page and reward (see ui_pack/ui_sounds.gd).
const CHOICE_SOUNDS = {"Back": "back", "Continue": "page", "Walk away": "back", "Be reborn": "confirm"}
var type_speed = 160.0       # letters per second (0 shows text at once)
var round_delay = 0.35       # seconds between the blows of a fight
var sound_volume = 1.0       # how loud the button sounds are (0 is off)
var music_on = true          # false switches the background music off
var music_volume = 0.5       # how loud the background music is

var player = PlayerScript.new()
var life = LifeManager.new(self)   # background, talent growth and life paths
var npcs = NpcManager.new(self)    # the people in your life
var family = FamilyManager.new(self)   # siblings, marriage and children
var stories = StoryManager.new(self)   # flags and stories in several stages
var martial = MartialManager.new(self) # martial techniques
var factions = FactionManager.new(self)   # your name in the jianghu, and what the sects think of you
var legacy = LegacyManager.new(self)   # the title and the story at the end of a life, and heirs
var chronicle = ChronicleManager.new(self)   # the record kept across all your lives
var mentions = {}            # which family members each scenario talks about (by scenario text)
var my_sect = null           # the sect you lead (null until you found one)
var rivals = World.RIVALS.duplicate(true)
var people = []
var actions_left = 0
var known_rank = 0
var recent = []              # the last few encounters, so they do not come straight back
var seen_unique = []         # once-in-a-lifetime encounters that already happened
var scenarios = []           # every encounter in the game: the built-in ones and your own
var my_scenarios = []        # the ones from my_scenarios.gd that have no mistakes
var mistakes = []            # what is wrong with the others, as sentences
var tested = 0               # how many of your scenarios test mode has shown so far
var menus_open = false       # false while an encounter or a fight needs an answer
var typing = null            # the animation that is typing out text (null when done)
var choice_buttons = []      # the choices on the page, in order (for the number keys)
var showing_menu = false     # true while the More menu (or one inside it) is open
var restarting = false       # true once "Be reborn", "New life" or "Load life" has been pressed
var alive = false            # true from the moment a life begins until it ends
var pending = null           # the scenario that is waiting for your answer (null when none is)
# Set by "New life" and "Be reborn", so the game opens on the New Life screen
# even though a saved life exists. It is "static" so that it survives the
# screen being started again.
static var skip_saved_life = false
# Set by "Live on as ...": what your child inherits (null otherwise).
static var heir_data = null
var fight_playing = false    # true while the blows of a turn are being shown
var page_image = ""          # the picture on the page right now ("" for none)

# --- The fight that is happening right now (null when not fighting) ---
var foe = null
var fight_choice = null
var fight_round = 0
var fight_edge = 0.0         # your bonus (or penalty) from the fortune stick
var stick_drawn = false      # a fortune stick can be drawn once in a fight
var foe_plan = "strike"      # what your opponent does this turn: a key of FOE_PLANS
var sure_blow = false        # true after you guard: your next blow cannot miss
var auto_fight = false       # true once you press Auto-fight
var used_moves = []          # the technique moves you have already used in this fight
var popup_scroll = ScrollContainer.new()   # what lets a long pop-up scroll

# --- Links to the nodes in your scene (each has "Access as Unique Name" on) ---
@onready var portrait = %Portrait
@onready var name_label = %NameLabel
@onready var stage_label = %StageLabel
@onready var date_label = %DateLabel
@onready var health_bar = %HealthBar
@onready var qi_bar = %QiBar
@onready var stats_box = %Stats
@onready var page = %Page
@onready var illustration = %Illustration
@onready var battle = %Battle
@onready var story = %Story
@onready var bars = %Bars
@onready var your_bar = %YourBar
@onready var enemy_bar = %EnemyBar
@onready var choices_box = %Choices
@onready var profile_button = %ProfileButton
@onready var age_button = %AgeButton
@onready var inventory_button = %InventoryButton
@onready var more_button = %MoreButton
@onready var popup = %Popup
@onready var popup_title = %PopupTitle
@onready var popup_body = %PopupBody
@onready var creation = %Creation
@onready var music = %Music

# One labelled chip for each of these, shown under the header. "Actions" is
# how many things you can still do this month.
var chip_stats = ["Strength", "Agility", "Martial Insight", "Gold", "Karma", "Reputation", "Merit", "Actions"]
var chip_labels = {}


func _ready():
	apply_look()
	for stat in chip_stats:
		var chip = PanelContainer.new()
		chip.theme_type_variation = "Chip"
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon = TextureRect.new()
		icon.texture = load("res://assets/ui/%s.svg" % stat.to_snake_case())
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(22, 22)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var label = Label.new()
		label.theme_type_variation = "ChipLabel"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(icon)
		row.add_child(label)
		chip.add_child(row)
		stats_box.add_child(chip)
		chip_labels[stat] = label

	# A pop-up with more in it than fits on the screen scrolls. Its body is
	# moved inside a scrolling box, which grows with it up to a limit.
	var card = popup_body.get_parent()
	popup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(popup_scroll)
	card.move_child(popup_scroll, popup_body.get_index())
	popup_body.reparent(popup_scroll)
	popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_body.minimum_size_changed.connect(fit_popup)

	%MenuButton.pressed.connect(show_menu)
	%SettingsButton.pressed.connect(show_settings)
	%PopupClose.pressed.connect(close_popup)
	profile_button.pressed.connect(show_profile)
	age_button.pressed.connect(age_up)
	inventory_button.pressed.connect(show_inventory)
	more_button.pressed.connect(show_more)
	# Every button makes a soft tap by itself (see ui_pack/ui_sounds.gd).
	# These two get a sound of their own.
	age_button.set_meta("ui_sound", "page")
	%PopupClose.set_meta("ui_sound", "back")
	# Keep the newest text in view whenever the page grows.
	page.get_v_scroll_bar().changed.connect(scroll_down)
	choices_box.resized.connect(scroll_down)

	load_settings()
	load_my_scenarios()
	apply_sound()
	refresh_screen()
	creation.begin.connect(start_life)
	creation.resume.connect(continue_life)
	# The game opens in your saved life if there is one. Otherwise it opens on
	# the New Life screen, which calls start_life().
	if heir_data != null:
		# A child carries on where a parent's life ended.
		var inherited = heir_data
		heir_data = null
		creation.hide()
		alive = true
		legacy.begin_as_heir(inherited)
		show_idle()
	elif skip_saved_life or not continue_life():
		creation.offer_saved_life(saved_life_name())
		creation.show_note(picture_note())
		creation.show()
	skip_saved_life = false


# Gives the screen its look: fonts, colours, and the shape of buttons and
# panels. The theme is put together in scripts/game_theme.gd, and every node
# on the screen (the New Life screen and the pop-ups too) takes it from here.
func apply_look():
	theme = Look.make()
	$Background.texture.gradient.colors = PackedColorArray([UiTheme.PANEL, UiTheme.INK])
	# Bars are red unless told otherwise. Qi, and your side in a fight, are jade.
	UiTheme.tint_bar(qi_bar, UiTheme.JADE)
	UiTheme.tint_bar(your_bar, UiTheme.JADE)


# Called by the New Life screen with the choices you made there.
func start_life(choices):
	creation.hide()
	alive = true
	player.setup(choices, World.TALENTS)
	new_page("shrine" if life.is_orphan() else "home")
	write_title("BORN  ·  YEAR %d" % player.year())
	life.be_born()
	# Notes for you while you build the game. Players of the finished game
	# never see them.
	if OS.is_debug_build():
		if picture_note() != "":
			write(picture_note(), BAD)
		for mistake in mistakes:
			write(mistake, BAD)
		if testing():
			write("Test mode is on: only your own scenarios appear. Set TEST_MY_SCENARIOS back to false in my_scenarios.gd when you are done.", BAD)
	# Your first choice comes with your first breath.
	show_encounter(life.birth_scenario())


# A click or a key press while text is still being typed shows it all at once.
func _input(event):
	if popup.visible or creation.visible:
		return
	var pressed = (event is InputEventMouseButton or event is InputEventKey) and event.pressed
	if pressed and typing != null:
		finish_typing()
		get_viewport().set_input_as_handled()


# Number keys 1-9 press the matching choice.
func _unhandled_key_input(event):
	if not event.pressed or event.echo or popup.visible or creation.visible:
		return
	var index = event.keycode - KEY_1
	if index >= 0 and index < choice_buttons.size() and not choice_buttons[index].disabled:
		choice_buttons[index].pressed.emit()


# ---------------------------------------------------------------------------
# Time: "Continue" passes a month, "+ Age" jumps to your next birthday
# ---------------------------------------------------------------------------

# Continue: one month passes.
func next_month():
	start_month(player.next_month(), false)


# + Age: the rest of the year passes quietly and your next birthday arrives.
func age_up():
	player.month = 12
	start_month(player.next_month(), true)


# Starts a new month and plays its event. "birthday" is true when the month
# is also the start of a new year.
func start_month(birthday, skipped):
	actions_left = ACTIONS_PER_MONTH if player.age >= GROWN_UP_AGE else 0
	if birthday and player.age >= player.lifespan:
		new_page("")
		write_title(page_title())
		die("You passed away peacefully of old age.")
		return

	var event = pick_event(birthday, skipped)
	new_page(event.get("image", ""))
	write_title(page_title())
	if skipped:
		write("The rest of the year passes quietly.", MUTED)
	if birthday:
		npcs.yearly()
		family.yearly()
		player.change({"Health": 5})
		yearly_upkeep()

	if event.has("choices"):
		show_encounter(event)
	else:
		write(event["text"])
		write_changes(event.get("win", {}))
		end_turn()


func page_title():
	return "AGE %d  ·  MONTH %d  ·  YEAR %d" % [player.age, player.month, player.year()]


# Decides what happens this month: a once-in-a-lifetime encounter, an
# ordinary encounter with choices, or a small happening with none.
# "skipped" is true when "+ Age" jumped here over the rest of the year.
func pick_event(birthday, skipped = false):
	if testing():
		# Your own scenarios, one after another.
		tested += 1
		return my_scenarios[(tested - 1) % my_scenarios.size()]
	# Each of your first birthdays brings its own milestone.
	var milestones = life.milestones()
	if birthday and player.age <= milestones.size():
		return milestones[player.age - 1]
	# Someone in your life may come looking for you.
	var visit = npcs.special_event()
	if visit == null:
		visit = factions.special_event()
	if visit != null:
		return visit

	var roll = randi_range(1, 100)
	if roll <= UNIQUE_CHANCE:
		# A talent that is ready to awaken comes before any other rare event.
		var unique = life.awakening_scenario()
		if unique != null:
			return unique
		unique = pick_from(scenarios, true)
		if unique != null:
			seen_unique.append(unique)
			return unique
	var chance = UNIQUE_CHANCE + ENCOUNTER_CHANCE + life.wander_bonus()
	if skipped:
		# A whole year went by, so something worth deciding usually happened.
		chance = max(chance, AGE_UP_CHANCE)
	if roll <= chance:
		var encounter = pick_from(scenarios, false)
		if encounter != null:
			recent.append(encounter)
			if recent.size() > NO_REPEAT:
				recent.pop_front()
			return encounter
	var happening = pick_from(World.HAPPENINGS, false)
	return happening if happening != null else QUIET_MONTH


# Picks a random entry that fits your age. "unique" chooses between the
# once-in-a-lifetime entries and the ordinary ones.
func pick_from(list, unique):
	var options = []
	for entry in list:
		if entry.get("unique", false) != unique or entry in seen_unique:
			continue
		# A "hidden" scenario is only reached from another one, through "goto".
		if entry.get("hidden", false):
			continue
		if player.age < entry.get("min_age", GROWN_UP_AGE) or player.age > entry.get("max_age", 999):
			continue
		# "once" scenarios never come back; "repeat" ones may come straight back.
		if entry.get("once", false) and player.done.has(entry.get("id", "")):
			continue
		if entry in recent and not entry.get("repeat", false):
			continue
		if entry.has("faction") and entry["faction"] != player.faction:
			continue
		if entry.has("needs") and not Needs.meets(self, entry["needs"]):
			continue
		if not family_present(entry):
			continue
		options.append(entry)
	if options.is_empty():
		return null
	# A scenario with "weight": 4 is four times as likely as one without.
	var total = 0
	for entry in options:
		total += entry.get("weight", 1)
	var roll = randi_range(1, total)
	for entry in options:
		roll -= entry.get("weight", 1)
		if roll <= 0:
			return entry
	return options[-1]


# A scenario that talks about your mother or father is left out when that
# person is not in your life (an orphan, or after they have died).
func family_present(entry):
	if not mentions.has(entry["text"]):
		mentions[entry["text"]] = family_mentioned(entry)
	for role in mentions[entry["text"]]:
		if not has_person(role):
			return false
	return true


# Works out which family members a scenario talks about, from its words and
# from the bonds it changes.
func family_mentioned(entry):
	var words = entry["text"]
	for choice in entry.get("choices", []):
		words += " " + choice.get("label", "") + " " + choice.get("win_text", "") + " " + choice.get("lose_text", "")
		words += " " + " ".join(choice.get("win", {}).keys()) + " " + " ".join(choice.get("lose", {}).keys())
	var roles = []
	# A name in curly brackets, such as {Sibling}, needs that person.
	for role in World.ROLES:
		if words.contains("{%s}" % role):
			roles.append(role)
	# So do the words "your mother", "your father" and "your parents", and a
	# reward that changes the bond with one of them.
	var rewards = ""
	for choice in entry.get("choices", []):
		rewards += " ".join(choice.get("win", {}).keys()) + " " + " ".join(choice.get("lose", {}).keys()) + " "
	words = words.to_lower()
	if words.contains("your mother") or words.contains("your parents") or rewards.contains("Mother"):
		roles.append("Mother")
	if words.contains("your father") or words.contains("your parents") or rewards.contains("Father"):
		roles.append("Father")
	if words.contains("the caretaker") or rewards.contains("Caretaker"):
		roles.append("Caretaker")
	return roles


# Income, stipends and consequences that arrive once a year.
func yearly_upkeep():
	life.yearly()
	martial.yearly()
	stories.yearly()
	chronicle.yearly()
	if my_sect != null:
		write("%s: %d disciples train under you." % [my_sect.sect_name, my_sect.disciples], MUTED)
		write_changes({"Gold": my_sect.yearly_income(), "Health": my_sect.yearly_healing()})
		if player.faction == "Orthodox" and player.stats["Karma"] < EXPEL_KARMA:
			player.faction = "Unorthodox"
			write("Word of your deeds spreads. The Alliance brands the %s unorthodox." % my_sect.sect_name, BAD)
	elif player.sect != "":
		if player.faction == "Orthodox" and player.stats["Karma"] < EXPEL_KARMA:
			write("The elders of %s strike your name from the rolls for your misdeeds." % player.sect, BAD)
			factions.change(player.sect, factions.WAR_REGARD)
			player.remember("was expelled from %s." % player.sect)
			player.faction = ""
			player.sect = ""
		else:
			write("%s pays your stipend." % player.sect, MUTED)
			write_changes({"Gold": World.STIPENDS[player.rank()]})


func show_encounter(encounter):
	if encounter.has("title"):
		write_heading(encounter["title"])
	write(fill(encounter["text"]))
	if encounter.get("once", false):
		player.done[encounter.get("id", "")] = true
	menus_open = false
	refresh_screen()
	clear_choices()
	for choice in encounter["choices"]:
		# A choice can ask for something: Gold, a technique, a stat. If you
		# lack it the choice is greyed out and says why. A choice that hangs
		# on the story (a flag) is not shown at all until its time comes.
		var blocked = Needs.missing(self, choice.get("needs", {}))
		if blocked == Needs.HIDDEN:
			continue
		var button = add_choice(fill(choice_label(choice)), blocked if blocked != "" else hint_for(choice), choose.bind(choice))
		button.disabled = blocked != ""
		button.set_meta("ui_sound", "choice")
	var open = false
	for button in choice_buttons:
		open = open or not button.disabled
	if not open:
		add_choice("Walk away", "", end_turn)
	# Saved together with the scenario, so that leaving the game now and
	# coming back shows the same scenario again.
	pending = encounter
	save_life()


# The end of a page: continue to the next month, or use the buttons below.
func show_idle():
	foe = null
	pending = null
	bars.hide()
	menus_open = true
	refresh_screen()
	clear_choices()
	if player.month == 12:
		add_choice("Continue", "On to your next birthday", next_month)
	else:
		add_choice("Continue", "On to month %d" % (player.month + 1), next_month)
	save_life()


func end_turn():
	if player.stats["Health"] <= 0:
		die("Your injuries were too great. Your life has ended.")
		return
	if player.stats["Willpower"] <= 0:
		qi_deviation()
		if player.stats["Health"] <= 0:
			die("Your own Qi tore you apart from within.")
			return
	check_rank()
	show_idle()


# A will worn down to nothing cannot hold your Qi on its path. It is a
# serious setback, not the end: you lose Qi and Health, and your will finds
# its feet again.
func qi_deviation():
	write("Your will gives way, and your Qi runs wild through your meridians.", BAD)
	player.stats["Qi"] = player.stats["Qi"] / 2
	player.stats["Willpower"] = WILL_AFTER_DEVIATION
	write_changes({"Health": -DEVIATION_DAMAGE, "Happiness": -10})
	write("Half of your Qi is lost. It will be a long road back.", BAD)


func die(reason):
	write(reason, BAD)
	# The title this life earned and the story told about it, which also go
	# into the Chronicle.
	chronicle.record_life(legacy.write_epilogue())
	foe = null
	bars.hide()
	menus_open = false
	refresh_screen()
	portrait.modulate = Color(0.5, 0.5, 0.5)
	clear_choices()
	var heir = legacy.heir()
	if heir != null:
		add_choice("Live on as %s" % heir["name"], "Your %s, age %d, inherits a part of what you built" %
			[family.son_or_daughter(heir), heir["age"]], continue_as_heir.bind(heir))
	add_choice("Be reborn", "Start a new life", restart)
	# A life that has ended cannot be loaded again.
	alive = false
	pending = null
	Saves.delete_life()


# "New life" and "Be reborn": goes back to the New Life screen.
func restart():
	reload(true)


# "Live on as ...": the next life is your child's, with a part of what you
# had. What is passed on waits in heir_data while the screen starts again.
func continue_as_heir(child):
	heir_data = legacy.inheritance(child)
	reload(true)


# "Load life": goes back to your last save.
func load_saved():
	reload(false)


# Starts the whole screen again. The short wait lets the click be heard
# before the screen is replaced.
func reload(new_life):
	if restarting:
		return
	restarting = true
	skip_saved_life = new_life
	await get_tree().create_timer(0.12).timeout
	get_tree().reload_current_scene()


# ---------------------------------------------------------------------------
# Saving and loading (the file itself is handled by scripts/save_manager.gd)
# ---------------------------------------------------------------------------

# A life can be saved while you are alive and not in the middle of a fight.
func can_save():
	return alive and foe == null and not restarting


# Writes the life to the save file. The game calls this by itself at the end
# of every month and whenever a scenario begins.
func save_life():
	if can_save():
		Saves.save_life(life_data())


# Everything about this life that must be remembered, as plain data. When a
# new system needs remembering, add it here and in load_life_data().
# Scenarios are remembered by their text, which is what tells them apart.
func life_data():
	return {
		"version": Saves.VERSION,
		"player": player.to_data(),
		"sect": my_sect.to_data() if my_sect != null else null,
		"people": people,
		"rivals": rivals,
		"actions_left": actions_left,
		"known_rank": known_rank,
		"recent": texts_of(recent),
		"seen_unique": texts_of(seen_unique),
		"pending": pending["text"] if pending != null else "",
		"pending_id": pending.get("id", "") if pending != null else "",
	}


# Puts a saved life back. Anything the save does not mention keeps its
# starting value, so older saves still load after the game has grown.
func load_life_data(data):
	player = PlayerScript.new()
	player.from_data(data["player"], World.TALENTS)
	my_sect = null
	if data.get("sect") is Dictionary:
		my_sect = SectScript.new()
		my_sect.from_data(data["sect"])
	people = []
	for person in data.get("people", []):
		if person is Dictionary and World.ROLES.has(person.get("role", "")):
			people.append(npcs.upgrade(person))
	rivals = data.get("rivals", World.RIVALS.duplicate(true))
	actions_left = data.get("actions_left", 0)
	known_rank = data.get("known_rank", 0)
	recent = scenarios_called(data.get("recent", []))
	seen_unique = scenarios_called(data.get("seen_unique", []))
	pending = find_scenario(data.get("pending", ""))
	# A rival's challenge is about one person, so it is built again here.
	var waiting = data.get("pending_id", "")
	if pending == null and waiting == "rival_duel" and npcs.has("Rival"):
		pending = npcs.duel_scenario(npcs.first("Rival"))
	if pending == null and waiting == "enemy_ambush" and npcs.has("Enemy"):
		pending = npcs.ambush_scenario(npcs.first("Enemy"))
	if pending == null and waiting == "sect_hunt":
		for sect in World.SECTS:
			if pending == null and factions.regard(sect) <= factions.HUNTED:
				pending = factions.hunt_scenario(sect)
	# Leave out what the game no longer has, such as an item or a sect that
	# was removed from world_data.gd after the save was made.
	for item in player.items.keys():
		if not World.ITEMS.has(item):
			player.items.erase(item)
	if my_sect == null and not World.SECTS.has(player.sect):
		player.sect = ""
		player.faction = ""
	if not Life.BACKGROUNDS.has(player.background):
		player.background = "Poor Village"
	if not Life.LIFE_PATHS.has(player.path):
		player.path = ""
		player.path_rank = 0
	for property in player.properties.duplicate():
		if not Life.PROPERTIES.has(property):
			player.properties.erase(property)


# Opens the saved life on the page. Returns false if there is none.
func continue_life():
	var data = Saves.load_life()
	if data == null:
		return false
	load_life_data(data)
	creation.hide()
	alive = true
	var waiting = pending
	new_page(waiting.get("image", "home") if waiting != null else "home")
	write_title(page_title())
	if picture_note() != "":
		write(picture_note(), BAD)
	if waiting != null:
		show_encounter(waiting)
	else:
		write("Your life goes on where you left it.", MUTED)
		show_idle()
	return true


# Who the saved life belongs to, such as "Baek Mu-jin, age 18" ("" if
# nothing is saved). Shown on the New Life screen.
func saved_life_name():
	var data = Saves.load_life()
	if data == null:
		return ""
	return "%s, age %d" % [data["player"].get("full_name", "your saved life"), data["player"].get("age", 0)]


func texts_of(list):
	var texts = []
	for scenario in list:
		texts.append(scenario["text"])
	return texts


func scenarios_called(texts):
	var found = []
	for text in texts:
		var scenario = find_scenario(text)
		if scenario != null:
			found.append(scenario)
	return found


# Finds a scenario by its text. Returns null if the game no longer has it.
func find_scenario(text):
	var everything = [World.BIRTH, Life.ORPHAN_BIRTH] + World.CHILDHOOD + Life.ORPHAN_CHILDHOOD \
		+ Life.TALENT_SCENARIOS.values() + scenarios + stories.by_id.values()
	for scenario in everything:
		if scenario["text"] == text:
			return scenario
	return null


# ---------------------------------------------------------------------------
# Choices and dice
# ---------------------------------------------------------------------------

# Chance (in %) that a choice succeeds.
func chance(choice):
	if choice.has("percent"):
		# Pure luck, which some talents improve.
		return clamp(choice["percent"] + player.talent_info.get("luck", 0), 0, 100)
	if choice.has("train"):
		var bonus = choice.get("bonus", 0) + training_bonus(choice["train"])
		return player.train_chance(choice["train"], bonus)
	if choice.has("stat"):
		return player.check_chance(choice["stat"], choice["difficulty"])
	return 100


# Extra training chance from your sect, your talent, your life path and
# your Smarts.
func training_bonus(stat):
	var bonus = life.train_bonus(stat) + player.talent_info.get("train_all", 0)
	if my_sect != null:
		if stat == "Martial Insight":
			bonus += my_sect.levels["Scripture Library"] * 10
		else:
			bonus += my_sect.levels["Training Hall"] * 10
	elif player.sect != "" and World.SECTS[player.sect]["trains"] == stat:
		bonus += 15
	if player.talent_info.get("train", "") == stat:
		bonus += player.talent_info["train_bonus"]
	if stat == "Martial Insight":
		# A sharp mind learns faster: Smarts 90 gives +10, Smarts 10 gives -10.
		bonus += (player.stats["Smarts"] - 50) / 4
	return bonus


# How much faster bonds grow: your talent, and a little from your Looks.
func bond_bonus():
	return player.talent_info.get("bond_bonus", 0) + player.stats["Looks"] / 25 + int(martial.bonus("bond"))


# The words on a choice's button. A choice that needs a technique names it
# in front: "[Qi Sense] Examine the pill first".
func choice_label(choice):
	var techniques = choice.get("needs", {}).get("technique", [])
	if techniques.is_empty():
		return choice["label"]
	return "[%s] %s" % [martial.title(techniques[0]), choice["label"]]


# The small line under a choice: which stat it tests and how hard it is.
func hint_for(choice):
	if choice.has("fight"):
		var friendly = choice.get("friendly", false)
		var kind = "Duel" if friendly else "Fight"
		if choice["fight"] is String and choice["fight"] == "random":
			return kind
		var stops_early = friendly or choice.get("mercy", false)
		return "%s  ·  %s" % [kind, difficulty_word(win_chance(make_enemy(choice["fight"]), stops_early))]
	if choice.has("stat"):
		return "%s  ·  %s" % [choice["stat"], difficulty_word(chance(choice))]
	if choice.has("percent"):
		return "Luck  ·  %s" % difficulty_word(chance(choice))
	if choice.has("train"):
		return difficulty_word(chance(choice))
	return ""


# A chance in words, so the player reads "Difficult" and not "43%".
func difficulty_word(percent):
	if percent >= 80:
		return "Easy"
	if percent >= 60:
		return "Moderate"
	if percent >= 40:
		return "Difficult"
	if percent >= 20:
		return "Very difficult"
	return "Nearly impossible"


func choose(choice):
	if choice.has("fight"):
		start_fight(choice)
	else:
		finish_choice(choice, randi_range(1, 100) <= chance(choice))


# Hands out the "win" or "lose" rewards of a choice and writes what happened.
func finish_choice(choice, success):
	var result = (choice.get("win", {}) if success else choice.get("lose", {})).duplicate()
	if choice.has("fight"):
		# Winning lifts your spirits; losing stings.
		result["Happiness"] = result.get("Happiness", 0) + (3 if success else -5)
		if success and not choice.get("friendly", false) and player.faction == "Unorthodox":
			# The Demonic Cult rewards every victory.
			result["Merit"] = result.get("Merit", 0) + 3

	if chance(choice) < 100:
		write("Success!" if success else "You failed...", GOOD if success else BAD)
	# A choice can tell in its own words how it turned out.
	var ending = choice.get("win_text" if success else "lose_text", "")
	if ending != "":
		write(fill(ending))
	write_changes(result)
	if choice.has("person") and (success or choice.has("fight")):
		var person = choice["person"]
		var gained = max(choice["bond"] + bond_bonus() + npcs.warmth(person), 1)
		person["bond"] = min(person["bond"] + gained, 100)
		write("Bond with %s +%d" % [person["name"], gained], GOOD)
		player.count("bonds")
		if choice.has("fight"):
			npcs.after_duel(person, success)

	# Keep count of what you do; talents grow from it.
	if choice.has("train"):
		player.count("trained")
	if choice.has("percent") and success:
		player.count("lucky")
	if choice.has("fight"):
		player.count("fights_won" if success else "fights_lost")
	if success and choice.get("talent_up", false):
		life.grow_talent()

	if success and choice.has("item"):
		player.add_item(choice["item"])
		write("You obtain: %s. It is in your inventory." % choice["item"], GOLD)
	if success and choice.has("meet"):
		meet(choice["meet"])
	if choice.has("join"):
		if success:
			join_sect(choice["join"])
		else:
			write("%s turns you away. Come back when you are stronger." % choice["join"], MUTED)

	# A few choices come from one particular sect or person (see
	# faction_manager.gd and npc_manager.gd).
	if success and choice.has("regard"):
		factions.change(choice["regard"][0], choice["regard"][1])
	if success and choice.has("slay"):
		npcs.slay(choice["slay"])
	if success and choice.has("peace"):
		npcs.make_peace(choice["peace"])

	# What the outcome does beyond the numbers: flags, techniques, and
	# whether the story carries on or ends here.
	stories.apply(result)
	if result.get("die", false):
		die("Your story ends here.")
	elif result.has("goto") and player.stats["Health"] > 0 and stories.by_id.has(result["goto"]):
		continue_story(stories.by_id[result["goto"]])
	else:
		end_turn()


# The story carries straight on in another scenario: one press of Continue,
# and it opens on a fresh page in the same month.
func continue_story(next):
	foe = null
	bars.hide()
	pending = next   # leaving the game now brings you back to the next part
	clear_choices()
	add_choice("Continue", "The story goes on", open_scenario.bind(next))
	save_life()


func open_scenario(scenario):
	new_page(scenario.get("image", page_image))
	write_title(page_title())
	show_encounter(scenario)


# Turns {"Qi": 30, "Health": -20} into "Qi +30, Health -20".
func describe(changes):
	var parts = []
	for stat in changes:
		parts.append("%s %+d" % [stat, changes[stat]])
	return ", ".join(parts)


# Changes the player's numbers and writes what really changed on one line,
# gains in green and losses in red: "Qi +30  ·  Health -20".
func write_changes(changes):
	var text = change_text(changes)
	if text != "":
		write(text, MUTED)


# Changes the player's numbers and returns what really changed as coloured
# text. A role such as "Mother" changes your bond with that person instead.
func change_text(changes):
	var before = player.stats.duplicate()
	var capacity = player.qi_capacity
	var numbers = {}
	var max_health = player.max_health
	for stat in changes:
		# Roles are bonds with people, and a few words are not numbers at
		# all ("flag", "goto"...); story_manager.gd deals with those.
		if not World.ROLES.has(stat) and stat not in stories.SPECIAL and stat not in SectScript.STATS:
			numbers[stat] = changes[stat]
	player.change(numbers)
	var parts = []
	for stat in numbers:
		var difference = player.stats.get(stat, 0) - before.get(stat, 0)
		if stat == "Qi Capacity":
			difference = player.qi_capacity - capacity
		if stat == "Max Health":
			difference = player.max_health - max_health
		if difference != 0:
			parts.append("[color=%s]%s %+d[/color]" % [GOOD if difference > 0 else BAD, stat, difference])
	# "Disciples", "Elders" and "Sect Fame" change the sect you lead.
	for stat in changes:
		if stat in SectScript.STATS and my_sect != null:
			var difference = my_sect.change(stat, changes[stat])
			if difference != 0:
				parts.append("[color=%s]%s %+d[/color]" % [GOOD if difference > 0 else BAD, stat, difference])
	for role in changes:
		# Of several people with the same role, the one closest to you is meant.
		var person = npcs.first(role) if World.ROLES.has(role) else null
		if person != null:
			var bond = clamp(person["bond"] + changes[role], 0, 100)
			var difference = bond - person["bond"]
			person["bond"] = bond
			if difference != 0:
				parts.append("[color=%s]Bond with %s %+d[/color]" % [GOOD if difference > 0 else BAD, person["name"], difference])
	return "  ·  ".join(parts)


# ---------------------------------------------------------------------------
# Your own scenarios (scripts/my_scenarios.gd)
# ---------------------------------------------------------------------------

# Adds the scenarios from my_scenarios.gd to the game. One with a mistake in
# it is left out, and the mistake is shown on the first page of a new life.
func load_my_scenarios():
	scenarios = World.ENCOUNTERS + Life.ORPHAN_SCENARIOS + FamilyData.SCENARIOS + CareerData.SCENARIOS \
		+ SectData.SCENARIOS
	# The ready-made events in content_pack/events.json.
	var pack = Pack.load_events()
	# Every scenario with an "id" is written down first, yours included, so
	# that a "goto" can be checked against them.
	stories.register(scenarios + pack)
	for scenario in Mine.SCENARIOS:
		if scenario is Dictionary:
			stories.register([scenario])
	for i in Mine.SCENARIOS.size():
		var scenario = Mine.SCENARIOS[i]
		var found = find_mistakes(scenario)
		if found.is_empty():
			my_scenarios.append(scenario)
		elif scenario is Dictionary:
			# A scenario with a mistake is left out, so nothing may lead to it.
			stories.by_id.erase(scenario.get("id", ""))
		# Name the scenario by its number in the list and its first few words.
		var title = "Scenario %d" % (i + 1)
		if scenario is Dictionary and scenario.get("text") is String:
			title += " (\"%s...\")" % scenario["text"].left(24)
		for mistake in found:
			mistakes.append("my_scenarios.gd  ·  %s: %s" % [title, mistake])
			push_warning(mistakes[-1])
	scenarios += my_scenarios
	# Scenarios marked "hidden" are only reached from another scenario,
	# through "goto", so they stay out of the pool.
	for scenario in pack:
		if not scenario.get("hidden", false):
			scenarios.append(scenario)


# True while TEST_MY_SCENARIOS is switched on in my_scenarios.gd. It only
# works while you run the game from Godot, never in the finished game.
func testing():
	return Mine.TEST_MY_SCENARIOS and OS.is_debug_build() and not my_scenarios.is_empty()


# Returns what is wrong with a scenario as a list of sentences. An empty list
# means it is fine.
func find_mistakes(scenario):
	if not scenario is Dictionary:
		return ["it must be written between { and }."]
	var found = []
	for word in scenario:
		if word not in SCENARIO_WORDS:
			found.append("\"%s\" is not a word a scenario can use." % word)
	if not scenario.get("text") is String or scenario["text"] == "":
		found.append("it needs a \"text\".")
	var image = scenario.get("image", "home")
	if not image is String or not ResourceLoader.exists("res://assets/scenes/%s.svg" % image):
		found.append("there is no picture called \"%s\"." % image)
	if scenario.has("faction") and not World.FACTIONS.has(scenario["faction"]):
		found.append("\"faction\" must be \"Orthodox\" or \"Unorthodox\".")
	for word in ["min_age", "max_age"]:
		if scenario.has(word) and not scenario[word] is int:
			found.append("\"%s\" must be a whole number." % word)
	if scenario.has("unique") and not scenario["unique"] is bool:
		found.append("\"unique\" must be true or false, without quotes.")
	if scenario.has("needs"):
		found += Needs.mistakes(player, scenario["needs"])
	var choices = scenario.get("choices")
	if not choices is Array or choices.is_empty():
		found.append("it needs \"choices\".")
		return found
	for i in choices.size():
		for mistake in find_choice_mistakes(choices[i]):
			found.append("choice %d: %s" % [i + 1, mistake])
	return found


func find_choice_mistakes(choice):
	if not choice is Dictionary:
		return ["it must be written between { and }."]
	var found = []
	for word in choice:
		if word not in CHOICE_WORDS:
			found.append("\"%s\" is not a word a choice can use." % word)
	if not choice.get("label") is String or choice["label"] == "":
		found.append("it needs a \"label\".")
	if choice.has("stat"):
		if choice["stat"] not in CHECK_STATS:
			found.append("\"stat\" must be one of: %s." % ", ".join(CHECK_STATS))
		if not choice.get("difficulty") is int:
			found.append("a choice with \"stat\" also needs a \"difficulty\" number.")
	if choice.has("percent") and not choice["percent"] is int:
		found.append("\"percent\" must be a whole number from 0 to 100.")
	if choice.has("fight") and choice["fight"] is String and choice["fight"] != "random" \
			and not World.ENEMIES.has(choice["fight"]):
		found.append("there is no enemy called \"%s\"." % choice["fight"])
	if choice.has("friendly") and not choice["friendly"] is bool:
		found.append("\"friendly\" must be true or false, without quotes.")
	if choice.has("meet") and not World.ROLES.has(choice["meet"]):
		found.append("\"meet\" must be Friend, Rival or Master.")
	if choice.has("item") and not World.ITEMS.has(choice["item"]):
		found.append("there is no item called \"%s\"." % choice["item"])
	for word in ["win", "lose"]:
		var changes = choice.get(word, {})
		if not changes is Dictionary:
			found.append("\"%s\" must be written between { and }." % word)
			continue
		for stat in changes:
			if stat in stories.SPECIAL:
				continue   # "flag", "goto" and the like are checked below
			if not player.stats.has(stat) and stat not in ["Qi Capacity", "Max Health"] and not World.ROLES.has(stat) \
					and stat not in SectScript.STATS:
				found.append("\"%s\" in \"%s\" is not something that can change." % [stat, word])
			elif not changes[stat] is int:
				found.append("%s in \"%s\" must be a whole number." % [stat, word])
		found += stories.mistakes(changes, word)
	for word in ["win_text", "lose_text"]:
		if choice.has(word) and not choice[word] is String:
			found.append("\"%s\" must be a sentence in quotes." % word)
	if choice.has("needs"):
		found += Needs.mistakes(player, choice["needs"])
	return found


# ---------------------------------------------------------------------------
# The More menu: activities, cultivation, relationships and your sect
# ---------------------------------------------------------------------------

# More is sorted into a few groups, so the list stays short as the game
# grows. What each group holds is decided in show_group() below, and by the
# "menu" of each activity in world_data.gd.
const MORE_GROUPS = {
	"Life": "Rest, work, study and your path in life",
	"Martial": "Cultivate, train and practise your techniques",
	"Jianghu": "Go out into the world and see what happens",
	"People": "Family, friends, masters, rivals and your sect",
	"Money": "The market and your property",
}


func show_more():
	open_menu("What would you like to do?  ·  actions left this month: %d" % actions_left)
	if player.can_break_through():
		var button = add_choice("Attempt a breakthrough", difficulty_word(player.breakthrough_chance()), breakthrough)
		button.add_theme_color_override("font_color", Color(GOLD))
		button.disabled = actions_left <= 0
	for group in MORE_GROUPS:
		# Small children have nothing to do in the world of martial arts and money.
		if player.age < GROWN_UP_AGE and group not in ["Life", "People"]:
			continue
		add_choice(group, MORE_GROUPS[group], show_group.bind(group))
	add_choice("Back", "", show_idle)


# One group of More. Activities need an action; opening a menu to look at
# it does not.
func show_group(group):
	open_menu("%s  ·  actions left this month: %d" % [group, actions_left])
	for activity in World.ACTIVITIES:
		if activity.get("menu", "Life") == group and player.age >= activity.get("min_age", GROWN_UP_AGE):
			add_activity(activity)
	disable_without_actions()
	if group == "Life":
		if player.age >= PATH_AGE:
			var walking = "%s (%s)" % [player.path, life.rank_name()] if player.path != "" else "Choose what to make of your life"
			add_choice("Life path", walking, life.show_paths)
		if player.age < GROWN_UP_AGE:
			add_caption("You are too small to do much yet. Your days are decided for you.")
	elif group == "Martial":
		add_choice("Martial arts", "%d techniques known" % player.techniques.size(), martial.show_techniques)
	elif group == "People":
		add_choice("Relationships", "%d people in your life" % npcs.alive().size(), show_people)
		if family.can_visit_matchmaker():
			var matchmaker = add_choice("Visit the matchmaker", "Costs %d gold  ·  she introduces you to someone" % family.MATCHMAKER_COST, family.visit_matchmaker)
			matchmaker.disabled = actions_left <= 0 or player.stats["Gold"] < family.MATCHMAKER_COST
		if player.age < SECT_AGE:
			add_choice("Sect", "No sect takes disciples younger than %d" % SECT_AGE, show_sect).disabled = true
		elif player.sect == "":
			add_choice("Sect", "Join a sect, or found your own", show_sect)
		else:
			add_choice("Sect", player.sect, show_sect)
	elif group == "Money":
		add_choice("Market", "Buy pills, wine, robes and manuals", show_market)
		if player.age >= Life.LIVING_AGE:
			add_choice("Property", "Houses, stalls and land", life.show_property)
	add_choice("Back", "", show_more)


# "Seek adventure": you go looking for trouble, and this month it finds you.
func seek_adventure():
	actions_left -= 1
	var encounter = pick_from(scenarios, false)
	if encounter == null:
		write("You walk the roads for a month and nothing happens. Even the bandits are busy elsewhere.", MUTED)
		end_turn()
		return
	recent.append(encounter)
	if recent.size() > NO_REPEAT:
		recent.pop_front()
	new_page(encounter.get("image", ""))
	write_title(page_title())
	write("You go looking for trouble.", MUTED)
	show_encounter(encounter)


# Adds one activity to the menu, with its chance or its reward underneath.
func add_activity(activity):
	if activity.has("cultivate"):
		add_choice(activity["label"], "Qi +%d" % player.cultivation_gain(library_bonus()), cultivate)
		return
	if activity.has("work"):
		add_choice(activity["label"], "Gold +%d" % life.work_pay(), life.work)
		return
	if activity.has("adventure"):
		add_choice(activity["label"], "Something will happen to you this month", seek_adventure)
		return
	var hint = hint_for(activity)
	if hint == "":
		hint = describe(activity["win"])
	add_choice(activity["label"], hint, do_action.bind(activity))


# The Market, opened from More. Buying costs Gold but no action.
func show_market():
	open_menu("Market  ·  you have %d gold" % player.stats["Gold"])
	for item in World.ITEMS:
		var info = World.ITEMS[item]
		var button = add_choice(item, "Costs %d gold  ·  %s" % [price_of(item), info["text"]], buy.bind(item))
		button.disabled = player.stats["Gold"] < price_of(item)
		button.set_meta("ui_sound", "confirm")
	add_choice("Back", "", show_group.bind("Money"))


# What the Market charges you. Some talents talk the price down.
func price_of(item):
	return max(int(World.ITEMS[item]["price"] * (1.0 - player.talent_info.get("price_cut", 0.0))), 1)


func buy(item):
	write("You buy a %s." % item, MUTED)
	write_changes({"Gold": -price_of(item)})
	player.add_item(item)
	refresh_screen()
	save_life()
	show_market()


# Spends this month's action on an activity, a person or your sect.
func do_action(choice):
	actions_left -= 1
	if choice.has("text"):
		write(choice["text"], MUTED)
	choose(choice)


# Extra Qi for every cultivation session: your sect's library, and the
# internal arts you know.
func library_bonus():
	var library = my_sect.levels["Scripture Library"] * 2 if my_sect != null else 0
	return library + int(martial.bonus("cultivate"))


# The cultivate loop: sit, gather Qi, repeat. Cultivating every year builds a
# streak that makes each session stronger; skipping a year resets it.
func cultivate():
	actions_left -= 1
	write("You sit cross-legged and circulate your Qi through the meridians.", MUTED)
	var before = player.stats["Qi"]
	player.cultivate(library_bonus())
	player.count("cultivated")
	if player.stats["Qi"] > before:
		write("Qi +%d" % (player.stats["Qi"] - before), GOOD)
	else:
		write("Your dantian is already full.", MUTED)
	write("Qi %d / %d  ·  cultivation streak: %d years in a row" %
		[player.stats["Qi"], player.qi_capacity, player.streak], MUTED)
	if player.can_break_through():
		write("You have gathered enough Qi to attempt a breakthrough.", GOLD)
	end_turn()


func breakthrough():
	actions_left -= 1
	write("You seal yourself away and drive your Qi against the barrier.", MUTED)
	# Two things from stories make a breakthrough certain: a jade pill, used
	# up by it, and the blood arts, which take their price every time.
	var certain = false
	if stories.has_flag("great_pill"):
		certain = true
		stories.clear_flag("great_pill")
		write("You swallow the jade pill. It burns a clear road through you.", GOLD)
	elif stories.has_flag("blood_art"):
		certain = true
		write("The blood arts force the barrier. Something in you pays for it.", BAD)
		write_changes({"Karma": -5, "Willpower": -5})
	if player.attempt_breakthrough(certain):
		chime()
		write("The barrier shatters. You are now %s." % player.stage_name(), GOLD)
		player.remember("broke through to the %s stage." % player.stage_name())
		write("All stats +%d  ·  Max Health %d  ·  Qi Capacity %d  ·  stat limit %d" %
			[player.STAGE_BOOST, player.max_health, player.qi_capacity, player.stat_cap()], GOOD)
	else:
		write("Your Qi runs wild and the breakthrough fails.", BAD)
		write("Health -25  ·  Happiness -10  ·  half of your Qi is lost", BAD)
	end_turn()


# ---------------------------------------------------------------------------
# Factions and sects
# ---------------------------------------------------------------------------

func show_sect():
	if my_sect != null:
		show_my_sect()
		return
	if player.sect == "":
		open_menu("Sect  ·  actions left this month: %d" % actions_left)
	else:
		open_menu("%s  ·  %s  ·  actions left this month: %d" %
			[player.sect, player.RANKS[player.rank()], actions_left])
	add_caption("How the great sects see you: " + factions.regard_line())
	if player.sect == "":
		for sect_name in World.SECTS:
			var info = World.SECTS[sect_name]
			var join = {"join": sect_name, "text": info["text"]}
			if factions.regard(sect_name) <= factions.SHUT_OUT:
				# A sect you have wronged does not open its gate to you.
				add_choice("Join " + sect_name, "They have not forgotten what you did", do_action.bind(join)).disabled = true
			elif info["faction"] == "Orthodox":
				# The Alliance tests your skill and turns away the wicked.
				join["stat"] = info["trains"]
				join["difficulty"] = 12
				if player.stats["Karma"] < 0:
					add_choice("Join " + sect_name, "Needs Karma 0 or higher", do_action.bind(join)).disabled = true
				else:
					add_choice("Join " + sect_name, "Skill test  ·  " + hint_for(join), do_action.bind(join))
			else:
				# The Cult only asks whether you can win.
				join["fight"] = "initiate"
				join["image"] = "cave"
				add_choice("Join " + sect_name, "Trial by combat  ·  " + hint_for(join), do_action.bind(join))
	else:
		# A mission done well raises your own sect's regard for you.
		var mission = World.FACTIONS[player.faction]["mission"].duplicate()
		mission["regard"] = [player.sect, 4]
		add_choice("Sect mission", hint_for(mission), do_action.bind(mission))
		martial.add_sect_lessons()
		add_choice("Leave " + player.sect, "", leave_sect)
	var found = add_choice("Found a sect", "Needs %d gold and the %s stage" %
		[FOUND_SECT_COST, player.STAGES[FOUND_SECT_STAGE]], found_sect)
	disable_without_actions()
	found.disabled = found.disabled or player.stage < FOUND_SECT_STAGE or player.stats["Gold"] < FOUND_SECT_COST
	add_choice("Back", "", show_group.bind("People"))


func join_sect(sect_name):
	player.sect = sect_name
	player.faction = World.SECTS[sect_name]["faction"]
	known_rank = player.rank()
	var info = World.FACTIONS[player.faction]
	write("%s accepts you. Your rank: %s." % [sect_name, player.RANKS[known_rank]], GOLD)
	write("%s values %s." % [info["name"], info["values"]], MUTED)
	write_changes({"Happiness": 10})
	factions.change(sect_name, factions.JOIN_REGARD)
	player.remember("joined %s." % sect_name)


func leave_sect():
	write("You bow three times at the gate and leave %s behind." % player.sect, MUTED)
	write_changes({"Reputation": -5})
	factions.change(player.sect, factions.LEAVE_REGARD)
	player.remember("left %s." % player.sect)
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
	write("You plant your banner on a quiet mountainside.", MUTED)
	write_changes({"Gold": -FOUND_SECT_COST})
	write("The %s is founded. %d disciples kneel before you." % [my_sect.sect_name, my_sect.disciples], GOLD)
	player.remember("founded the %s." % my_sect.sect_name)
	write("It stands with %s." % World.FACTIONS[player.faction]["name"], MUTED)
	end_turn()


# ---------------------------------------------------------------------------
# Sect management (once you lead a sect)
# ---------------------------------------------------------------------------

func show_my_sect():
	open_menu("%s  ·  actions left this month: %d" % [my_sect.sect_name, actions_left])
	add_choice("Build", "Raise a facility", show_build)
	var recruit = add_choice("Recruit", "Costs %d gold" % my_sect.RECRUIT_COST, recruit_disciples)
	add_choice("Wage war", "March on a rival", show_war)
	disable_without_actions()
	recruit.disabled = recruit.disabled or player.stats["Gold"] < my_sect.RECRUIT_COST
	add_choice("Sect report", "", write_sect_report)
	add_choice("Back", "", show_group.bind("People"))


func show_build():
	open_menu("Build  ·  you have %d gold" % player.stats["Gold"])
	for facility in my_sect.levels:
		var level = my_sect.levels[facility]
		if level >= my_sect.MAX_LEVEL:
			add_choice(facility, "Level %d  ·  fully built" % level, build.bind(facility)).disabled = true
		else:
			var cost = my_sect.build_cost(facility)
			var button = add_choice(facility, "Level %d  ·  costs %d gold" % [level, cost], build.bind(facility))
			button.disabled = player.stats["Gold"] < cost or actions_left <= 0
	add_choice("Back", "", show_my_sect)


func build(facility):
	actions_left -= 1
	write("Carpenters and masons get to work.", MUTED)
	write_changes({"Gold": -my_sect.build_cost(facility)})
	my_sect.build(facility)
	write("%s is now level %d." % [facility, my_sect.levels[facility]], GOLD)
	write(my_sect.FACILITIES[facility]["text"], MUTED)
	end_turn()


func recruit_disciples():
	actions_left -= 1
	write("You send word through the villages that the sect is taking disciples.", MUTED)
	write_changes({"Gold": -my_sect.RECRUIT_COST})
	var gained = my_sect.recruit(player.rank_score())
	write("%d new disciples join. The %s now has %d." % [gained, my_sect.sect_name, my_sect.disciples], GOOD)
	end_turn()


func show_war():
	open_menu("Wage war  ·  your sect's strength: %d" % my_sect.power(player))
	for rival in rivals:
		# You cannot attack your own faction.
		if rival["side"] != player.faction:
			add_choice(rival["name"], "Their strength: %d" % rival["power"], wage_war.bind(rival))
	disable_without_actions()
	add_choice("Back", "", show_my_sect)


func wage_war(rival):
	actions_left -= 1
	var result = my_sect.wage_war(player, rival)
	write("The %s marches on %s." % [my_sect.sect_name, rival["name"]], GOLD)
	write("Your strength %d  ·  their strength %d" % [result["ours"], result["theirs"]], MUTED)
	if result["won"]:
		write("Victory! Their gates fall and their banner burns.", GOOD)
		factions.change(rival["name"], factions.WAR_REGARD)
		player.remember("led the %s to victory over %s." % [my_sect.sect_name, rival["name"]])
		# Attacking the righteous is evil; crushing outlaws and cultists is not.
		var spoils = {"Gold": rival["gold"], "Reputation": rival["power"] / 10, "Happiness": 10}
		spoils["Karma"] = -15 if rival["side"] == "Orthodox" else 5
		if player.faction == "Unorthodox":
			spoils["Merit"] = rival["power"] / 8
		write_changes(spoils)
		rival["power"] = int(rival["power"] * 1.3)
	else:
		write("Defeat. Your disciples are driven back down the mountain.", BAD)
		write_changes({"Reputation": -10, "Health": -15, "Happiness": -10})
	write("Disciples lost: %d  ·  remaining: %d" % [result["fallen"], my_sect.disciples], MUTED)
	end_turn()


func write_sect_report():
	write_title(my_sect.sect_name.to_upper())
	for line in my_sect.report_lines(player):
		write(line)


# ---------------------------------------------------------------------------
# Relationships. The people in your life are looked after by
# scripts/npc_manager.gd and scripts/family_manager.gd; these are shortcuts.
# ---------------------------------------------------------------------------

func add_person(role, person_age, bond):
	return npcs.make(role, person_age, bond)


# True if someone with this role is alive and in your life.
func has_person(role):
	return npcs.has(role)


# Called when a choice has "meet".
func meet(role):
	npcs.meet(role)


func show_people():
	npcs.show_people()


# Replaces a role in curly brackets with that person's name, so a scenario
# can say "{Sibling} wants to join a sect".
func fill(text):
	if not text.contains("{"):
		return text
	for role in World.ROLES:
		var person = npcs.first(role)
		if person != null:
			text = text.replace("{%s}" % role, person["name"])
	return text


# ---------------------------------------------------------------------------
# Fighting, turn by turn: you pick a move, then your opponent makes theirs.
# The picture of the fight is drawn by scripts/battle_stage.gd.
# ---------------------------------------------------------------------------

# Builds the enemy for a fight. Enemies are written for a Commoner and grow
# with your stage.
func make_enemy(template):
	var picture = "person"
	if template is String:
		if template == "random":
			template = World.HUNT.pick_random()
		picture = template
		template = World.ENEMIES[template]
	var enemy = template.duplicate()
	if not enemy.has("picture"):
		enemy["picture"] = picture
	enemy["health"] = int(enemy["health"] * (1 + player.stage * 0.5))
	enemy["damage"] = int(enemy["damage"] * (1 + player.stage * 0.25))
	enemy["attack"] += player.stage * 6
	enemy["defense"] += player.stage * 6
	enemy["max_health"] = enemy["health"]
	return enemy


func burst_cost():
	return martial.qi_strike_cost(QI_BURST_COST * (player.stage + 1))


func flee_chance():
	var odds = 50 + (player.stats["Agility"] - foe["attack"]) * 5
	return clamp(odds + player.talent_info.get("flee_bonus", 0) + int(martial.bonus("flee")), 10, 95)


# The picture of a fighter: assets/fighters/<name>.png if you made one,
# otherwise the .svg that comes with the game.
func fighter_picture(fighter):
	for ending in ["png", "svg"]:
		var path = "res://assets/fighters/%s.%s" % [fighter, ending]
		if ResourceLoader.exists(path):
			return load(path)
	return load("res://assets/fighters/person.svg")


# Your chance (in %) to land a blow. Agility decides who hits whom.
func hit_chance(enemy, move = "strike"):
	var aim = 50 + (player.stats["Agility"] - enemy["defense"]) * 5
	aim = clamp(aim + player.talent_info.get("hit_bonus", 0) + int(martial.bonus("hit")), 10, 95)
	if move == "heavy":
		aim = max(aim - HEAVY_AIM, 5)
	return aim


# What every blow of yours does before the dice: your Strength, plus what
# your techniques add, plus anything special you carry (a legendary sword).
func blow_power():
	var power = player.stats["Strength"] + int(martial.bonus("damage"))
	for flag in Pack.FIGHT_FLAGS:
		if stories.has_flag(flag):
			power += Pack.FIGHT_FLAGS[flag]
	return power


func foe_hit_chance(enemy):
	return clamp(50 + (enemy["attack"] - player.stats["Agility"]) * 5, 10, 95)


# What your opponent decides to do this turn: one of the FOE_PLANS.
func pick_plan():
	var roll = randi_range(1, 100)
	for plan in FOE_PLANS:
		roll -= FOE_PLANS[plan]
		if roll <= 0:
			return plan
	return "strike"


# Rolls the dice for your blow and returns {"hit": true, "damage": 12}.
# Strength decides how hard you hit.
#   move  - "strike", "heavy" or "qi"
#   plan  - what your opponent is doing this turn
#   sure  - true if the blow cannot miss
#   edge  - your bonus from the fortune stick: 0.2 means you hit 20% harder
#           and are hurt 20% less (a negative edge works against you)
func roll_blow(move, enemy, plan, sure, edge):
	if not sure and randi_range(1, 100) > hit_chance(enemy, move):
		return {"hit": false, "damage": 0}
	var damage = blow_power() + randi_range(1, 6)
	if move == "heavy":
		damage *= HEAVY_DAMAGE
	if move == "qi":
		# Qi adds your Martial Insight and goes straight through a guard.
		damage += player.stats["Martial Insight"]
	elif plan == "guard":
		damage *= GUARD_BLOCK
	return {"hit": true, "damage": max(int(damage * (1.0 + edge)), 1)}


# Rolls the dice for a move that comes from a technique (see MOVES in
# martial_data.gd). "level" is how well you know the technique.
func roll_technique(special, level, enemy, plan, edge):
	var aim = clamp(hit_chance(enemy) + special.get("aim", 0), 5, 95)
	if not special.get("sure", false) and not sure_blow and randi_range(1, 100) > aim:
		return {"hit": false, "damage": 0}
	var damage = (blow_power() + randi_range(1, 6)) * special["damage"] * (1.0 + 0.15 * (level - 1))
	if plan == "guard" and not special.get("pierce", false):
		damage *= GUARD_BLOCK
	return {"hit": true, "damage": max(int(damage * (1.0 + edge)), 1)}


# Rolls the dice for your opponent's blow. "guarding" is true if you chose
# to guard this turn.
func roll_foe_blow(enemy, plan, guarding, edge):
	if randi_range(1, 100) > foe_hit_chance(enemy):
		return {"hit": false, "damage": 0}
	var damage = enemy["damage"] + randi_range(1, 4)
	if plan == "heavy":
		damage *= FOE_HEAVY_DAMAGE
	if guarding:
		# Defensive techniques make a guard block more.
		damage *= max(GUARD_BLOCK - martial.bonus("guard"), 0.2)
	# A hardened body takes less of every blow.
	damage *= max(1.0 - player.talent_info.get("armor", 0.0) - martial.bonus("armor"), 0.4)
	return {"hit": true, "damage": max(int(damage * (1.0 - edge)), 1)}


# Your chance (in %) to win if you simply strike every turn, found by quietly
# playing the fight 200 times with a plain fortune.
func win_chance(enemy, friendly):
	var wins = 0
	for i in 200:
		var health = player.stats["Health"]
		var enemy_health = enemy["health"]
		for turn in MAX_ROUNDS:
			var plan = pick_plan()
			enemy_health -= roll_blow("strike", enemy, plan, false, 0.0)["damage"]
			if enemy_health <= 0:
				wins += 1
				break
			if plan != "guard":
				health -= roll_foe_blow(enemy, plan, false, 0.0)["damage"]
			if health <= (15 if friendly else 0):
				break
	return wins / 2


func start_fight(choice):
	fight_choice = choice
	foe = make_enemy(choice["fight"])
	fight_round = 0
	fight_edge = 0.0
	stick_drawn = false
	sure_blow = false
	auto_fight = false
	used_moves = []
	menus_open = false
	# A fight gets a page of its own, with the fighters drawn over the picture.
	var image = choice.get("image", page_image)
	new_page(image if image != "" else "mountain")
	fight_log()
	write("You face %s." % foe["name"], GOLD)
	battle.speed = round_delay
	battle.set_profiles(portrait_profile(), foe["picture"])
	battle.begin(fighter_picture("hero"), fighter_picture(foe["picture"]), player.age < YOUNG_FIGHTER)
	bars.show()
	show_fight_bars()
	next_turn()


# Brings the two health bars under the picture (and your own numbers at the
# top of the screen) up to date.
func show_fight_bars():
	set_bar(your_bar, "You", player.stats["Health"], player.max_health)
	set_bar(enemy_bar, capital(foe["name"]), foe["health"], foe["max_health"])
	refresh_screen()


# The same words with a capital first letter: "the bandits" -> "The bandits".
func capital(words):
	return words.left(1).to_upper() + words.substr(1)


# Starts a turn: your opponent settles on a move, and you can see which.
func next_turn():
	fight_playing = false
	foe_plan = pick_plan()
	battle.show_plan(foe_plan)
	show_moves()
	if auto_fight:
		take_turn("strike")


# Your moves for this turn, as two columns of buttons.
func show_moves():
	clear_choices()
	add_caption(PLAN_TEXT[foe_plan] % foe["name"])
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	choices_box.add_child(grid)
	var aim = 100 if sure_blow else hit_chance(foe)
	var heavy_aim = 100 if sure_blow else hit_chance(foe, "heavy")
	add_move(grid, "Strike  ·  %d%%" % aim, take_turn.bind("strike"))
	add_move(grid, "Heavy blow  ·  %d%%" % heavy_aim, take_turn.bind("heavy"))
	add_move(grid, "Guard", take_turn.bind("guard"))
	var qi = add_move(grid, "Qi strike  ·  %d Qi" % burst_cost(), take_turn.bind("qi"))
	qi.disabled = player.stats["Qi"] < burst_cost()
	add_move(grid, "Fortune stick", draw_fortune).disabled = stick_drawn
	add_move(grid, "Auto-fight", start_auto)
	if fight_choice.get("friendly", false):
		add_move(grid, "Yield", end_fight.bind(false))
	else:
		add_move(grid, "Flee  ·  %d%%" % flee_chance(), flee)
	# The last place is for your techniques if you have any with a move of
	# their own; "How to fight" is then found inside that list.
	if martial.moves().is_empty():
		add_move(grid, "How to fight", show_fight_help)
	else:
		add_move(grid, "Techniques", show_technique_moves)


# The moves your techniques give you, in place of the usual ones. Each can
# be used once in a fight and costs Qi.
func show_technique_moves():
	clear_choices()
	add_caption(PLAN_TEXT[foe_plan] % foe["name"])
	for entry in martial.moves():
		var technique = entry[0]
		var special = entry[1]
		var hint = "Costs %d Qi  ·  once per fight" % special["qi"]
		var button = add_choice(special["name"], hint, take_turn.bind("technique", technique))
		button.disabled = technique in used_moves or player.stats["Qi"] < special["qi"]
	add_choice("How to fight", "", show_fight_help)
	add_choice("Back", "", show_moves)


# Adds one numbered move to the grid. The number keys press it, as they do
# for any other choice.
func add_move(grid, text, action):
	var button = Button.new()
	button.text = "%d.  %s" % [choice_buttons.size() + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	grid.add_child(button)
	choice_buttons.append(button)
	return button


# One turn of the fight: your move, then your opponent's.
#   move  - "strike", "heavy", "qi", "guard", "item" (you used something
#           from your inventory) or "flee" (you tried to run and failed)
func take_turn(move, item = ""):
	# The moves stay on the page, greyed out, while the blows are exchanged.
	for button in choice_buttons:
		button.disabled = true
	fight_playing = true
	fight_round += 1
	battle.speed = round_delay
	# A friendly duel and a fight marked "mercy" both stop before they kill you.
	var spared = fight_choice.get("friendly", false) or fight_choice.get("mercy", false)
	var guarding = move == "guard"
	fight_log()

	# --- Your move ---
	if guarding:
		battle.guard(true, true)
		write("You raise your guard and watch for an opening.", MUTED)
	elif move == "item":
		write("You use a %s.  %s" % [item, change_text(World.ITEMS[item]["use"])], MUTED)
	elif move == "flee":
		write("You tried to run, but %s cut you off." % foe["name"], BAD)
	elif move == "technique":
		# "item" is the technique here. Its move is used up for this fight.
		var special = martial.Data.MOVES[martial.Data.TECHNIQUES[item]["move"]]
		used_moves.append(item)
		player.change({"Qi": -special["qi"]})
		var blow = roll_technique(special, martial.level(item), foe, foe_plan, fight_edge)
		sure_blow = false
		foe["health"] = max(foe["health"] - blow["damage"], 0)
		write(special["text"], MUTED)
		await battle.strike(true, "qi", blow, show_fight_bars)
		if not is_inside_tree():
			return
		if blow["hit"]:
			write("Your %s hit %s for %d." % [special["name"].to_lower(), foe["name"], blow["damage"]], GOOD)
			if special.has("heal"):
				write_changes({"Health": int(blow["damage"] * special["heal"])})
		else:
			write("Your %s missed." % special["name"].to_lower(), MUTED)
	else:
		var sure = sure_blow or move == "qi"
		if move == "qi":
			player.change({"Qi": -burst_cost()})
		else:
			sure_blow = false
		var blow = roll_blow(move, foe, foe_plan, sure, fight_edge)
		foe["health"] = max(foe["health"] - blow["damage"], 0)
		await battle.strike(true, move, blow, show_fight_bars)
		if not is_inside_tree():
			return   # the game was restarted in the middle of the fight
		if blow["hit"]:
			write("Your %s hit %s for %d." % [MOVE_NAMES[move], foe["name"], blow["damage"]], GOOD)
		else:
			write("Your %s missed." % MOVE_NAMES[move], MUTED)
	show_fight_bars()
	if foe["health"] <= 0:
		end_fight(true)
		return
	# Guarding lets you read your opponent: your next blow cannot miss.
	if guarding:
		sure_blow = true

	# --- Your opponent's move ---
	# The lines about your opponent are in the past tense, so that they read
	# right for one opponent ("the wolf") and for several ("the bandits").
	var foe_name = capital(foe["name"])
	if foe_plan == "guard":
		write("%s held a tight guard." % foe_name, MUTED)
	else:
		var blow = roll_foe_blow(foe, foe_plan, guarding, fight_edge)
		var left = max(player.stats["Health"] - blow["damage"], 0)
		# A friendly duel stops before anyone gets killed, and so does a
		# fight marked "mercy".
		player.stats["Health"] = max(left, 1) if spared else left
		await battle.strike(false, foe_plan, blow, show_fight_bars)
		if not is_inside_tree():
			return
		if not blow["hit"]:
			write("%s missed you." % foe_name, MUTED)
		elif guarding:
			write("%s hit your guard for %d." % [foe_name, blow["damage"]], BAD)
		elif foe_plan == "heavy":
			write("%s landed a heavy blow for %d." % [foe_name, blow["damage"]], BAD)
		else:
			write("%s hit you for %d." % [foe_name, blow["damage"]], BAD)
	battle.guard(true, false)

	var health = player.stats["Health"]
	if health <= 0 or (spared and health <= 15):
		end_fight(false)
	elif fight_round >= MAX_ROUNDS:
		write("Neither of you can finish it. You both step back, spent.", MUTED)
		end_fight(false)
	else:
		next_turn()


# Starts a fresh page of text for the round. Only the newest lines are kept,
# so the picture of the fight stays in view.
func fight_log():
	finish_typing()
	story.clear()
	if fight_round == 0:
		write_title("A DUEL" if fight_choice.get("friendly", false) else "A FIGHT")
	else:
		write_title("%s  ·  ROUND %d" % [foe["name"].to_upper(), fight_round])


# Auto-fight: you strike every turn until the fight is over.
func start_auto():
	auto_fight = true
	take_turn("strike")


# Draws one of the FORTUNES at random; heavier ones come up more often. The
# stick lasts for the whole fight, and drawing it does not use up your turn.
func draw_fortune():
	var sticks = []
	for fortune in FORTUNES:
		# The lucky talent takes the worst stick out of the cup.
		if fortune["edge"] <= -0.2 and player.talent_info.get("lucky", false):
			continue
		sticks.append(fortune)
	var total = 0
	for fortune in sticks:
		total += fortune["weight"]
	var pick = randi_range(1, total)
	var drawn = sticks[0]
	for fortune in sticks:
		pick -= fortune["weight"]
		if pick <= 0:
			drawn = fortune
			break
	var color = MUTED
	if drawn["edge"] > 0:
		color = GOOD
	elif drawn["edge"] < 0:
		color = BAD
	fight_edge = drawn["edge"]
	stick_drawn = true
	fight_log()
	write("You shake the bamboo cup and a stick falls out: %s." % drawn["name"], color)
	if fight_edge != 0:
		write("Your blows are %d%% %s this fight." % [abs(roundi(fight_edge * 100)), "stronger" if fight_edge > 0 else "weaker"], MUTED)
	show_moves()


# Running away works at once or costs you the turn.
func flee():
	if randi_range(1, 100) <= flee_chance():
		end_fight(false)
	else:
		take_turn("flee")


func end_fight(won):
	fight_playing = false
	auto_fight = false
	var friendly = fight_choice.get("friendly", false)
	battle.speed = round_delay
	battle.show_plan("")
	battle.guard(true, false)
	if won:
		battle.fall(false, friendly)
		write("You defeated %s!" % foe["name"], GOLD)
	elif player.stats["Health"] <= 0:
		battle.fall(true, false)
		write("%s struck you down." % capital(foe["name"]), BAD)
	elif friendly and player.stats["Health"] <= 15:
		battle.fall(true, true)
		write("You are beaten, and bow to %s." % foe["name"], MUTED)
	elif fight_choice.get("mercy", false) and player.stats["Health"] <= 15:
		battle.fall(true, false)
		write("You are beaten. %s left you where you fell." % capital(foe["name"]), BAD)
	else:
		write("You withdraw from the fight.", MUTED)
	finish_choice(fight_choice, won)


# The "How to fight" pop-up.
func show_fight_help():
	open_popup("How to fight")
	popup_line("Above your moves you can read what your opponent is about to do.", GOLD, 20)
	popup_line("Strike: a plain blow. The number is your chance to land it.", TEXT, 20)
	popup_line("Heavy blow: hits much harder, but is harder to land.", TEXT, 20)
	popup_line("Guard: you take half damage this turn, and your next blow cannot miss. Use it against a heavy blow.", TEXT, 20)
	popup_line("Qi strike: costs Qi. It cannot miss, hits harder the more Martial Insight you have, and cuts through a guard.", TEXT, 20)
	popup_line("Fortune stick: once per fight, and it does not use up your turn. A lucky stick makes you stronger, an unlucky one weaker.", TEXT, 20)
	popup_line("Inventory: using an item takes your turn.", TEXT, 20)
	popup_line("Auto-fight: you strike every turn until it is over.", TEXT, 20)


# ---------------------------------------------------------------------------
# Pop-ups: profile, settings and the menu
# ---------------------------------------------------------------------------

# Where you stand in the world, as one line.
func standing():
	if player.faction == "":
		return "%s  ·  wanderer with no sect" % player.stage_name()
	if my_sect != null:
		return "%s  ·  leader of the %s" % [player.stage_name(), my_sect.sect_name]
	return "%s  ·  %s of %s" % [player.stage_name(), player.RANKS[player.rank()], player.sect]


func show_profile():
	open_popup("Profile")
	# Your portrait, larger than in the header, with a word for your Looks.
	var picture = Portrait.new()
	picture.custom_minimum_size = Vector2(PROFILE_PORTRAIT, PROFILE_PORTRAIT)
	popup_body.add_child(picture)
	picture.set_profile(portrait_profile())
	var word = UiTheme.label(Portrait.looks_word(player.stats["Looks"]), 20, UiTheme.GOLD)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_body.add_child(word)
	popup_line(player.full_name, TEXT, 30)
	popup_line("%s  ·  age %d  ·  born in the year %d" % [player.gender, player.age, player.birth_year], MUTED)
	popup_line("Rank: %s" % standing())
	popup_line("Name in the jianghu: %s" % factions.name_in_jianghu(), MUTED, 20)
	var walking = "%s (%s)" % [player.path, life.rank_name()] if player.path != "" else "none yet"
	popup_line("Background: %s  ·  Life path: %s" % [player.background, walking], MUTED, 20)
	if not player.properties.is_empty():
		popup_line("Property: %s" % ", ".join(player.properties), MUTED, 20)
	popup_line("Talent: %s" % player.talent_name, GOLD)
	popup_bar("Health", player.stats["Health"], player.max_health)
	for stat in ["Happiness", "Smarts", "Looks", "Willpower"]:
		popup_bar(stat, player.stats[stat], 100)
	popup_line("Strength %d  ·  Agility %d  ·  Martial Insight %d" %
		[player.stats["Strength"], player.stats["Agility"], player.stats["Martial Insight"]])
	popup_line("Qi %d / %d  ·  cultivation streak %d years" %
		[player.stats["Qi"], player.qi_capacity, player.streak])
	popup_line("Karma %+d  ·  Reputation %d  ·  Merit %d  ·  Gold %d" %
		[player.stats["Karma"], player.stats["Reputation"], player.stats["Merit"], player.stats["Gold"]])
	if player.stats["Shame"] > 0:
		popup_line("Shame %d" % player.stats["Shame"], BAD, 20)
	if not player.techniques.is_empty():
		var known = []
		for technique in player.techniques:
			known.append("%s %d" % [martial.title(technique), player.techniques[technique]])
		popup_line("Techniques: %s" % ", ".join(known), MUTED, 20)


# The inventory: everything you carry, each with a Use button.
# "note" is a line shown at the top, such as what you just used.
func show_inventory(note = ""):
	open_popup("Inventory")
	if note != "":
		popup_line(note, GOOD, 20)
	if player.items.is_empty():
		popup_line("You are carrying nothing.", MUTED)
		popup_line("Items can be bought at the Market (in More) or found on your travels.", MUTED, 18)
		return
	if foe != null:
		popup_line("In a fight, using an item takes your turn.", MUTED, 18)
	# Nothing can be used once you are dead, or while blows are being exchanged.
	var locked = fight_playing or player.stats["Health"] <= 0
	for item in player.items:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var words = VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title = Label.new()
		title.text = "%s  x%d" % [item, player.items[item]]
		var hint = Label.new()
		hint.text = World.ITEMS[item]["text"]
		hint.theme_type_variation = "HintLabel"
		words.add_child(title)
		words.add_child(hint)
		var button = Button.new()
		button.text = "Use"
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.disabled = locked
		button.pressed.connect(use_item.bind(item))
		row.add_child(words)
		row.add_child(button)
		popup_body.add_child(row)


func use_item(item):
	player.remove_item(item)
	if foe != null:
		# In a fight this is your move for the turn.
		close_popup()
		take_turn("item", item)
		return
	write("You use a %s." % item, MUTED)
	write_changes(World.ITEMS[item]["use"])
	refresh_screen()
	save_life()
	show_inventory("Used: %s" % item)


func show_settings():
	open_popup("Settings")
	popup_line("Text speed", MUTED, 18)
	popup_options(TEXT_SPEEDS, type_speed, set_text_speed)
	popup_line("Fight speed", MUTED, 18)
	popup_options(FIGHT_SPEEDS, round_delay, set_fight_speed)
	popup_line("Button sound", MUTED, 18)
	popup_options(SOUND_LEVELS, sound_volume, set_sound)
	popup_line("Music", MUTED, 18)
	popup_options(MUSIC_SWITCH, 1.0 if music_on else 0.0, set_music_on)
	popup_line("Music volume", MUTED, 18)
	popup_options(MUSIC_LEVELS, music_volume, set_music)


func set_sound(value):
	sound_volume = value
	apply_sound()
	save_settings()
	show_settings()


func set_music_on(value):
	music_on = value > 0
	apply_sound()
	save_settings()
	show_settings()


func set_music(value):
	music_volume = value
	apply_sound()
	save_settings()
	show_settings()


# Sets how loud the button sounds and the music are. Volume is measured in
# decibels, so the 0-to-1 numbers are converted.
func apply_sound():
	# The button sounds come from ui_pack/ui_sounds.gd. It is the "UiSounds"
	# autoload (Project > Project Settings > Globals), so it can be used by
	# name from any script.
	UiSounds.enabled = sound_volume > 0
	UiSounds.volume_db = BUTTON_SOUND_DB + linear_to_db(max(sound_volume, 0.01))
	music.volume_db = linear_to_db(music_volume)
	# Switching the music off pauses it, so switching it on carries on from
	# the same place.
	music.stream_paused = not music_on


# The soft chime for a big moment: a breakthrough, a new technique, a talent
# that grows, an achievement.
func chime():
	UiSounds.play("reward")


func set_text_speed(value):
	type_speed = value
	save_settings()
	show_settings()


func set_fight_speed(value):
	round_delay = value
	save_settings()
	show_settings()


func load_settings():
	var file = ConfigFile.new()
	if file.load(SETTINGS_FILE) == OK:
		type_speed = file.get_value("settings", "type_speed", type_speed)
		round_delay = file.get_value("settings", "round_delay", round_delay)
		sound_volume = file.get_value("settings", "sound_volume", sound_volume)
		music_on = file.get_value("settings", "music_on", music_on)
		music_volume = file.get_value("settings", "music_volume", music_volume)
		if music_volume <= 0:
			# Older settings used a volume of 0 to mean "off".
			music_on = false
			music_volume = 0.5


func save_settings():
	var file = ConfigFile.new()
	file.set_value("settings", "type_speed", type_speed)
	file.set_value("settings", "round_delay", round_delay)
	file.set_value("settings", "sound_volume", sound_volume)
	file.set_value("settings", "music_on", music_on)
	file.set_value("settings", "music_volume", music_volume)
	file.save(SETTINGS_FILE)


# "note" is a line shown at the top, such as "Life saved."
func show_menu(note = ""):
	open_popup("Menu")
	if note != "":
		popup_line(note, GOOD, 20)
	popup_button("Save life", save_now).disabled = not can_save()
	popup_line("The game also saves by itself at the end of every month.", MUTED, 18)
	popup_button("Load life", load_saved).disabled = not Saves.has_life()
	popup_line("Goes back to your last save.", MUTED, 18)
	popup_button("New life", restart)
	popup_line("Your current life stays saved until the new one is born.", MUTED, 18)
	popup_button("Journal", stories.show_journal).disabled = not alive
	popup_button("Jianghu Chronicle", chronicle.show_chronicle)
	popup_button("Credits", show_credits)


func save_now():
	save_life()
	show_menu("Life saved.")


func show_credits():
	open_popup("Credits")
	popup_line("Made with Godot Engine (godotengine.org), free software under the MIT licence.", TEXT, 20)
	popup_line("Text is set in EB Garamond by Georg Duffner and Octavio Pardo, used under the SIL Open Font License 1.1.", TEXT, 20)
	popup_line(Engine.get_license_text(), MUTED, 13)


func open_popup(title):
	clear(popup_body)
	popup_title.text = title
	popup_scroll.scroll_vertical = 0
	popup.show()


# Makes the pop-up as tall as what is in it, up to a share of the screen.
# Anything beyond that can be scrolled to.
func fit_popup():
	var wanted = popup_body.get_combined_minimum_size().y
	popup_scroll.custom_minimum_size.y = min(wanted, get_viewport_rect().size.y * POPUP_HEIGHT)


func close_popup():
	popup.hide()


func popup_line(text, color = TEXT, font_size = 22):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(color))
	label.add_theme_font_size_override("font_size", font_size)
	popup_body.add_child(label)


# A coloured bar with its name and number written on it. The colour of each
# stat's bar is in BAR_COLOURS (scripts/game_theme.gd).
func popup_bar(title, value, max_value):
	var bar = UiTheme.make_bar(Look.BAR_COLOURS[title], 30)
	bar.get_node("Text").add_theme_font_size_override("font_size", 18)
	popup_body.add_child(bar)
	UiTheme.set_bar(bar, title, value, max_value)


func popup_button(text, action):
	var button = Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(action)
	popup_body.add_child(button)
	return button


# A row of buttons, one per option. The one in use is shown in gold.
func popup_options(options, current, action):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for option in options:
		var button = Button.new()
		button.text = option
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 20)
		if is_equal_approx(options[option], current):
			button.add_theme_color_override("font_color", Color(GOLD))
		button.pressed.connect(action.bind(options[option]))
		row.add_child(button)
	popup_body.add_child(row)


# ---------------------------------------------------------------------------
# The page: picture, typed-out text and choices
# ---------------------------------------------------------------------------

# Starts a fresh page. "image" is a picture in assets/scenes, or "" for none.
func new_page(image):
	finish_typing()
	story.clear()
	battle.hide()
	page_image = image
	illustration.visible = image != ""
	if image != "":
		illustration.texture = load("res://assets/scenes/%s.tres" % image)


# Adds a line to the page. It is typed out letter by letter.
func write(text, color = TEXT):
	# Text that is already on the page stays; only the new line is typed.
	if story.visible_characters < 0:
		story.visible_characters = story.get_total_character_count()
	story.append_text("[color=%s]%s[/color]\n" % [color, text])
	start_typing()


# Adds a small centred heading such as "AGE 12 · MONTH 3 · YEAR 1215".
func write_title(title):
	if story.visible_characters < 0:
		story.visible_characters = story.get_total_character_count()
	story.append_text("[center][font_size=18][color=%s]%s[/color][/font_size][/center]\n" % [GOLD, title])
	start_typing()


# Adds the name of a scenario above its text, such as "The Old Beggar".
func write_heading(title):
	if story.visible_characters < 0:
		story.visible_characters = story.get_total_character_count()
	story.append_text("[center][color=%s]%s[/color][/center]\n" % [GOLD, title])
	start_typing()


func start_typing():
	if typing != null:
		typing.kill()
		typing = null
	if type_speed <= 0:
		finish_typing()
		return
	var total = story.get_total_character_count()
	var seconds = (total - story.visible_characters) / type_speed
	# The choices stay hidden until the text has finished appearing.
	choices_box.hide()
	typing = create_tween()
	typing.tween_property(story, "visible_characters", total, seconds)
	typing.tween_callback(finish_typing)


func finish_typing():
	if typing != null:
		typing.kill()
	typing = null
	story.visible_characters = -1
	choices_box.show()


func scroll_down():
	if showing_menu:
		# A long menu starts at its first choice instead of its last.
		page.scroll_vertical = int(choices_box.position.y) - 8
	else:
		page.scroll_vertical = int(page.get_v_scroll_bar().max_value)


func clear(box):
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func clear_choices():
	clear(choices_box)
	choice_buttons = []
	showing_menu = false


# Starts a menu (More, relationships, sect) with a small heading.
func open_menu(caption):
	clear_choices()
	showing_menu = true
	add_caption(caption)


func add_caption(text):
	var label = Label.new()
	label.text = text
	label.theme_type_variation = "HintLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choices_box.add_child(label)


# Adds a numbered choice to the page. "hint" is the small line shown
# underneath it.
func add_choice(text, hint, action):
	var button = Button.new()
	button.text = "%d.   %s" % [choice_buttons.size() + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	# "Back" and "Continue" have sounds of their own; the rest make the soft tap.
	if CHOICE_SOUNDS.has(text):
		button.set_meta("ui_sound", CHOICE_SOUNDS[text])
	choices_box.add_child(button)
	choice_buttons.append(button)
	if hint != "":
		var label = Label.new()
		label.text = "       " + hint
		label.theme_type_variation = "HintLabel"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choices_box.add_child(label)
	return button


# Greys out every choice added so far when you have no actions left.
func disable_without_actions():
	if actions_left <= 0:
		for button in choice_buttons:
			button.disabled = true


# ---------------------------------------------------------------------------
# The header: portrait, Health and Qi bars, and the row of stat chips
# ---------------------------------------------------------------------------

func refresh_screen():
	# The portrait only redraws when something about your look has changed.
	portrait.set_profile(portrait_profile())
	name_label.text = player.full_name
	stage_label.text = player.stage_name()
	date_label.text = "Age %d  ·  Month %d  ·  Year %d" % [player.age, player.month, player.year()]
	if player.sect != "":
		date_label.text += "  ·  " + player.sect
	set_bar(health_bar, "Health", player.stats["Health"], player.max_health)
	set_bar(qi_bar, "Qi", player.stats["Qi"], player.qi_capacity)

	for stat in chip_labels:
		if stat == "Actions":
			chip_labels[stat].text = "Actions %d" % actions_left
		elif stat == "Karma":
			chip_labels[stat].text = "Karma %+d" % player.stats[stat]
		elif stat == "Martial Insight":
			chip_labels[stat].text = "Insight %d" % player.stats[stat]
		else:
			chip_labels[stat].text = "%s %d" % [stat, player.stats[stat]]

	# + Age and More wait while an encounter or a fight needs your answer.
	age_button.disabled = not menus_open
	more_button.disabled = not menus_open


# Writes a bar's name and number on it, and glides it to the new value.
func set_bar(bar, title, value, max_value):
	UiTheme.set_bar(bar, title, value, max_value)


# What your portrait is chosen by (see ui_pack/portrait.gd). You never pick a
# face: it follows your Looks, your age and your gender, so it gets better
# or worse as your Looks change. "seed" decides which set of faces is yours
# once the pack holds more than one sheet of them.
func portrait_profile():
	return {
		"name": player.full_name, "gender": player.gender, "age": player.age,
		"looks": player.stats["Looks"], "seed": player.face_seed,
		"look": player.appearance, "outfit": player.portrait_outfit,
		"backdrop": player.portrait_backdrop, "cultivation": player.stage,
	}


# Adds someone's portrait to a menu on the page, above its choices.
func add_portrait(profile):
	var picture = Portrait.new()
	picture.custom_minimum_size = Vector2(PERSON_PORTRAIT, PERSON_PORTRAIT)
	choices_box.add_child(picture)
	picture.set_profile(profile)


# A note for you while you build the game: "" if the pack's pictures are in
# place, and otherwise what to do about it. Players never see it.
func picture_note():
	return ""
