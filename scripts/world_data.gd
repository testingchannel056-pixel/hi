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
		"mission": {"fight": "bandit", "image": "mountain", "win": {"Reputation": 6, "Karma": 3, "Gold": 15},
			"text": "The sect sends you to clear bandits from a mountain pass."},
	},
	"Unorthodox": {
		"name": "The Unorthodox Faction",
		"values": "Strength and Merit",
		"mission": {"fight": "duelist", "image": "forest", "win": {"Merit": 10, "Gold": 20, "Karma": -4},
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
	"Beggars' Union": {"faction": "Orthodox", "trains": "Agility",
		"text": "A cracked bowl, a stick, and ten thousand brothers with ears in every city under heaven."},
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
# In a fight each enemy is drawn with the picture of the same name in
# assets/fighters: "wolf" uses wolf.svg (or wolf.png if you add one). An
# enemy without a picture of its own is drawn as person.svg.
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
# Childhood: your first choice, and one milestone on each early birthday
# ---------------------------------------------------------------------------

# These use the same format as ENCOUNTERS below.

# The very first page of a life.
const BIRTH = {
	"text": "The midwife lifts you into the lamplight. The whole household holds its breath.",
	"choices": [
		{"label": "Wail loud enough to wake the village", "win": {"Strength": 1},
			"win_text": "\"Lungs like a war drum,\" your father laughs."},
		{"label": "Stare quietly at every face", "win": {"Martial Insight": 1},
			"win_text": "The midwife shivers. \"This one is already thinking.\""},
		{"label": "Grab your mother's finger", "win": {"Mother": 5, "Happiness": 5},
			"win_text": "She laughs through her tears and holds you close."},
	],
}

# The first one happens on your 1st birthday, the second on your 2nd...
const CHILDHOOD = [
	{
		"text": "You pull yourself up on the edge of the well and take your first wobbly steps.",
		"image": "home",
		"choices": [
			{"label": "Totter towards your mother", "win": {"Mother": 6, "Happiness": 4},
				"win_text": "She catches you just before you fall."},
			{"label": "Totter towards your father", "win": {"Father": 6, "Happiness": 4},
				"win_text": "He swings you up onto his shoulders."},
			{"label": "Chase the chickens", "stat": "Agility", "difficulty": 12,
				"win": {"Agility": 1}, "win_text": "You come back holding a tail feather.",
				"lose": {"Health": -5}, "lose_text": "The rooster wins this round."},
		],
	},
	{
		"text": "Your first word is on the tip of your tongue. The whole family leans in.",
		"image": "home",
		"choices": [
			{"label": "\"Mama\"", "win": {"Mother": 8},
				"win_text": "Your mother tells the whole village before sunset."},
			{"label": "\"Papa\"", "win": {"Father": 8},
				"win_text": "Your father pretends he has something in his eye."},
			{"label": "\"Sword\"", "win": {"Martial Insight": 1, "Father": 3},
				"win_text": "Your parents stare at each other. Your father looks rather proud."},
		],
	},
	{
		"text": "A wandering swordsman drinks at the village well. His scabbard hangs right at your eye level.",
		"image": "village",
		"choices": [
			{"label": "Tug on the scabbard", "percent": 50,
				"win": {"Martial Insight": 1, "Happiness": 5},
				"win_text": "He laughs and lets you hold the hilt for one breath.",
				"lose": {"Happiness": -5, "Mother": -3},
				"lose_text": "Your mother drags you away by the ear, apologising."},
			{"label": "Ask him for a story", "win": {"Smarts": 3, "Happiness": 3},
				"win_text": "He tells you of a man who cut a waterfall in two."},
			{"label": "Hide behind your mother", "win": {"Mother": 3}},
		],
	},
	{
		"text": "Your father whittles you a wooden sword for your birthday.",
		"image": "home",
		"choices": [
			{"label": "Swing it until your arms ache", "win": {"Strength": 1, "Father": 4}},
			{"label": "Copy the stances you saw the swordsman use", "stat": "Martial Insight", "difficulty": 13,
				"win": {"Martial Insight": 1}, "win_text": "For a moment the sword feels like part of your arm.",
				"lose": {}, "lose_text": "You mostly hit yourself."},
			{"label": "Trade it for sweets", "win": {"Happiness": 8, "Father": -5},
				"win_text": "The sweets are gone by evening. So is your father's smile."},
		],
	},
	{
		"text": "You are old enough for chores now. The water buckets are heavier than they look.",
		"image": "village",
		"choices": [
			{"label": "Carry them without complaint", "win": {"Strength": 1, "Karma": 1}},
			{"label": "Work out how to carry two at once", "stat": "Smarts", "difficulty": 50,
				"win": {"Smarts": 4}, "win_text": "A pole across the shoulders. The neighbours start copying you.",
				"lose": {"Health": -5}, "lose_text": "Both buckets land on your feet."},
			{"label": "Hide in the hayloft", "win": {"Happiness": 5, "Father": -3}},
		],
	},
]

# ---------------------------------------------------------------------------
# Encounters: scenarios with choices
# ---------------------------------------------------------------------------

# To write your own, use scripts/my_scenarios.gd. It has templates to copy and
# explains every word below.
#
# A choice with "stat" rolls dice + that stat against "difficulty".
#   Strength, Agility, Martial Insight: 10 is easy, 14 normal, 18 hard.
#   Smarts, Looks, Happiness: 30 is easy, 50 normal, 70 hard.
# A choice with "percent" succeeds that often, whatever your stats are.
# A choice with "fight" starts a battle against that enemy.
# A choice with "friendly" is a duel that stops before anyone dies.
# A choice with none of these always succeeds.
# A choice with "meet" adds that person to your relationships on success.
# A choice with "item" puts that item (see ITEMS) in your inventory on success.
# "win" and "lose" can change any of these:
#   Health, Qi, Qi Capacity, Strength, Agility, Martial Insight,
#   Happiness, Smarts, Looks, Karma, Reputation, Merit, Gold
#   and your bond with Mother, Father, Friend, Rival or Master.
# "win_text" and "lose_text" are a sentence about how the choice turned out.
# An encounter with "min_age" only shows up once you are that old. Without
#   it, the encounter waits until you are 6.
# An encounter with "max_age" stops showing up once you are older than that.
# An encounter with "faction" only shows up for members of that faction.
# An encounter's "image" is the picture shown above it: res://assets/scenes/<image>.svg
# An encounter with "unique" is rare and happens at most once in a life.
const ENCOUNTERS = [
	# --- Early childhood (birth to age 5) ---
	{
		"text": "You discover that you have feet.",
		"image": "home", "min_age": 0, "max_age": 1,
		"choices": [
			{"label": "Put one in your mouth", "win": {"Happiness": 2}, "win_text": "Delicious."},
			{"label": "Kick the blanket off", "percent": 60,
				"win": {"Happiness": 4}, "win_text": "It sails clean out of the cradle.",
				"lose": {}, "lose_text": "The blanket wins."},
		],
	},
	{
		"text": "A cricket lands on the edge of your cradle.",
		"image": "home", "min_age": 0, "max_age": 1,
		"choices": [
			{"label": "Grab it", "percent": 50,
				"win": {"Happiness": 4}, "win_text": "It sings in your fist until you let it go.",
				"lose": {"Happiness": -3}, "lose_text": "It hops away and you howl."},
			{"label": "Watch it", "win": {"Smarts": 2},
				"win_text": "You watch it clean each leg in turn."},
		],
	},
	{
		"text": "Your father's sword leans against the wall, just within crawling distance.",
		"image": "home", "min_age": 0, "max_age": 1,
		"choices": [
			{"label": "Crawl for it", "percent": 40,
				"win": {"Qi": 3, "Happiness": 3}, "win_text": "You pat the scabbard, and something in you hums.",
				"lose": {"Father": -2, "Happiness": -3}, "lose_text": "Your father scoops you up halfway there."},
			{"label": "Chew on your blanket instead", "win": {"Happiness": 2}},
		],
	},
	{
		"text": "The whole family crowds around the cradle to argue about who you look like.",
		"image": "home", "min_age": 0, "max_age": 1,
		"choices": [
			{"label": "Smile at your mother", "win": {"Mother": 4}},
			{"label": "Smile at your father", "win": {"Father": 4}},
			{"label": "Sneeze on everyone", "win": {"Happiness": 2},
				"win_text": "The argument ends at once."},
		],
	},
	{
		"text": "Your first tooth is coming in, and it hurts.",
		"image": "home", "min_age": 0, "max_age": 1,
		"choices": [
			{"label": "Chew on your father's sword tassel", "win": {"Father": 2, "Happiness": 2},
				"win_text": "He pretends not to notice."},
			{"label": "Scream all night", "win": {"Mother": -2, "Father": -2, "Health": 3}},
			{"label": "Bear it quietly", "win": {"Karma": 1},
				"win_text": "Your mother tells the neighbours you are the most patient baby in the province."},
		],
	},
	{
		"text": "Your mother hums a lullaby while she mends clothes.",
		"image": "home", "min_age": 0, "max_age": 2,
		"choices": [
			{"label": "Hum along", "win": {"Mother": 4, "Happiness": 1},
				"win_text": "You are badly out of tune. She does not mind."},
			{"label": "Fall asleep", "win": {"Health": 5}},
			{"label": "Cry until she picks you up", "win": {"Happiness": 2, "Mother": -2}},
		],
	},
	{
		"text": "Your mother carries you to the market on her back.",
		"image": "village", "min_age": 0, "max_age": 2,
		"choices": [
			{"label": "Stare at everything", "win": {"Smarts": 2}},
			{"label": "Sleep through it", "win": {"Health": 3}},
			{"label": "Grab a pear from a stall", "percent": 50,
				"win": {"Happiness": 4}, "win_text": "The pear seller laughs and lets you keep it.",
				"lose": {"Mother": -2}, "lose_text": "Your mother apologises and puts it back."},
		],
	},
	{
		"text": "The village healer holds out a spoon of bitter medicine. \"It will make the child strong.\"",
		"image": "village", "min_age": 0, "max_age": 3,
		"choices": [
			{"label": "Swallow it", "win": {"Health": 8, "Happiness": -3}},
			{"label": "Spit it at the healer", "win": {"Happiness": 3, "Karma": -1},
				"win_text": "He wipes his beard and says nothing at all."},
		],
	},
	{
		"text": "A stray dog wanders into the courtyard and sniffs your toes.",
		"image": "home", "min_age": 1, "max_age": 4,
		"choices": [
			{"label": "Pat its nose", "percent": 70,
				"win": {"Happiness": 5}, "win_text": "It licks your whole face.",
				"lose": {"Health": -6, "Happiness": -3}, "lose_text": "It nips your hand and bolts."},
			{"label": "Share your rice ball", "win": {"Karma": 1, "Happiness": 1}},
			{"label": "Scream for your father", "win": {"Father": 2}},
		],
	},
	{
		"text": "The house cat has had kittens under the porch.",
		"image": "home", "min_age": 1, "max_age": 5,
		"choices": [
			{"label": "Play with them all afternoon", "percent": 75,
				"win": {"Happiness": 5},
				"lose": {"Health": -3, "Happiness": -2}, "lose_text": "Their mother does not approve. You come away scratched."},
			{"label": "Bring them a saucer of milk", "win": {"Karma": 1, "Happiness": 1}},
		],
	},
	{
		"text": "Thunder shakes the house in the middle of the night.",
		"image": "home", "min_age": 1, "max_age": 5,
		"choices": [
			{"label": "Crawl into your parents' bed", "win": {"Mother": 3, "Father": 3}},
			{"label": "Hide under the blanket", "win": {"Happiness": -3}},
			{"label": "Watch the lightning from the window", "stat": "Martial Insight", "difficulty": 14,
				"win": {"Qi": 4}, "win_text": "For a heartbeat you feel the storm breathing.",
				"lose": {"Happiness": -4}, "lose_text": "The next thunderclap sends you diving under the bed."},
		],
	},
	{
		"text": "You find your father's ink stone and a clean white wall.",
		"image": "home", "min_age": 2, "max_age": 4,
		"choices": [
			{"label": "Paint a tiger on the wall", "win": {"Smarts": 2, "Happiness": 3, "Father": -4},
				"win_text": "Your father sighs for a long time. It does look a little like a tiger."},
			{"label": "Paint yourself instead", "win": {"Happiness": 4, "Looks": -2, "Mother": -2},
				"win_text": "It takes three baths to get you clean."},
			{"label": "Put the ink stone back", "win": {"Karma": 1, "Father": 2}},
		],
	},
	{
		"text": "The neighbour's boy snatches your rattle drum.",
		"image": "village", "min_age": 2, "max_age": 5,
		"choices": [
			{"label": "Snatch it back", "stat": "Strength", "difficulty": 12,
				"win": {"Happiness": 4},
				"lose": {"Health": -4, "Happiness": -4}, "lose_text": "He shoves you into the mud and runs."},
			{"label": "Cry until the adults come", "win": {"Mother": 2, "Happiness": -2}},
			{"label": "Let him keep it", "win": {"Karma": 2, "Happiness": -3}},
		],
	},
	{
		"text": "The sweet seller's cart rattles into the village.",
		"image": "village", "min_age": 2, "max_age": 5,
		"choices": [
			{"label": "Beg your mother for candied hawthorn", "stat": "Looks", "difficulty": 50,
				"win": {"Happiness": 5}, "win_text": "Nobody can say no to that face.",
				"lose": {"Happiness": -3}, "lose_text": "\"Not before dinner.\""},
			{"label": "Swipe one while he is not looking", "stat": "Agility", "difficulty": 13,
				"win": {"Happiness": 5, "Karma": -2},
				"lose": {"Karma": -2, "Mother": -4, "Happiness": -4},
				"lose_text": "He catches your wrist. Your mother pays, red-faced."},
			{"label": "Just breathe in the smell", "win": {"Karma": 1}},
		],
	},
	{
		"text": "A visiting uncle presses a few coins into your hands.",
		"image": "home", "min_age": 2, "max_age": 5,
		"choices": [
			{"label": "Hide the coins in your shoe", "win": {"Gold": 2}},
			{"label": "Buy sweets for the other children", "win": {"Karma": 1, "Happiness": 2}},
			{"label": "Hand them to your mother", "win": {"Mother": 4, "Gold": 1},
				"win_text": "She gives one coin back and winks."},
		],
	},
	{
		"text": "A pedlar sets up a shadow-puppet play for the village children.",
		"image": "village", "min_age": 2, "max_age": 5,
		"choices": [
			{"label": "Watch every moment", "win": {"Happiness": 2}},
			{"label": "Sneak behind the screen to see how it works", "stat": "Smarts", "difficulty": 45,
				"win": {"Smarts": 3}, "win_text": "Sticks and paper. You are thrilled anyway.",
				"lose": {"Happiness": -2}, "lose_text": "The pedlar shoos you out before you see a thing."},
		],
	},
	{
		"text": "It snows for the first time you can remember.",
		"image": "mountain", "min_age": 2, "max_age": 5,
		"choices": [
			{"label": "Build a snow tiger", "win": {"Happiness": 2, "Smarts": 1}},
			{"label": "Start a snowball war", "win": {"Happiness": 3, "Health": -3}},
			{"label": "Eat the snow", "percent": 60,
				"win": {"Happiness": 2}, "win_text": "It tastes of nothing. You eat more.",
				"lose": {"Health": -6}, "lose_text": "You spend the week in bed with a cold."},
		],
	},
	{
		"text": "Your mother catches you with your hand in the honey jar.",
		"image": "home", "min_age": 2, "max_age": 5,
		"choices": [
			{"label": "Confess", "win": {"Karma": 1, "Mother": 2}},
			{"label": "Blame the cat", "stat": "Smarts", "difficulty": 55,
				"win": {"Smarts": 2, "Karma": -1}, "win_text": "The cat is put outside. It glares at you through the door.",
				"lose": {"Mother": -4, "Karma": -1}, "lose_text": "The honey on your chin gives you away."},
			{"label": "Offer her some", "stat": "Looks", "difficulty": 50,
				"win": {"Mother": 3, "Happiness": 3}, "win_text": "She tries to stay stern, and fails.",
				"lose": {"Mother": -2}, "lose_text": "She does not think it is funny."},
		],
	},
	{
		"text": "Your mother begins to teach you your letters.",
		"image": "home", "min_age": 3, "max_age": 5,
		"choices": [
			{"label": "Pay attention", "stat": "Smarts", "difficulty": 45,
				"win": {"Smarts": 3, "Mother": 2},
				"lose": {"Smarts": 1}, "lose_text": "The letters swim like tadpoles, but a few stay put."},
			{"label": "Draw swordsmen in the margins", "win": {"Happiness": 3, "Mother": -2}},
		],
	},
	{
		"text": "The village children are playing heroes and demons in the lane.",
		"image": "village", "min_age": 3, "max_age": 5,
		"choices": [
			{"label": "Be the hero", "meet": "Friend", "win": {"Happiness": 2, "Karma": 1}},
			{"label": "Be the demon lord", "win": {"Happiness": 3, "Karma": -1},
				"win_text": "Your evil laugh is the best in the village."},
			{"label": "Settle the argument about who won", "win": {"Smarts": 2}},
		],
	},
	{
		"text": "Sect disciples drill in the village square, their sleeves snapping in the wind.",
		"image": "village", "min_age": 3, "max_age": 5,
		"choices": [
			{"label": "Copy their stances", "stat": "Agility", "difficulty": 13,
				"win": {"Qi": 3, "Happiness": 3}, "win_text": "A disciple corrects your elbow and nods.",
				"lose": {"Happiness": -2}, "lose_text": "You fall over. One of the disciples hides a smile."},
			{"label": "Count their strikes", "win": {"Smarts": 2}},
			{"label": "Ask to hold a sword", "percent": 30,
				"win": {"Happiness": 8}, "win_text": "It is heavier than the sky.",
				"lose": {}, "lose_text": "\"Come back in ten years, little one.\""},
		],
	},
	{
		"text": "You fall out of the persimmon tree.",
		"image": "village", "min_age": 3, "max_age": 5,
		"choices": [
			{"label": "Bite your lip and climb back up", "win": {"Happiness": 3, "Health": -5},
				"win_text": "From the top you can see all the way to the mountains."},
			{"label": "Howl for your mother", "win": {"Mother": 3},
				"win_text": "She kisses your scraped knee and scolds the tree."},
		],
	},
	{
		"text": "You find a baby bird that has fallen from its nest.",
		"image": "forest", "min_age": 3, "max_age": 5,
		"choices": [
			{"label": "Take it home and nurse it", "percent": 50,
				"win": {"Karma": 2, "Happiness": 5}, "win_text": "One morning it flies off the windowsill and does not look back.",
				"lose": {"Karma": 1, "Happiness": -4}, "lose_text": "It does not last the night. You bury it under the plum tree."},
			{"label": "Climb up and put it back", "stat": "Agility", "difficulty": 12,
				"win": {"Karma": 2},
				"lose": {"Health": -5}, "lose_text": "The branch snaps. The bird is fine. You are less fine."},
			{"label": "Leave it be", "win": {}},
		],
	},
	{
		"text": "A travelling monk rests at your gate and looks at you for a long while.",
		"image": "home", "unique": true, "min_age": 0, "max_age": 5,
		"choices": [
			{"label": "Smile at him", "win": {"Qi Capacity": 10, "Karma": 2},
				"win_text": "\"Remarkable bones,\" he murmurs, and presses a thumb to your brow. Something warm settles in your belly."},
			{"label": "Pull his beard", "win": {"Strength": 1, "Happiness": 5},
				"win_text": "He roars with laughter. \"And a remarkable grip!\""},
		],
	},

	# --- From age 6 ---
	{
		"text": "An old beggar offers you a strange pill.",
		"image": "village",
		"choices": [
			{"label": "Eat it", "stat": "Martial Insight", "difficulty": 12,
				"win": {"Qi": 20}, "lose": {"Health": -20}},
			{"label": "Give him your lunch instead", "win": {"Karma": 3}},
		],
	},
	{
		"text": "You find a torn sword manual in the mud.",
		"image": "forest",
		"choices": [
			{"label": "Study it", "stat": "Martial Insight", "difficulty": 13,
				"win": {"Agility": 1, "Martial Insight": 1}, "lose": {}},
			{"label": "Sell it", "win": {"Gold": 8}},
		],
	},
	{
		"text": "A wandering physician sets up a stall in your village.",
		"image": "village",
		"choices": [
			{"label": "Ask for treatment", "item": "Healing Pill", "win": {"Health": 25}},
			{"label": "Ask to be taught", "stat": "Martial Insight", "difficulty": 14,
				"win": {"Martial Insight": 2}, "lose": {}},
		],
	},
	{
		"text": "A stranger about your age shares a rice cake with you.",
		"image": "village",
		"choices": [
			{"label": "Share your food in return", "meet": "Friend", "win": {"Karma": 2}},
			{"label": "Eat it and run", "win": {"Strength": 1, "Karma": -2}},
		],
	},
	{
		"text": "You find a quiet waterfall, thick with spiritual energy.",
		"image": "waterfall",
		"choices": [
			{"label": "Meditate beneath it", "stat": "Martial Insight", "difficulty": 12,
				"win": {"Qi": 15}, "lose": {"Health": -10}},
			{"label": "Train in the current", "win": {"Strength": 1}},
		],
	},
	{
		"text": "A sect elder is testing children at the market square.",
		"image": "village",
		"choices": [
			{"label": "Step forward", "stat": "Agility", "difficulty": 13, "meet": "Master",
				"win": {"Qi": 10, "Martial Insight": 1}, "lose": {}},
			{"label": "Watch from the crowd", "win": {"Martial Insight": 1}},
		],
	},
	{
		"text": "A glowing herb grows on a cliff edge, just out of reach.",
		"image": "mountain",
		"choices": [
			{"label": "Climb for it", "stat": "Agility", "difficulty": 13, "item": "Spirit Herb",
				"win": {"Qi": 10}, "lose": {"Health": -25}},
			{"label": "Leave it be", "win": {"Health": 5}},
		],
	},
	{
		"text": "Starving refugees line the road, holding out empty bowls.",
		"image": "mountain",
		"choices": [
			{"label": "Give them your coin", "win": {"Gold": -10, "Karma": 6, "Reputation": 2}},
			{"label": "Walk on", "win": {"Karma": -1}},
		],
	},
	{
		"text": "A hungry wolf stalks you on the forest path.",
		"image": "forest",
		"min_age": 10,
		"choices": [
			{"label": "Stand your ground", "fight": "wolf", "win": {"Strength": 1}},
			{"label": "Climb a tree and wait", "stat": "Agility", "difficulty": 10,
				"win": {}, "lose": {"Health": -15}},
		],
	},
	{
		"text": "Bandits leap from the roadside brush. \"Your coin or your life!\"",
		"image": "mountain",
		"min_age": 12,
		"choices": [
			{"label": "Fight them", "fight": "bandit", "item": "Wine Gourd",
				"win": {"Gold": 15, "Reputation": 3, "Karma": 2}},
			{"label": "Hand over your purse", "win": {"Gold": -15}},
			{"label": "Run for it", "stat": "Agility", "difficulty": 12,
				"win": {}, "lose": {"Health": -15, "Gold": -5}},
		],
	},
	{
		"text": "Behind a collapsed shrine wall you find an ancient manual sealed in oilcloth.",
		"image": "shrine",
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
		"image": "tavern",
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
		"image": "forest",
		"min_age": 14,
		"choices": [
			{"label": "Hide him", "stat": "Agility", "difficulty": 12,
				"win": {"Karma": 6, "Reputation": 4}, "lose": {"Health": -15, "Karma": 2}},
			{"label": "Rob him", "win": {"Gold": 20, "Karma": -10, "Merit": 5}},
		],
	},
	{
		"text": "A merchant caravan is hiring guards for the mountain road.",
		"image": "mountain",
		"min_age": 14,
		"choices": [
			{"label": "Guard it", "fight": "bandit", "win": {"Gold": 30, "Reputation": 4}},
			{"label": "Rob it yourself", "fight": "duelist", "win": {"Gold": 50, "Karma": -12, "Merit": 8}},
			{"label": "Pass by", "win": {}},
		],
	},
	{
		"text": "A demonic cultist is draining the life from a village.",
		"image": "fire",
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
		"image": "cave",
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
		"image": "fire",
		"min_age": 14, "faction": "Orthodox",
		"choices": [
			{"label": "Join the vanguard", "fight": "cultist", "win": {"Reputation": 12, "Karma": 4}},
			{"label": "Guard the wounded", "win": {"Karma": 3, "Reputation": 2}},
			{"label": "Stay behind", "win": {"Reputation": -3}},
		],
	},
	{
		"text": "A senior cultist sneers that your rank should be his.",
		"image": "cave",
		"min_age": 14, "faction": "Unorthodox",
		"choices": [
			{"label": "Break him", "fight": "initiate", "win": {"Merit": 15}},
			{"label": "Yield your place", "win": {"Merit": -10}},
		],
	},
	{
		"text": "The cult orders you to burn a village that refused tribute.",
		"image": "fire",
		"min_age": 14, "faction": "Unorthodox",
		"choices": [
			{"label": "Obey", "win": {"Merit": 15, "Gold": 15, "Karma": -15}},
			{"label": "Warn the villagers first", "stat": "Agility", "difficulty": 13,
				"win": {"Karma": 8}, "lose": {"Merit": -10, "Health": -15}},
		],
	},

	# --- Once-in-a-lifetime encounters ("unique": each can happen only once) ---
	{
		"text": "A comet burns across the sky. The old folk whisper that it is your star.",
		"image": "home", "unique": true,
		"choices": [
			{"label": "Wish for strength", "win": {"Strength": 2}},
			{"label": "Wish for wisdom", "win": {"Martial Insight": 2, "Smarts": 5}},
			{"label": "Wish for joy", "win": {"Happiness": 25}},
		],
	},
	{
		"text": "A veiled stranger offers you a pill said to reshape the body.",
		"image": "village", "unique": true, "min_age": 10,
		"choices": [
			{"label": "Swallow it", "percent": 50,
				"win": {"Strength": 3, "Agility": 3, "Looks": 10}, "lose": {"Health": -35, "Looks": -10}},
			{"label": "Decline", "win": {"Karma": 1}},
		],
	},
	{
		"text": "Lightning splits an ancient tree and reveals a sword humming in its heart.",
		"image": "forest", "unique": true, "min_age": 12,
		"choices": [
			{"label": "Draw the sword", "stat": "Strength", "difficulty": 14,
				"win": {"Strength": 3, "Reputation": 10}, "lose": {"Health": -20}},
			{"label": "Leave it for a worthier hand", "win": {"Karma": 5}},
		],
	},
	{
		"text": "You wander into a valley no map shows, where peach trees bloom out of season.",
		"image": "waterfall", "unique": true, "min_age": 12,
		"choices": [
			{"label": "Stay a while", "win": {"Health": 40, "Happiness": 15, "Qi": 40}},
			{"label": "Mark the path and leave", "item": "Spirit Herb", "win": {"Qi Capacity": 20}},
		],
	},
	{
		"text": "A dying hermit grips your wrist. \"I have no heir. Take sixty years of my cultivation.\"",
		"image": "cave", "unique": true, "min_age": 14,
		"choices": [
			{"label": "Accept his gift", "stat": "Martial Insight", "difficulty": 14,
				"win": {"Qi": 80, "Qi Capacity": 30, "Martial Insight": 2}, "lose": {"Health": -30, "Qi": 30}},
			{"label": "Refuse, and ease his passing", "win": {"Karma": 10, "Happiness": 5}},
		],
	},
	{
		"text": "The Alliance announces a tournament held once in a generation.",
		"image": "sect", "unique": true, "min_age": 16,
		"choices": [
			{"label": "Enter the lists", "fight": "duelist", "friendly": true,
				"win": {"Reputation": 30, "Gold": 100, "Happiness": 10}},
			{"label": "Watch from the stands", "win": {"Martial Insight": 2}},
		],
	},
]

# ---------------------------------------------------------------------------
# Happenings: small things in an ordinary month (no choices, just a result)
# ---------------------------------------------------------------------------

# "min_age" and "max_age" work as they do for encounters.

const HAPPENINGS = [
	{"text": "A quiet month. You keep to your routine.", "image": "home"},
	{"text": "You help a neighbour mend a roof and are paid in coin.", "image": "village",
		"win": {"Gold": 4, "Karma": 1}},
	{"text": "A travelling storyteller fills the square. You laugh until your sides hurt.", "image": "village",
		"win": {"Happiness": 6}},
	{"text": "A fever keeps you in bed for a week.", "image": "home",
		"win": {"Health": -8, "Happiness": -3}},
	{"text": "You find a coin purse in the road and no one to claim it.", "image": "mountain",
		"win": {"Gold": 8}},
	{"text": "Rain falls all month. You brood by the window.", "image": "home",
		"win": {"Happiness": -4}},
	{"text": "A festival fills the streets with lanterns.", "image": "village",
		"win": {"Happiness": 8, "Gold": -2}},
	{"text": "A pickpocket lightens your purse.", "image": "village",
		"win": {"Gold": -6}},
	{"text": "You sleep under the stars and wake with your mind clear.", "image": "mountain",
		"win": {"Qi": 5, "Happiness": 2}},
	{"text": "You share a meal with a lonely old soldier.", "image": "tavern",
		"win": {"Karma": 2, "Happiness": 3}},
	{"text": "You watch two masters spar on a bridge and learn from every exchange.", "image": "waterfall",
		"min_age": 8, "win": {"Martial Insight": 1}},
	{"text": "You carry grain sacks for the miller all month.", "image": "village",
		"min_age": 10, "win": {"Strength": 1, "Gold": 3}},
	{"text": "You chase a thief across the rooftops and catch him.", "image": "village",
		"min_age": 12, "win": {"Agility": 1, "Reputation": 2}},
	{"text": "Gossip about you spreads through the tea houses.", "image": "tavern",
		"min_age": 12, "win": {"Reputation": 2}},

	# --- Early childhood (birth to age 5) ---
	{"text": "You nap in a patch of sunlight.", "image": "home", "min_age": 0, "max_age": 5},
	{"text": "Your mother sings while she works.", "image": "home", "min_age": 0, "max_age": 5,
		"win": {"Happiness": 1}},
	{"text": "Your father lifts you onto his shoulders to see the market.", "image": "village",
		"min_age": 0, "max_age": 5, "win": {"Happiness": 1}},
	{"text": "A fever keeps the whole house awake for three nights.", "image": "home",
		"min_age": 0, "max_age": 5, "win": {"Health": -6, "Happiness": -3}},
	{"text": "A bad dream wakes you, and the dark takes a long time to go away.", "image": "home",
		"min_age": 0, "max_age": 5, "win": {"Happiness": -3}},
	{"text": "You toddle after the chickens.", "image": "home", "min_age": 1, "max_age": 5},
	{"text": "You stack pebbles into wobbly towers.", "image": "home", "min_age": 1, "max_age": 5},
	{"text": "You scrape both knees on the courtyard stones.", "image": "home",
		"min_age": 1, "max_age": 5, "win": {"Health": -3, "Happiness": -2}},
	{"text": "You hide behind the rice jars until someone finds you.", "image": "home",
		"min_age": 2, "max_age": 5},
	{"text": "Your parents argue in low voices after they think you are asleep.", "image": "home",
		"min_age": 2, "max_age": 5, "win": {"Happiness": -4}},
]

# ---------------------------------------------------------------------------
# Talents: chosen on the New Life screen
# ---------------------------------------------------------------------------

# "train" and "train_bonus" make one stat easier to train.
# "max_health" adds to your Max Health. "qi_bonus" 0.3 means 30% more Qi from
# cultivation. "bond_bonus" is added every time a bond grows. "lucky" means
# you never draw the worst fortune stick.
const TALENTS = {
	"None": {"text": "No gift at all. Everything must be earned."},
	"Iron Body": {"text": "Strength training is easier. Max Health +20.",
		"train": "Strength", "train_bonus": 15, "max_health": 20},
	"Wind Step": {"text": "Agility training is easier.",
		"train": "Agility", "train_bonus": 15},
	"Scholar's Mind": {"text": "Martial Insight training is easier.",
		"train": "Martial Insight", "train_bonus": 15},
	"Heavenly Meridians": {"text": "Cultivation gathers 30% more Qi.",
		"qi_bonus": 0.3},
	"Silver Tongue": {"text": "Bonds with people grow faster.",
		"bond_bonus": 6},
	"Fortune's Favourite": {"text": "You never draw the worst fortune stick. Pure-luck choices succeed 5% more often.",
		"lucky": true, "luck": 5},
}

# ---------------------------------------------------------------------------
# Items: carried in your inventory, bought at the Market or found on the road
# ---------------------------------------------------------------------------

# "use" is what happens when you use one (same format as "win").
# "price" is what the Market charges for it.
const ITEMS = {
	"Healing Pill": {"text": "Restores 30 Health.", "use": {"Health": 30}, "price": 15},
	"Qi Pill": {"text": "Restores 25 Qi.", "use": {"Qi": 25}, "price": 25},
	"Spirit Herb": {"text": "Restores 15 Health and 10 Qi.", "use": {"Health": 15, "Qi": 10}, "price": 20},
	"Wine Gourd": {"text": "Raises Happiness by 15.", "use": {"Happiness": 15}, "price": 6},
	"Fine Robe": {"text": "Raises Looks by 5.", "use": {"Looks": 5}, "price": 30},
	"Martial Manual": {"text": "Raises Martial Insight by 1.", "use": {"Martial Insight": 1}, "price": 60},
}

# ---------------------------------------------------------------------------
# Activities: things you can choose to do each month
# ---------------------------------------------------------------------------

# Same format as encounter choices. "train" means the roll gets harder the
# closer that stat is to its cap. "cultivate" is the Cultivate action.
# An activity with a "fight" can name the "image" the fight takes place in.
# "menu" is the group of More the activity is listed in: Life, Martial or
# Jianghu ("Life" if it is left out).
const ACTIVITIES = [
	{"label": "Rest", "menu": "Life", "win": {"Health": 30, "Happiness": 5},
		"text": "You rest, eat well and tend your wounds."},
	# "work" is the Work action: what it pays depends on your life path.
	{"label": "Work", "menu": "Life", "min_age": 10, "work": true},
	{"label": "Study the classics", "menu": "Life", "win": {"Smarts": 2},
		"text": "You copy out the classics until the candle gutters."},
	{"label": "Steady your mind", "menu": "Life", "min_age": 10, "win": {"Willpower": 3},
		"text": "You sit by the river at dawn and count your breaths until the counting stops."},
	{"label": "Tend your appearance", "menu": "Life", "min_age": 10, "win": {"Looks": 2, "Gold": -2},
		"text": "You visit the bathhouse, the barber and the tailor."},
	{"label": "Cultivate", "menu": "Martial", "cultivate": true,
		"text": "You sit cross-legged and circulate your Qi through the meridians."},
	{"label": "Train strength", "menu": "Martial",
		"train": "Strength", "win": {"Strength": 1}, "lose": {"Health": -5},
		"text": "You strike the wooden post until dusk."},
	{"label": "Train agility", "menu": "Martial",
		"train": "Agility", "win": {"Agility": 1}, "lose": {"Health": -5},
		"text": "You run the plum-blossom poles until your legs shake."},
	{"label": "Study martial arts", "menu": "Martial",
		"train": "Martial Insight", "win": {"Martial Insight": 1}, "lose": {},
		"text": "You study forms and manuals by candlelight."},
	# "adventure" is the Seek adventure action: a scenario happens this month.
	{"label": "Seek adventure", "menu": "Jianghu", "min_age": 10, "adventure": true},
	{"label": "Visit a tea house", "menu": "Jianghu", "min_age": 10, "win": {"Happiness": 12, "Gold": -3},
		"text": "You spend an afternoon over tea, music and idle talk."},
	{"label": "Hunt", "menu": "Jianghu", "min_age": 12, "fight": "random", "image": "forest", "win": {"Reputation": 2, "Gold": 5},
		"text": "You wander the wilds looking for trouble."},
]

# ---------------------------------------------------------------------------
# People in your life. "guidance" is what they can teach you.
# ---------------------------------------------------------------------------

# "power" is how strong they are when you spar.
# "family" marks family members. "surname" gives them your family name.
# "most" is how many you can have at one time (1 if it is left out).
# "fade" is how much the bond fades each year you ignore them (3 if left out).
# "gender" fixes it; otherwise it is random.
const ROLES = {
	"Father": {"guidance": {"Strength": 1}, "train": "Strength", "power": 1.2,
		"family": true, "surname": true, "gender": "Male", "fade": 1},
	"Mother": {"guidance": {"Martial Insight": 1}, "train": "Martial Insight", "power": 1.0,
		"family": true, "gender": "Female", "fade": 1},
	"Caretaker": {"guidance": {"Willpower": 2}, "power": 0.8, "family": true, "gender": "Female", "fade": 1},
	"Sibling": {"guidance": {"Agility": 1}, "train": "Agility", "power": 1.0,
		"family": true, "surname": true, "most": 4, "fade": 2},
	"Spouse": {"power": 1.0, "family": true, "fade": 2},
	"Partner": {"power": 1.0},
	"Child": {"power": 0.7, "family": true, "surname": true, "most": 6, "fade": 1},
	"Master": {"guidance": {"Qi": 12}, "power": 2.0},
	"Friend": {"guidance": {"Agility": 1}, "train": "Agility", "power": 1.0, "most": 3},
	"Rival": {"guidance": {"Strength": 1}, "train": "Strength", "power": 1.3},
	"Disciple": {"power": 0.8, "most": 3},
	"Acquaintance": {"power": 1.0, "most": 4, "fade": 4},
	"Enemy": {"power": 1.4, "most": 3, "fade": 0},
}
