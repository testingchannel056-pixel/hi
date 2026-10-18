extends RefCounted

# Martial techniques. They are separate from your stats: a technique is
# something you know, and it grows from level 1 to level 3 with practice.
# The rules are in scripts/martial_manager.gd.
#
# Each technique has:
#   "name", "type" and "text"   what the player reads
#   "needs"                     what you must have before you can learn it
#                               from a master or a sect (same format as
#                               everywhere else; see requirements.gd)
#   "sect"                      only taught inside this sect
# and any of these effects. Each one counts once per level:
#   "damage"      added to every blow you land
#   "hit"         added to your chance to land a blow (in %)
#   "flee"        added to your chance to flee (in %)
#   "armor"       0.05 means you take 5% less damage
#   "guard"       0.1 means a guard blocks 10% more
#   "cultivate"   Qi added to every cultivation session
#   "bond"        added every time a bond grows
#   "yearly"      what it brings every birthday (not multiplied by level)
#   "qi_saving"   Qi a Qi strike costs less
# "move" gives you an extra move in fights (see MOVES below).

const MAX_LEVEL = 3
const TYPES = ["Body", "Movement", "Internal Art", "Weapon", "Defensive", "Special"]

const TECHNIQUES = {
	"qi_sense": {"name": "Qi Sense", "type": "Internal Art",
		"text": "You feel the qi of people and things. Each cultivation session gathers more Qi.",
		"cultivate": 1},
	"flowing_cloud_steps": {"name": "Flowing Cloud Steps", "type": "Movement",
		"text": "Your feet barely touch the ground. Fleeing is easier and your blows land more often.",
		"flee": 10, "hit": 3, "needs": {"Agility": 9}},
	"iron_shirt": {"name": "Iron Shirt", "type": "Defensive",
		"text": "Skin like boiled leather. You take less damage in fights.",
		"armor": 0.05, "needs": {"Strength": 9}},
	"drunken_fist": {"name": "Drunken Fist", "type": "Body",
		"text": "Never where you seem to be. A move in fights: Drunken blow.",
		"move": "drunken", "needs": {"Agility": 10}},
	"hidden_weapons": {"name": "Hidden Weapons", "type": "Weapon",
		"text": "Needles in the sleeve. A move in fights: Hidden needle.",
		"move": "needle", "needs": {"Agility": 10}},
	"medicine": {"name": "Medicine", "type": "Special",
		"text": "You know which root cures and which kills. You heal a little every year.",
		"yearly": {"Health": 8}, "needs": {"Smarts": 55}},
	"poison_lore": {"name": "Poison Lore", "type": "Special",
		"text": "A little something on the blade. Your blows do more damage.",
		"damage": 1, "needs": {"Smarts": 55}},
	"honeyed_tongue": {"name": "Honeyed Tongue", "type": "Special",
		"text": "People believe you. Bonds grow faster.",
		"bond": 2},
	"thousand_faces": {"name": "Thousand Faces", "type": "Special",
		"text": "A new face for every town. Fleeing is easier.",
		"flee": 8},
	"sword_intent": {"name": "Sword Intent", "type": "Weapon",
		"text": "The sword moves before the hand does. Your blows do more damage and land more often.",
		"damage": 2, "hit": 3, "needs": {"Martial Insight": 14, "stage": 1}},
	"taiji_sword": {"name": "Taiji Sword", "type": "Weapon", "sect": "Wudang",
		"text": "Softness that turns hardness aside. Your guard blocks more, and your blows do more damage.",
		"guard": 0.08, "damage": 1, "needs": {"Martial Insight": 10}},
	"plum_blossom_sword": {"name": "Plum Blossom Sword", "type": "Weapon", "sect": "Mount Hua",
		"text": "Blows that fall like petals in the wind. They land more often and do more damage.",
		"hit": 5, "damage": 1, "needs": {"Agility": 10}},
	"arhat_fist": {"name": "Arhat Fist", "type": "Body", "sect": "Shaolin",
		"text": "The first fist of Shaolin. Your blows do more damage and you take less.",
		"damage": 2, "armor": 0.03, "needs": {"Strength": 10}},
	"blood_devouring_art": {"name": "Blood-Devouring Art", "type": "Internal Art",
		"text": "It feeds on what you take from others. More Qi from cultivation, and a move in fights: Blood drain.",
		"cultivate": 2, "move": "drain"},
	"heavenly_demon_art": {"name": "Heavenly Demon Art", "type": "Internal Art", "sect": "Demonic Cult",
		"text": "The art of the Heavenly Demon himself. Your blows do far more damage and a Qi strike costs less.",
		"damage": 3, "qi_saving": 3, "needs": {"stage": 2}},
	# --- Techniques of this game that the content pack does not have ---
	"breathing_method": {"name": "Tortoise Breathing", "type": "Internal Art",
		"text": "Slow breath, long life. Each cultivation session gathers more Qi.",
		"cultivate": 1},
	"cloud_step": {"name": "Cloud Step", "type": "Movement",
		"text": "A light step taught to every wandering swordsman. Fleeing is easier.",
		"flee": 8},
	"heavens_palm": {"name": "Heaven's Palm", "type": "Body",
		"text": "A palm strike driven by Qi. A move in fights: Heaven's Palm.",
		"move": "palm", "needs": {"Strength": 12, "stage": 1}},
	"golden_bell": {"name": "Golden Bell", "type": "Defensive",
		"text": "Qi rings around the body like a bell. Your guard blocks more and you take less damage.",
		"guard": 0.08, "armor": 0.04, "needs": {"stage": 1}},
}

# Extra moves in a fight, given by techniques. Each can be used once per
# fight, costs Qi, and is rolled like an ordinary blow with these changes:
#   "damage"   times as much damage as a strike
#   "aim"      added to the chance to land (in %); "sure" cannot miss
#   "pierce"   goes through the opponent's guard
#   "heal"     this share of the damage comes back to you as Health
# A higher technique level makes the move 15% stronger per level.
const MOVES = {
	"drunken": {"name": "Drunken blow", "qi": 5, "damage": 1.3, "aim": 25, "pierce": true,
		"text": "You stumble, and the stumble is the blow."},
	"needle": {"name": "Hidden needle", "qi": 5, "damage": 1.2, "sure": true,
		"text": "A flick of the sleeve."},
	"drain": {"name": "Blood drain", "qi": 10, "damage": 1.4, "heal": 0.5,
		"text": "Your palm closes on their wrist and something flows up your arm."},
	"palm": {"name": "Heaven's Palm", "qi": 12, "damage": 2.0, "aim": -10, "pierce": true,
		"text": "You gather everything into one open hand."},
}

# What the masters you meet can teach, and what it takes.
const MASTER_TEACHES = ["breathing_method", "cloud_step", "iron_shirt", "sword_intent", "heavens_palm", "golden_bell"]
const TEACH_BOND = 50       # bond needed before a master teaches you anything
const TEACH_COST = 20       # Gold a lesson costs (a gift for the master)

# The Gold a sect asks for each lesson, and the rank needed (0 is Outer Disciple).
const SECT_TEACH_COST = 10
const SECT_TEACHES = {
	"Wudang": {"taiji_sword": 0, "breathing_method": 0, "golden_bell": 2},
	"Mount Hua": {"plum_blossom_sword": 0, "cloud_step": 0, "sword_intent": 2},
	"Shaolin": {"arhat_fist": 0, "iron_shirt": 1, "golden_bell": 2},
	"Beggars' Union": {"drunken_fist": 0, "cloud_step": 0, "hidden_weapons": 1},
	"Demonic Cult": {"poison_lore": 0, "hidden_weapons": 1, "heavenly_demon_art": 3},
}

# Practising a technique (More > Martial arts): the chance in % to raise it
# a level, at level 1 and at level 2.
const PRACTICE_CHANCE = [30, 15]
