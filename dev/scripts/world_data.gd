extends RefCounted

# The content of the murim world, written as plain data. To add content, add
# more entries to these lists. Nothing in here runs any game logic.

# ---------------------------------------------------------------------------
# Factions and the great sects
# ---------------------------------------------------------------------------

# "mission" is the job your faction gives you. It uses the same format as an
# encounter choice (see ENCOUNTERS below).
const FACTIONS = {
	"Orthodox": {
		"name": "The Orthodox Alliance",
		"values": "Karma and Reputation",
		"mission": {"fight": "bandit", "win": {"Reputation": 6, "Karma": 3, "Gold": 15},
			"text": "The sect sends you to clear bandits from a mountain pass."},
	},
	"Unorthodox": {
		"name": "The Unorthodox Faction",
		"values": "Strength and Merit",
		"mission": {"fight": "duelist", "win": {"Merit": 10, "Gold": 20, "Karma": -4},
			"text": "The cult sends you to raid an Alliance supply line."},
	},
}

# "trains" is the stat that members of the sect train more easily.
const SECTS = {
	"Shaolin": {"faction": "Orthodox", "trains": "Strength",
		"text": "The monks of Shaolin temper the body until it rings like iron."},
	"Mount Hua": {"faction": "Orthodox", "trains": "Agility",
		"text": "Mount Hua's plum blossom swords fall as fast as petals in the wind."},
	"Wudang": {"faction": "Orthodox", "trains": "Martial Insight",
		"text": "Wudang's Taoists seek the stillness inside every movement."},
	"Demonic Cult": {"faction": "Unorthodox", "trains": "Strength",
		"text": "In the Demonic Cult the strong take and the weak serve. Prove yourself in blood."},
}

# Gold a great sect pays you each year, by rank (Outer, Inner, Core, Elder).
const STIPENDS = [5, 10, 20, 40]

# Names for the sect you can found yourself.
const SECT_NAMES = ["Azure Cloud Sect", "Iron Lotus Hall", "Nine Peaks Sect", "Crimson Moon Pavilion", "Silent River Sect"]

# Who your own sect can go to war with. You cannot attack your own faction.
const RIVALS = [
	{"name": "Black Tiger Gang", "side": "Outlaw", "power": 40, "gold": 60},
	{"name": "Iron Fist Hall", "side": "Outlaw", "power": 100, "gold": 140},
	{"name": "Mount Hua", "side": "Orthodox", "power": 220, "gold": 300},
	{"name": "Wudang", "side": "Orthodox", "power": 260, "gold": 350},
	{"name": "Shaolin", "side": "Orthodox", "power": 300, "gold": 400},
	{"name": "Demonic Cult", "side": "Unorthodox", "power": 320, "gold": 450},
]

# ---------------------------------------------------------------------------
# Enemies
# ---------------------------------------------------------------------------

# "attack" helps them hit you, "defense" makes them harder to hit. These are
# the numbers for a Commoner; enemies grow stronger with your stage.
const ENEMIES = {
	"wolf": {"name": "Mountain Wolf", "health": 25, "attack": 4, "defense": 4, "damage": 5},
	"bandit": {"name": "Mountain Bandit", "health": 40, "attack": 6, "defense": 6, "damage": 7},
	"initiate": {"name": "Cult Initiate", "health": 45, "attack": 7, "defense": 7, "damage": 8},
	"duelist": {"name": "Wandering Swordsman", "health": 50, "attack": 8, "defense": 8, "damage": 8},
	"cultist": {"name": "Demonic Cultist", "health": 70, "attack": 10, "defense": 10, "damage": 11},
	"beast": {"name": "Spirit Beast", "health": 130, "attack": 13, "defense": 11, "damage": 15},
}

# "Hunt" picks one of these at random.
const HUNT = ["wolf", "bandit", "duelist"]

# ---------------------------------------------------------------------------
# Childhood (age 1, 2, 3... before you can make choices)
# ---------------------------------------------------------------------------

const CHILDHOOD = [
	"You take your first wobbly steps across the courtyard.",
	"You speak your first words. Everyone claims you said their name.",
	"You chase the village chickens with a stick, shouting like a swordsman.",
	"You listen wide-eyed to stories of heroes who split mountains.",
	"You start helping with chores. The water buckets are heavier than they look.",
]

# ---------------------------------------------------------------------------
# Encounters: one happens every year
# ---------------------------------------------------------------------------

# A choice with "stat" rolls a 20-sided die + that stat against "difficulty".
# A choice with "fight" starts a battle against that enemy.
# A choice with "friendly" is a duel that stops before anyone dies.
# A choice with "meet" adds that person to your relationships on success.
# A choice with none of these always succeeds.
# "win" and "lose" can change anything in the status window:
#   Health, Qi, Qi Capacity, Strength, Agility, Martial Insight,
#   Karma, Reputation, Merit, Gold
# An encounter with "min_age" only shows up once you are that old.
# An encounter with "faction" only shows up for members of that faction.
const ENCOUNTERS = [
	{
		"text": "An old beggar offers you a strange pill.",
		"choices": [
			{"label": "Eat it", "stat": "Martial Insight", "difficulty": 12,
				"win": {"Qi": 20}, "lose": {"Health": -20}},
			{"label": "Give him your lunch instead", "win": {"Karma": 3}},
		],
	},
	{
		"text": "You find a torn sword manual in the mud.",
		"choices": [
			{"label": "Study it", "stat": "Martial Insight", "difficulty": 13,
				"win": {"Agility": 1, "Martial Insight": 1}, "lose": {}},
			{"label": "Sell it", "win": {"Gold": 8}},
		],
	},
	{
		"text": "A wandering physician sets up a stall in your village.",
		"choices": [
			{"label": "Ask for treatment", "win": {"Health": 25}},
			{"label": "Ask to be taught", "stat": "Martial Insight", "difficulty": 14,
				"win": {"Martial Insight": 2}, "lose": {}},
		],
	},
	{
		"text": "A stranger about your age shares a rice cake with you.",
		"choices": [
			{"label": "Share your food in return", "meet": "Friend", "win": {"Karma": 2}},
			{"label": "Eat it and run", "win": {"Strength": 1, "Karma": -2}},
		],
	},
	{
		"text": "You find a quiet waterfall, thick with spiritual energy.",
		"choices": [
			{"label": "Meditate beneath it", "stat": "Martial Insight", "difficulty": 12,
				"win": {"Qi": 15}, "lose": {"Health": -10}},
			{"label": "Train in the current", "win": {"Strength": 1}},
		],
	},
	{
		"text": "A sect elder is testing children at the market square.",
		"choices": [
			{"label": "Step forward", "stat": "Agility", "difficulty": 13, "meet": "Master",
				"win": {"Qi": 10, "Martial Insight": 1}, "lose": {}},
			{"label": "Watch from the crowd", "win": {"Martial Insight": 1}},
		],
	},
	{
		"text": "A glowing herb grows on a cliff edge, just out of reach.",
		"choices": [
			{"label": "Climb for it", "stat": "Agility", "difficulty": 13,
				"win": {"Qi": 20, "Health": 10}, "lose": {"Health": -25}},
			{"label": "Leave it be", "win": {"Health": 5}},
		],
	},
	{
		"text": "Starving refugees line the road, holding out empty bowls.",
		"choices": [
			{"label": "Give them your coin", "win": {"Gold": -10, "Karma": 6, "Reputation": 2}},
			{"label": "Walk on", "win": {"Karma": -1}},
		],
	},
	{
		"text": "A hungry wolf stalks you on the forest path.",
		"min_age": 10,
		"choices": [
			{"label": "Stand your ground", "fight": "wolf", "win": {"Strength": 1}},
			{"label": "Climb a tree and wait", "stat": "Agility", "difficulty": 10,
				"win": {}, "lose": {"Health": -15}},
		],
	},
	{
		"text": "Bandits leap from the roadside brush. \"Your coin or your life!\"",
		"min_age": 12,
		"choices": [
			{"label": "Fight them", "fight": "bandit", "win": {"Gold": 15, "Reputation": 3, "Karma": 2}},
			{"label": "Hand over your purse", "win": {"Gold": -15}},
			{"label": "Run for it", "stat": "Agility", "difficulty": 12,
				"win": {}, "lose": {"Health": -15, "Gold": -5}},
		],
	},
	{
		"text": "Behind a collapsed shrine wall you find an ancient manual sealed in oilcloth.",
		"min_age": 12,
		"choices": [
			{"label": "Study it in secret", "stat": "Martial Insight", "difficulty": 14,
				"win": {"Qi Capacity": 15, "Martial Insight": 2}, "lose": {"Health": -15}},
			{"label": "Hand it to the Alliance", "win": {"Karma": 5, "Reputation": 8}},
			{"label": "Sell it on the black market", "win": {"Gold": 40, "Karma": -5}},
		],
	},
	{
		"text": "A drunken swordsman slams down his cup and challenges you to a duel.",
		"min_age": 14,
		"choices": [
			{"label": "Accept the duel", "fight": "duelist", "friendly": true, "meet": "Rival",
				"win": {"Reputation": 8, "Gold": 10}},
			{"label": "Buy him a drink instead", "win": {"Gold": -5, "Karma": 1}},
			{"label": "Decline", "win": {"Reputation": -2}},
		],
	},
	{
		"text": "A wounded Alliance disciple begs you to hide him from cultist hunters.",
		"min_age": 14,
		"choices": [
			{"label": "Hide him", "stat": "Agility", "difficulty": 12,
				"win": {"Karma": 6, "Reputation": 4}, "lose": {"Health": -15, "Karma": 2}},
			{"label": "Rob him", "win": {"Gold": 20, "Karma": -10, "Merit": 5}},
		],
	},
	{
		"text": "A merchant caravan is hiring guards for the mountain road.",
		"min_age": 14,
		"choices": [
			{"label": "Guard it", "fight": "bandit", "win": {"Gold": 30, "Reputation": 4}},
			{"label": "Rob it yourself", "fight": "duelist", "win": {"Gold": 50, "Karma": -12, "Merit": 8}},
			{"label": "Pass by", "win": {}},
		],
	},
	{
		"text": "A demonic cultist is draining the life from a village.",
		"min_age": 16,
		"choices": [
			{"label": "Confront the cultist", "fight": "cultist", "win": {"Reputation": 10, "Karma": 8, "Qi": 10}},
			{"label": "Lead the villagers to safety", "stat": "Agility", "difficulty": 13,
				"win": {"Karma": 5, "Reputation": 3}, "lose": {"Health": -20}},
			{"label": "Look the other way", "win": {"Karma": -5}},
		],
	},
	{
		"text": "A spirit beast sleeps coiled around a thousand-year ginseng.",
		"min_age": 16,
		"choices": [
			{"label": "Slay the beast", "fight": "beast", "win": {"Qi Capacity": 20, "Qi": 30, "Reputation": 10}},
			{"label": "Sneak past it", "stat": "Agility", "difficulty": 15,
				"win": {"Qi": 30}, "lose": {"Health": -30}},
			{"label": "Back away slowly", "win": {}},
		],
	},
	{
		"text": "The Alliance calls its disciples to drive cultists out of a border town.",
		"min_age": 14, "faction": "Orthodox",
		"choices": [
			{"label": "Join the vanguard", "fight": "cultist", "win": {"Reputation": 12, "Karma": 4}},
			{"label": "Guard the wounded", "win": {"Karma": 3, "Reputation": 2}},
			{"label": "Stay behind", "win": {"Reputation": -3}},
		],
	},
	{
		"text": "A senior cultist sneers that your rank should be his.",
		"min_age": 14, "faction": "Unorthodox",
		"choices": [
			{"label": "Break him", "fight": "initiate", "win": {"Merit": 15}},
			{"label": "Yield your place", "win": {"Merit": -10}},
		],
	},
	{
		"text": "The cult orders you to burn a village that refused tribute.",
		"min_age": 14, "faction": "Unorthodox",
		"choices": [
			{"label": "Obey", "win": {"Merit": 15, "Gold": 15, "Karma": -15}},
			{"label": "Warn the villagers first", "stat": "Agility", "difficulty": 13,
				"win": {"Karma": 8}, "lose": {"Merit": -10, "Health": -15}},
		],
	},
]

# ---------------------------------------------------------------------------
# Activities: things you can choose to do each year
# ---------------------------------------------------------------------------

# Same format as encounter choices. "train" means the roll gets harder the
# closer that stat is to its cap. "cultivate" is the Cultivate action.
const ACTIVITIES = [
	{"label": "Cultivate", "cultivate": true,
		"text": "You sit cross-legged and circulate your Qi through the meridians."},
	{"label": "Train strength", "train": "Strength", "win": {"Strength": 1}, "lose": {"Health": -5},
		"text": "You strike the wooden post until dusk."},
	{"label": "Train agility", "train": "Agility", "win": {"Agility": 1}, "lose": {"Health": -5},
		"text": "You run the plum-blossom poles until your legs shake."},
	{"label": "Study martial arts", "train": "Martial Insight", "win": {"Martial Insight": 1}, "lose": {},
		"text": "You study forms and manuals by candlelight."},
	{"label": "Rest", "win": {"Health": 30},
		"text": "You rest, eat well and tend your wounds."},
	{"label": "Work", "min_age": 10, "win": {"Gold": 10},
		"text": "You haul cargo at the river docks."},
	{"label": "Hunt", "min_age": 12, "fight": "random", "win": {"Reputation": 2, "Gold": 5},
		"text": "You wander the wilds looking for trouble."},
]

# ---------------------------------------------------------------------------
# People in your life. "guidance" is what they can teach you.
# ---------------------------------------------------------------------------

const ROLES = {
	"Father": {"guidance": {"Strength": 1}, "train": "Strength", "power": 1.2},
	"Mother": {"guidance": {"Martial Insight": 1}, "train": "Martial Insight", "power": 1.0},
	"Master": {"guidance": {"Qi": 12}, "power": 2.0},
	"Friend": {"guidance": {"Agility": 1}, "train": "Agility", "power": 1.0},
	"Rival": {"guidance": {"Strength": 1}, "train": "Strength", "power": 1.3},
}
