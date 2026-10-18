extends RefCounted

# Who you are born as and what you make of it: backgrounds, the steps a
# talent can grow through, and life paths. Plain data, like world_data.gd.
# The rules that use it are in scripts/life_manager.gd.

# ---------------------------------------------------------------------------
# Backgrounds: chosen on the New Life screen
# ---------------------------------------------------------------------------

# "start" is added to your stats at birth (same format as "win" in a scenario).
# "items" are heirlooms you own from the start.
# "father" and "mother" are what your parents do for a living.
# "orphan" means you have no parents; a temple caretaker raises you.
# "paths" are life paths that are open to you without their usual requirement.
# A background never locks anything: every path can still be earned.
const BACKGROUNDS = {
	"Poor Village": {
		"text": "A farming family in a hungry village. Hard work from the first day.",
		"start": {"Strength": 1, "Willpower": 8},
		"father": "Farmer", "mother": "Weaver",
		"paths": ["Farmer"],
	},
	"Merchant Family": {
		"text": "A shop on the market street. You count coins before you can read.",
		"start": {"Smarts": 5, "Gold": 40},
		"father": "Merchant", "mother": "Shopkeeper",
		"paths": ["Merchant"],
	},
	"Martial Clan": {
		"text": "A clan that has carried swords for six generations. Much is expected of you.",
		"start": {"Strength": 1, "Agility": 1, "Reputation": 3},
		"father": "Clan Swordsman", "mother": "Clan Swordswoman",
		"paths": ["Martial Disciple"],
	},
	"Sect Family": {
		"text": "Born inside a sect's walls. You fall asleep to the sound of disciples drilling.",
		"start": {"Martial Insight": 1, "Qi Capacity": 10},
		"father": "Sect Elder", "mother": "Sect Disciple",
		"paths": ["Sect Heir"],
	},
	"Scholar Family": {
		"text": "A house full of books and very little else.",
		"start": {"Smarts": 10, "Willpower": 3},
		"father": "Scholar", "mother": "Teacher",
		"paths": ["Scholar"],
	},
	"Noble Family": {
		"text": "Silk, servants and a family name that opens doors. And closes some.",
		"start": {"Looks": 5, "Gold": 80, "Reputation": 5, "Willpower": -5},
		"items": ["Fine Robe"],
		"father": "Magistrate", "mother": "Lady of the House",
	},
	"Orphan": {
		"text": "Left at a temple gate. Nobody is coming for you, so you learn to come for yourself.",
		"start": {"Agility": 1, "Willpower": 10, "Happiness": -10},
		"orphan": true,
		"paths": ["Wanderer"],
	},
	"Wandering Family": {
		"text": "Performers and pedlars. Home is wherever the cart stops tonight.",
		"start": {"Agility": 1, "Smarts": 3, "Happiness": 5},
		"father": "Travelling Performer", "mother": "Herb Seller",
		"paths": ["Wanderer"],
	},
}

# ---------------------------------------------------------------------------
# Talent growth
# ---------------------------------------------------------------------------

# Each talent in world_data.gd can grow twice. The first step comes by itself
# on a birthday once you meet its "needs". The second step also needs its
# awakening scenario (TALENT_SCENARIOS below) to go well.
#
# A step can change what the talent does:
#   "train", "train_bonus"  one stat is easier to train
#   "train_all"             every stat is easier to train
#   "max_health"            added to your Max Health when you gain the step
#   "qi_bonus"              0.5 means 50% more Qi from cultivation
#   "bond_bonus"            added every time a bond grows
#   "break_bonus"           added to your breakthrough chance (in %)
#   "luck"                  added to every pure-luck roll (in %)
#   "lucky"                 you never draw the worst fortune stick
#   "armor"                 0.15 means you take 15% less damage in fights
#   "flee_bonus", "hit_bonus"   added to those chances in a fight (in %)
#   "price_cut"             0.15 means the Market is 15% cheaper
# "count" in "needs" looks at what you have done so far in this life.
const TALENT_STEPS = {
	"None": [
		{"name": "Diligent", "needs": {"count": {"trained": 25}},
			"text": "No gift, only stubbornness. All training is a little easier.",
			"train_all": 6},
		{"name": "Self-Made", "needs": {"count": {"trained": 70}, "stage": 2},
			"text": "Everything was earned. All training is easier. Max Health +20.",
			"train_all": 12, "max_health": 20},
	],
	"Iron Body": [
		{"name": "Steel Bones", "needs": {"Strength": 18, "stage": 1},
			"text": "Strength training is much easier. Max Health +40.",
			"train": "Strength", "train_bonus": 25, "max_health": 20},
		{"name": "Unbreakable Physique", "needs": {"Strength": 30, "stage": 3},
			"text": "Strength training is far easier. Max Health +80. You take 15% less damage in fights.",
			"train": "Strength", "train_bonus": 35, "max_health": 40, "armor": 0.15},
	],
	"Wind Step": [
		{"name": "Shadow Step", "needs": {"Agility": 18, "stage": 1},
			"text": "Agility training is much easier. Fleeing a fight is easier.",
			"train": "Agility", "train_bonus": 25, "flee_bonus": 15},
		{"name": "Heaven-Chasing Step", "needs": {"Agility": 30, "stage": 3},
			"text": "Agility training is far easier. You flee and land blows more easily.",
			"train": "Agility", "train_bonus": 35, "flee_bonus": 30, "hit_bonus": 10},
	],
	"Scholar's Mind": [
		{"name": "Enlightened Mind", "needs": {"Martial Insight": 18, "Smarts": 65},
			"text": "Martial Insight training is much easier. Breakthroughs are a little easier.",
			"train": "Martial Insight", "train_bonus": 25, "break_bonus": 5},
		{"name": "Sage's Insight", "needs": {"Martial Insight": 30, "Smarts": 80, "stage": 3},
			"text": "Martial Insight training is far easier. Breakthroughs are easier.",
			"train": "Martial Insight", "train_bonus": 35, "break_bonus": 12},
	],
	"Heavenly Meridians": [
		{"name": "Open Meridians", "needs": {"stage": 1, "count": {"cultivated": 40}},
			"text": "Cultivation gathers 50% more Qi.",
			"qi_bonus": 0.5},
		{"name": "Boundless Meridians", "needs": {"stage": 3, "count": {"cultivated": 150}},
			"text": "Cultivation gathers 80% more Qi.",
			"qi_bonus": 0.8},
	],
	"Silver Tongue": [
		{"name": "Golden Words", "needs": {"age": 16, "Looks": 55, "count": {"bonds": 20}},
			"text": "Bonds grow much faster. The Market is 15% cheaper for you.",
			"bond_bonus": 10, "price_cut": 0.15},
		{"name": "Voice of the People", "needs": {"Reputation": 60, "count": {"bonds": 60}},
			"text": "Bonds grow far faster. The Market is 30% cheaper for you.",
			"bond_bonus": 14, "price_cut": 0.3},
	],
	"Fortune's Favourite": [
		{"name": "Heaven's Favourite", "needs": {"age": 18, "count": {"lucky": 12}},
			"text": "You never draw the worst fortune stick. Pure-luck choices succeed 8% more often.",
			"lucky": true, "luck": 8},
		{"name": "Child of Destiny", "needs": {"stage": 2, "count": {"lucky": 35}},
			"text": "You never draw the worst fortune stick. Pure-luck choices succeed 15% more often.",
			"lucky": true, "luck": 15},
	],
}

# The scenario in which each talent can take its second step. It only shows
# up for someone who has the first step and meets the needs of the second.
# A choice with "talent_up" grows the talent when it succeeds.
const TALENT_SCENARIOS = {
	"None": {
		"text": "An old soldier watches you train alone in the rain. \"No gift at all,\" he says. \"I was the same. Shall I show you what forty years of stubbornness taught me?\"",
		"image": "mountain",
		"choices": [
			{"label": "Train with him until spring", "stat": "Willpower", "difficulty": 55, "talent_up": true,
				"win_text": "By the thaw you can no longer remember what it felt like to be told you had no talent.",
				"lose": {"Health": -10}, "lose_text": "Your body gives out before your will does. He tells you to come back when you are ready."},
			{"label": "Bow and decline", "win": {}},
		],
	},
	"Iron Body": {
		"text": "A wandering monk offers to temper your body the old way: a hundred days of iron sand, bitter herbs and cold rivers.",
		"image": "waterfall",
		"choices": [
			{"label": "Endure the hundred days", "stat": "Strength", "difficulty": 18, "talent_up": true,
				"win_text": "On the last day he breaks a staff across your back. You do not notice until he shows you the pieces.",
				"lose": {"Health": -20}, "lose_text": "On the sixtieth day your body fails. He tells you to return when you are stronger."},
			{"label": "Thank him and walk on", "win": {}},
		],
	},
	"Wind Step": {
		"text": "On a cliff path you watch a hawk fall on a hare, and for an instant you see exactly how the fall is done.",
		"image": "mountain",
		"choices": [
			{"label": "Step off the path after it", "stat": "Agility", "difficulty": 18, "talent_up": true,
				"win_text": "You land without a sound, further down than anyone should. The hawk looks offended.",
				"lose": {"Health": -20}, "lose_text": "You land badly. The moment is gone, but you know now that it exists."},
			{"label": "Keep to the path", "win": {}},
		],
	},
	"Scholar's Mind": {
		"text": "A blind old woman in a tea house is correcting the storyteller's account of a famous duel, move by move. She was there.",
		"image": "tavern",
		"choices": [
			{"label": "Ask her to teach you how to see", "stat": "Martial Insight", "difficulty": 18, "talent_up": true,
				"win_text": "She talks until dawn. Afterwards every fight you have ever watched replays itself in your head, and makes sense.",
				"lose": {}, "lose_text": "You follow about half of it. \"Come back when the other half troubles you,\" she says."},
			{"label": "Listen from your table", "win": {"Martial Insight": 1}},
		],
	},
	"Heavenly Meridians": {
		"text": "Deep in meditation you find a gate inside yourself that you have never been able to open.",
		"image": "cave",
		"choices": [
			{"label": "Drive all your Qi against it", "stat": "Willpower", "difficulty": 60, "talent_up": true,
				"win_text": "It opens like a held breath let go. Qi moves through places in you that were dark before.",
				"lose": {"Health": -20}, "lose_text": "The gate holds, and throws you back. You wake with blood on your lips."},
			{"label": "Leave it for another year", "win": {}},
		],
	},
	"Silver Tongue": {
		"text": "Two villages face each other across a bridge with hoes and cleavers, about to kill one another over a dry well.",
		"image": "village",
		"choices": [
			{"label": "Step between them and speak", "stat": "Looks", "difficulty": 60, "talent_up": true,
				"win": {"Reputation": 8, "Karma": 5},
				"win_text": "You talk until your voice cracks. By evening they are digging a new well together, and arguing about who you belong to.",
				"lose": {"Health": -15}, "lose_text": "Someone throws a stone. You are carried off the bridge, still talking."},
			{"label": "Cross somewhere else", "win": {}},
		],
	},
	"Fortune's Favourite": {
		"text": "A dying gambler presses a pair of worn dice into your hand. \"They never loved me,\" he says. \"Maybe they will love you.\"",
		"image": "tavern",
		"choices": [
			{"label": "Roll them once, for everything in your purse", "percent": 60, "talent_up": true,
				"win": {"Gold": 50},
				"win_text": "Double sixes. Then again. Then again. The whole tavern has gone quiet.",
				"lose": {"Gold": -30}, "lose_text": "Snake eyes. The dice roll under a table and you never find them, though you will see them again."},
			{"label": "Bury them with him", "win": {"Karma": 2}},
		],
	},
}

# ---------------------------------------------------------------------------
# Life paths: what you spend your days on, from age 13
# ---------------------------------------------------------------------------

# You pick a path in More > Life path, and you can change it whenever you
# meet another path's "needs". A background listed in BACKGROUNDS "paths"
# only needs the age.
# "yearly" is what the path brings every birthday (same format as "win").
# "train" makes those stats easier to train while you walk the path.
# "wander" raises the chance of an encounter each month (in %).
const LIFE_PATHS = {
	"Farmer": {
		"text": "Work the land. Honest, tiring and never rich.",
		"needs": {"age": 13},
		"yearly": {"Gold": 8, "Health": 5, "Willpower": 1},
		"year_text": "A year of ploughing, planting and praying for rain.",
	},
	"Martial Disciple": {
		"text": "Give your days to the martial arts. Strength, Agility and Martial Insight train more easily.",
		"needs": {"age": 13, "Strength": 7},
		"yearly": {"Willpower": 1},
		"train": {"Strength": 8, "Agility": 8, "Martial Insight": 8},
		"year_text": "A year of stances, bruises and slow improvement.",
	},
	"Scholar": {
		"text": "Study the classics. Smarts grows every year, and Martial Insight trains more easily.",
		"needs": {"age": 13, "Smarts": 55},
		"yearly": {"Smarts": 3, "Gold": 4},
		"train": {"Martial Insight": 10},
		"year_text": "A year among books, ink and other people's arguments.",
	},
	"Craftsman": {
		"text": "Learn a trade at the forge or the workbench. Steady coin and strong arms.",
		"needs": {"age": 13, "Strength": 8},
		"yearly": {"Gold": 14},
		"train": {"Strength": 8},
		"year_text": "A year at the workbench. Your hands know things your head does not.",
	},
	"Merchant": {
		"text": "Buy low, sell high. The best coin of any honest path.",
		"needs": {"age": 15, "Smarts": 50, "Gold": 30},
		"yearly": {"Gold": 28},
		"year_text": "A year of ledgers, haggling and long roads between markets.",
	},
	"Physician": {
		"text": "Learn which root cures and which kills. You heal yourself every year, and others thank you.",
		"needs": {"age": 15, "Smarts": 60},
		"yearly": {"Gold": 12, "Health": 15, "Karma": 2, "Reputation": 1},
		"year_text": "A year of fevers broken, bones set and babies delivered.",
	},
	"Wanderer": {
		"text": "No home and no master. More happens to you on the road.",
		"needs": {"age": 15, "Agility": 8},
		"yearly": {"Reputation": 1, "Happiness": 2},
		"train": {"Agility": 8},
		"wander": 15,
		"year_text": "A year of roads, inns and strangers' stories.",
	},
	"Sect Heir": {
		"text": "Raised to lead. Qi comes easily, and so does everyone's attention.",
		"needs": {"age": 13, "Martial Insight": 12, "Reputation": 20},
		"yearly": {"Reputation": 2, "Qi": 10},
		"train": {"Martial Insight": 8},
		"year_text": "A year of lessons, duties and elders watching every move you make.",
	},
	"Jianghu Outlaw": {
		"text": "Take what you want and answer to no one. Good coin, bad name.",
		"needs": {"age": 15, "max": {"Karma": -5}},
		"yearly": {"Gold": 22, "Karma": -3},
		"train": {"Agility": 6},
		"wander": 10,
		"year_text": "A year of other people's purses and looking over your shoulder.",
	},
	"Teacher": {
		"text": "Pass on what you know. Modest coin, lasting respect.",
		"needs": {"age": 25, "Smarts": 70},
		"yearly": {"Gold": 10, "Reputation": 2, "Happiness": 3},
		"year_text": "A year of pupils. One or two of them may even remember what you said.",
	},
	"Hunter": {
		"text": "Live off the forest. Lean coin, quick feet and good health.",
		"needs": {"age": 13, "Agility": 8},
		"yearly": {"Gold": 10, "Health": 5},
		"train": {"Agility": 8},
		"year_text": "A year of tracks, snares and long cold mornings.",
	},
	"Guard": {
		"text": "Stand between other people's goods and other people's greed.",
		"needs": {"age": 15, "Strength": 9},
		"yearly": {"Gold": 14, "Reputation": 1},
		"train": {"Strength": 6},
		"year_text": "A year of night watches, caravan dust and the odd real fight.",
	},
}

# ---------------------------------------------------------------------------
# Careers: the ranks you rise through on a life path
# ---------------------------------------------------------------------------

# Every path has three ranks. You start at the first. The next one comes on a
# birthday once you have walked the path for "years" and meet its "needs".
# Each rank above the first adds RANK_PAY to the Gold the path pays, and
# "gain" is a one-off reward for the promotion.
const RANK_PAY = 0.6
const CAREER_RANKS = {
	"Farmer": [
		{"name": "Field Hand"},
		{"name": "Farmer", "years": 4, "needs": {}, "gain": {"Reputation": 1}},
		{"name": "Village Elder", "years": 12, "needs": {"Reputation": 15}, "gain": {"Reputation": 5}},
	],
	"Martial Disciple": [
		{"name": "Novice"},
		{"name": "Martial Artist", "years": 4, "needs": {"stage": 1}, "gain": {"Reputation": 3}},
		{"name": "Martial Master", "years": 10, "needs": {"stage": 3}, "gain": {"Reputation": 10}},
	],
	"Scholar": [
		{"name": "Student"},
		{"name": "Scholar", "years": 4, "needs": {"Smarts": 70}, "gain": {"Reputation": 3}},
		{"name": "Grand Scholar", "years": 10, "needs": {"Smarts": 90}, "gain": {"Reputation": 10}},
	],
	"Craftsman": [
		{"name": "Apprentice"},
		{"name": "Craftsman", "years": 4, "needs": {"Strength": 12}, "gain": {"Reputation": 2}},
		{"name": "Master Smith", "years": 10, "needs": {"Strength": 20}, "gain": {"Reputation": 8}},
	],
	"Merchant": [
		{"name": "Pedlar"},
		{"name": "Shopkeeper", "years": 4, "needs": {"Gold": 150}, "gain": {"Reputation": 2}},
		{"name": "Merchant Prince", "years": 10, "needs": {"Gold": 600}, "gain": {"Reputation": 10}},
	],
	"Physician": [
		{"name": "Apprentice Healer"},
		{"name": "Physician", "years": 4, "needs": {"Smarts": 75}, "gain": {"Reputation": 4}},
		{"name": "Divine Doctor", "years": 10, "needs": {"Smarts": 90, "Karma": 20}, "gain": {"Reputation": 15}},
	],
	"Wanderer": [
		{"name": "Drifter"},
		{"name": "Wandering Swordsman", "years": 4, "needs": {"Reputation": 30}, "gain": {"Reputation": 3}},
		{"name": "Legend of the Road", "years": 10, "needs": {"Reputation": 100}, "gain": {"Reputation": 10}},
	],
	"Sect Heir": [
		{"name": "Young Master"},
		{"name": "Heir Apparent", "years": 4, "needs": {"stage": 1}, "gain": {"Reputation": 5}},
		{"name": "Head of the House", "years": 10, "needs": {"stage": 3}, "gain": {"Reputation": 15}},
	],
	"Jianghu Outlaw": [
		{"name": "Cutpurse"},
		{"name": "Bandit", "years": 3, "needs": {"max": {"Karma": -20}}, "gain": {"Gold": 20}},
		{"name": "Bandit Chief", "years": 8, "needs": {"max": {"Karma": -45}, "Strength": 18}, "gain": {"Gold": 80}},
	],
	"Teacher": [
		{"name": "Tutor"},
		{"name": "Teacher", "years": 4, "needs": {}, "gain": {"Reputation": 3}},
		{"name": "Grand Tutor", "years": 10, "needs": {"Smarts": 90, "Reputation": 40}, "gain": {"Reputation": 10}},
	],
	"Hunter": [
		{"name": "Trapper"},
		{"name": "Hunter", "years": 4, "needs": {"Agility": 12}, "gain": {"Reputation": 1}},
		{"name": "Master of the Hunt", "years": 10, "needs": {"Agility": 20}, "gain": {"Reputation": 6}},
	],
	"Guard": [
		{"name": "Watchman"},
		{"name": "Escort Guard", "years": 4, "needs": {"Strength": 12}, "gain": {"Reputation": 2}},
		{"name": "Chief Escort", "years": 10, "needs": {"Strength": 20, "Reputation": 30}, "gain": {"Reputation": 8}},
	],
}

# What a month of extra work looks like on each path (the Work action in
# More). "" is for someone with no path. The Gold grows with your rank.
const WORK = {
	"": {"text": "You haul cargo at the river docks.", "gold": 4},
	"Farmer": {"text": "You hire yourself out for the harvest.", "gold": 3},
	"Martial Disciple": {"text": "You give lessons to a merchant's clumsy son.", "gold": 3},
	"Scholar": {"text": "You write letters for those who cannot.", "gold": 3},
	"Craftsman": {"text": "You take on a rush order and work through the nights.", "gold": 4},
	"Merchant": {"text": "You run a consignment to the next town and back.", "gold": 6},
	"Physician": {"text": "You see patients from dawn until the lamps are lit.", "gold": 4},
	"Wanderer": {"text": "You take odd jobs along the road.", "gold": 3},
	"Sect Heir": {"text": "You settle a dispute between two branch families, for a fee.", "gold": 4},
	"Jianghu Outlaw": {"text": "You relieve a tax collector of his burden.", "gold": 6},
	"Teacher": {"text": "You tutor a magistrate's children through the summer.", "gold": 3},
	"Hunter": {"text": "You sell pelts and venison at the market.", "gold": 3},
	"Guard": {"text": "You escort a caravan over the mountain road.", "gold": 4},
}

# ---------------------------------------------------------------------------
# Money: the cost of living, and property
# ---------------------------------------------------------------------------

# From age 18 a year of rice and rent costs LIVING_COST Gold, plus CHILD_COST
# for every child under 14. A year you cannot pay for is a hard one.
const LIVING_AGE = 18
const LIVING_COST = 8
const CHILD_COST = 4
const HARD_YEAR = {"Health": -8, "Happiness": -6}
# Wealth costs money to keep: each year this share of your Gold above
# TAX_FREE goes on taxes, gifts and upkeep.
const TAX_FREE = 100
const TAX = 0.03

# Time wears a name down. From FADE_AGE on, every year takes 1 point of
# Reputation and of Shame, plus one more for every so many points you have:
# 15 for Reputation (so 100 Reputation loses 7 a year), 50 for Shame.
const FADE_AGE = 16
const FADE = {"Reputation": 15, "Shame": 50}

# Property is bought in More > Market > Property. "yearly" is what it brings
# every birthday (same format as "win"). You can own one of each.
const PROPERTIES = {
	"Cottage": {"price": 120, "text": "A roof of your own. Health +5 and Happiness +3 every year.",
		"yearly": {"Health": 5, "Happiness": 3}},
	"Market Stall": {"price": 200, "text": "Earns 15 Gold every year.",
		"yearly": {"Gold": 15}},
	"Shop": {"price": 450, "text": "Earns 40 Gold every year.",
		"yearly": {"Gold": 40}},
	"Courtyard House": {"price": 700, "text": "Room for a family. Happiness +8 and Reputation +2 every year.",
		"yearly": {"Happiness": 8, "Reputation": 2}},
	"Estate": {"price": 1500, "text": "Land, servants and a name. Earns 60 Gold and Reputation +4 every year.",
		"yearly": {"Gold": 60, "Reputation": 4}},
}

# ---------------------------------------------------------------------------
# Growing up without parents (the Orphan background)
# ---------------------------------------------------------------------------

# The first page of an orphan's life, in place of BIRTH in world_data.gd.
const ORPHAN_BIRTH = {
	"text": "A basket is left at the gate of a small mountain temple on a night of snow. Inside it, you.",
	"choices": [
		{"label": "Scream until someone comes", "win": {"Strength": 1},
			"win_text": "The old caretaker comes running in her nightclothes."},
		{"label": "Lie still and watch the snow fall", "win": {"Willpower": 5},
			"win_text": "When they find you at dawn you are not crying. The monks talk about it for years."},
		{"label": "Smile at the first face you see", "win": {"Caretaker": 5, "Happiness": 5},
			"win_text": "\"Well,\" says the caretaker, \"that settles it.\""},
	],
}

# An orphan's birthday milestones, in place of CHILDHOOD in world_data.gd.
const ORPHAN_CHILDHOOD = [
	{
		"text": "You take your first steps across the temple courtyard, between the legs of sweeping novices.",
		"image": "shrine",
		"choices": [
			{"label": "Totter towards the caretaker", "win": {"Caretaker": 6, "Happiness": 4},
				"win_text": "She puts her broom down just in time."},
			{"label": "Totter towards the great bronze bell", "stat": "Agility", "difficulty": 12,
				"win": {"Agility": 1}, "win_text": "You slap it with both hands. It hums for you.",
				"lose": {"Health": -5}, "lose_text": "The step is higher than it looks."},
			{"label": "Chase the temple cat", "win": {"Happiness": 4}},
		],
	},
	{
		"text": "Your first word is on the tip of your tongue. The caretaker and two novices lean in.",
		"image": "shrine",
		"choices": [
			{"label": "\"Granny\"", "win": {"Caretaker": 8},
				"win_text": "She pretends to be cross about it for the rest of the day."},
			{"label": "\"Rice\"", "win": {"Health": 5, "Happiness": 3},
				"win_text": "Everyone agrees it is a sensible first word."},
			{"label": "\"Sword\"", "win": {"Martial Insight": 1},
				"win_text": "The novices look at each other. One of them hides his practice sword."},
		],
	},
	{
		"text": "A wandering swordsman drinks at the temple well. His scabbard hangs right at your eye level.",
		"image": "shrine",
		"choices": [
			{"label": "Tug on the scabbard", "percent": 50,
				"win": {"Martial Insight": 1, "Happiness": 5},
				"win_text": "He laughs and lets you hold the hilt for one breath.",
				"lose": {"Happiness": -5, "Caretaker": -3},
				"lose_text": "The caretaker drags you away by the ear, apologising."},
			{"label": "Ask him for a story", "win": {"Smarts": 3, "Happiness": 3},
				"win_text": "He tells you of a man who cut a waterfall in two."},
			{"label": "Watch from behind the water jar", "win": {"Willpower": 2}},
		],
	},
	{
		"text": "A novice whittles you a wooden sword from a broken broom handle.",
		"image": "shrine",
		"choices": [
			{"label": "Swing it until your arms ache", "win": {"Strength": 1}},
			{"label": "Copy the stances you saw the swordsman use", "stat": "Martial Insight", "difficulty": 13,
				"win": {"Martial Insight": 1}, "win_text": "For a moment the sword feels like part of your arm.",
				"lose": {}, "lose_text": "You mostly hit yourself."},
			{"label": "Trade it for a steamed bun", "win": {"Health": 5, "Happiness": 3}},
		],
	},
	{
		"text": "You are old enough for chores now. The temple's water buckets are heavier than they look.",
		"image": "shrine",
		"choices": [
			{"label": "Carry them without complaint", "win": {"Strength": 1, "Karma": 1}},
			{"label": "Work out how to carry two at once", "stat": "Smarts", "difficulty": 50,
				"win": {"Smarts": 4}, "win_text": "A pole across the shoulders. The novices start copying you.",
				"lose": {"Health": -5}, "lose_text": "Both buckets land on your feet."},
			{"label": "Hide in the bell tower", "win": {"Happiness": 5, "Caretaker": -3}},
		],
	},
]

# Extra childhood scenarios for orphans. Scenarios about a mother or father
# are left out automatically for anyone who has none.
const ORPHAN_SCENARIOS = [
	{
		"text": "The caretaker ladles out the evening porridge. Yours is the smallest bowl again.",
		"image": "shrine", "min_age": 2, "max_age": 5, "needs": {"background": ["Orphan"]},
		"choices": [
			{"label": "Eat slowly and make it last", "win": {"Willpower": 3}},
			{"label": "Steal a spoonful from the next bowl", "stat": "Agility", "difficulty": 12,
				"win": {"Health": 4, "Karma": -1},
				"lose": {"Caretaker": -3, "Happiness": -3}, "lose_text": "The spoon is rapped smartly across your knuckles."},
			{"label": "Give half to the smaller child beside you", "win": {"Karma": 2, "Health": -2}},
		],
	},
	{
		"text": "On festival day the village children walk past the temple gate, holding their parents' hands.",
		"image": "shrine", "min_age": 2, "max_age": 5, "needs": {"background": ["Orphan"]},
		"choices": [
			{"label": "Watch until they are gone", "win": {"Happiness": -4, "Willpower": 3}},
			{"label": "Ask the caretaker where your own are", "win": {"Caretaker": 3},
				"win_text": "She is quiet for a long time. Then she gives you a sweet instead of an answer."},
			{"label": "Throw a pine cone at them", "win": {"Happiness": 2, "Karma": -1}},
		],
	},
	{
		"text": "A monk is copying sutras by lamplight. He does not send you away.",
		"image": "shrine", "min_age": 1, "max_age": 5, "needs": {"background": ["Orphan"]},
		"choices": [
			{"label": "Watch his brush", "win": {"Smarts": 2}},
			{"label": "Fall asleep against his knee", "win": {"Health": 4, "Happiness": 2}},
			{"label": "Tip the ink over", "win": {"Happiness": 3, "Karma": -1},
				"win_text": "He looks at the black sutra, then at you, and begins again from the first line."},
		],
	},
	{
		"text": "The temple bell is rung at dawn. Today a novice lets you hold the rope.",
		"image": "shrine", "min_age": 2, "max_age": 5, "needs": {"background": ["Orphan"]},
		"choices": [
			{"label": "Pull with your whole weight", "stat": "Strength", "difficulty": 12,
				"win": {"Happiness": 5}, "win_text": "The bell answers. The whole valley hears you.",
				"lose": {"Happiness": -2}, "lose_text": "The rope lifts you off your feet instead."},
			{"label": "Listen with your hand on the bronze", "win": {"Qi": 3},
				"win_text": "The hum goes all the way through you."},
		],
	},
	{
		"text": "A beggar child your own age is caught stealing from the offering bowl.",
		"image": "shrine", "min_age": 3, "max_age": 5, "needs": {"background": ["Orphan"]},
		"choices": [
			{"label": "Hide them behind the altar", "percent": 60, "meet": "Friend",
				"win": {"Karma": 1},
				"lose": {"Caretaker": -3}, "lose_text": "The caretaker finds you both. You scrub the steps together."},
			{"label": "Share your rice ball with them", "win": {"Karma": 2}},
			{"label": "Fetch the caretaker", "win": {"Caretaker": 2}},
		],
	},
	{
		"text": "Winter. The temple has one blanket for every two children.",
		"image": "shrine", "min_age": 0, "max_age": 5, "needs": {"background": ["Orphan"]},
		"choices": [
			{"label": "Curl up with the others", "win": {"Health": 3, "Happiness": 2}},
			{"label": "Give yours to the coughing baby", "win": {"Karma": 2, "Willpower": 2, "Health": -4}},
			{"label": "Pull it all to your side", "win": {"Health": 4, "Karma": -1}},
		],
	},
]
