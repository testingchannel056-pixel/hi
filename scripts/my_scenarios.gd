extends RefCounted

# =============================================================================
#  YOUR OWN SCENARIOS
# =============================================================================
# Every scenario in the SCENARIOS list at the bottom of this file shows up in
# the game, mixed in with the ones that are already there.
#
# HOW TO ADD ONE
#   1. Copy one of the templates below, from its { line to its }, line.
#   2. Paste it at the bottom of this file, above the last ] .
#   3. Select the pasted lines and press Ctrl+K. That removes the # in front
#      of each line and turns them from a note into a real scenario.
#   4. Change the words between the "quotes" and the numbers.
#   5. Press F5. If something is misspelled, the first page of the game tells
#      you which scenario and which choice to look at.
#
# HOW TO TRY IT OUT
#   Change TEST_MY_SCENARIOS below to true. Then only your scenarios appear,
#   one after another, whatever your age. Change it back to false afterwards.

const TEST_MY_SCENARIOS = false

# =============================================================================
#  THE WORDS YOU CAN USE
# =============================================================================
#
# A SCENARIO
#   "text"      what happens                                    (always needed)
#   "choices"   the list of choices, as many as you like        (always needed)
#   "image"     the picture: forest, village, mountain, waterfall, tavern,
#               shrine, fire, cave, sect or home
#   "min_age"   the youngest age it can happen. Without it: 6.
#               Write 0 for something that can happen to a baby.
#   "max_age"   the oldest age it can happen
#   "faction"   "Orthodox" or "Unorthodox": only members of that side see it
#   "unique"    true makes it rare, and it happens only once in a life
#   "title"     a name shown above the text, such as "The Old Beggar"
#   "needs"     what you must have or be for it to happen (see NEEDS below)
#   "weight"    how likely it is next to the others. 3 is three times as likely
#   "id"        a short name of its own, such as "old_beggar". It is needed
#               for "once" and for "goto" (see STORIES below)
#   "once"      true: it never comes back in the same life (needs an "id")
#   "hidden"    true: it never comes by itself, only through a "goto"
#
# A CHOICE
#   "label"      the words on the button                        (always needed)
#   "win"        what changes if it goes well
#   "lose"       what changes if it goes badly
#   "win_text"   a sentence shown if it goes well
#   "lose_text"  a sentence shown if it goes badly
#   "needs"      what you must have to pick it (see NEEDS below). Without it
#                the button is grey and says what is missing
#
#   A choice always goes well, unless you add ONE of these three:
#   "stat" and "difficulty"   a dice roll that your stat helps with
#   "percent"                 pure luck. 50 means it works half the time
#   "fight"                   a battle against: wolf, bandit, initiate,
#                             duelist, cultist or beast (weakest to strongest)
#
#   Extras:
#   "friendly"   true makes the fight a duel that stops before anyone dies
#   "item"       you receive it if it goes well: Healing Pill, Qi Pill,
#                Spirit Herb, Wine Gourd, Fine Robe or Martial Manual
#   "meet"       someone you get to know if it goes well: Friend, Rival, Master
#
# WHAT "win" AND "lose" CAN CHANGE
#   Health, Max Health, Qi, Qi Capacity, Strength, Agility, Martial Insight,
#   Happiness, Smarts, Looks, Willpower, Karma, Reputation, Shame, Merit, Gold
#   Your bond with a person: Mother, Father, Sibling, Spouse, Child, Friend,
#   Rival, Master
#   A plain number adds, a number with a minus takes away:
#       {"Gold": 10, "Karma": -3, "Mother": 5}
#
# WHICH "stat" AND HOW DIFFICULT
#   Strength, Agility, Martial Insight:        10 easy  ·  14 normal  ·  18 hard
#   Smarts, Looks, Happiness, Willpower:       30 easy  ·  50 normal  ·  70 hard
#   The game shows the player how hard it is under the button.
#
# NEEDS
#   A list of what is asked for, between { and }. A few examples:
#       {"age": 16}                         at least 16 years old
#       {"Gold": 20, "Smarts": 55}          at least this much of each
#       {"stage": 1}                        at least the Third-Class stage
#       {"path": ["Scholar", "Teacher"]}    one of these life paths
#       {"background": ["Orphan"]}          one of these backgrounds
#       {"sect": ["Wudang"]}                a member of one of these sects
#       {"relation": ["Master"]}            this person is in your life
#       {"item": ["Fine Robe"]}             you carry this
#       {"flag": ["helped_beggar"]}         this has happened (see STORIES)
#       {"not_flag": ["helped_beggar"]}     this has not happened
#   The full list is at the top of scripts/requirements.gd.
#
# STORIES: scenarios that remember and follow each other
#   Inside "win" or "lose" you can also write:
#   "flag": ["helped_beggar"]   remembers that this happened. A later scenario
#                               or choice can ask for it with "needs". The
#                               name is yours to make up; mind the [ and ].
#   "goto": "beggar_returns"    the story goes on at once with the scenario
#                               that has this "id"
#   "learn": "iron_shirt"       teaches a technique (their ids are in
#                               scripts/martial_data.gd)
#   Template 7 below shows a story in two parts.
#
# NAMES OF PEOPLE
#   In any text, {Master}, {Mother}, {Father}, {Sibling}, {Spouse}, {Child},
#   {Friend} and {Rival} are replaced by that person's name. The scenario
#   then only happens while that person is in your life.
#
# SPELLING MATTERS
#   Write the words exactly as above, capital letters included: "Martial
#   Insight", not "martial insight". Every line inside a { } ends with a comma.
#   To put a " inside a sentence, write \" like this: "He says \"Run!\""

# =============================================================================
#  TEMPLATES TO COPY
# =============================================================================

# --- TEMPLATE 1: plain choices that always work ------------------------------
#	{
#		"text": "Write what happens here.",
#		"image": "village",
#		"choices": [
#			{"label": "The first choice", "win": {"Gold": 5},
#				"win_text": "Write how it turned out."},
#			{"label": "The second choice", "win": {"Karma": 2}},
#		],
#	},

# --- TEMPLATE 2: a dice roll that a stat helps with --------------------------
#	{
#		"text": "Write what happens here.",
#		"image": "mountain",
#		"min_age": 10,
#		"choices": [
#			{"label": "The risky choice", "stat": "Agility", "difficulty": 14,
#				"win": {"Agility": 1, "Reputation": 2},
#				"win_text": "Write what happens when it works.",
#				"lose": {"Health": -15},
#				"lose_text": "Write what happens when it goes wrong."},
#			{"label": "The safe choice", "win": {}},
#		],
#	},

# --- TEMPLATE 3: pure luck ----------------------------------------------------
#	{
#		"text": "Write what happens here.",
#		"image": "tavern",
#		"min_age": 14,
#		"choices": [
#			{"label": "Take the gamble", "percent": 40,
#				"win": {"Gold": 30}, "win_text": "Luck is with you.",
#				"lose": {"Gold": -10}, "lose_text": "Luck is not with you."},
#			{"label": "Walk away", "win": {}},
#		],
#	},

# --- TEMPLATE 4: a fight, with an item as the prize ---------------------------
#	{
#		"text": "Write what happens here.",
#		"image": "forest",
#		"min_age": 12,
#		"choices": [
#			{"label": "Fight", "fight": "bandit", "item": "Healing Pill",
#				"win": {"Gold": 15, "Reputation": 3},
#				"win_text": "Write what you find afterwards."},
#			{"label": "A friendly duel instead", "fight": "duelist", "friendly": true,
#				"meet": "Rival", "win": {"Reputation": 5}},
#			{"label": "Slip away", "stat": "Agility", "difficulty": 12,
#				"win": {}, "lose": {"Health": -10}},
#		],
#	},

# --- TEMPLATE 5: something that happens to a small child ----------------------
#	{
#		"text": "Write what happens here.",
#		"image": "home",
#		"min_age": 0, "max_age": 5,
#		"choices": [
#			{"label": "The first choice", "win": {"Mother": 5, "Happiness": 3}},
#			{"label": "The second choice", "win": {"Father": 5, "Smarts": 2}},
#		],
#	},

# --- TEMPLATE 6: a rare event that happens only once in a life ----------------
#	{
#		"text": "Write what happens here.",
#		"image": "cave",
#		"min_age": 14,
#		"unique": true,
#		"choices": [
#			{"label": "Accept", "stat": "Martial Insight", "difficulty": 16,
#				"win": {"Qi": 50, "Qi Capacity": 20},
#				"lose": {"Health": -25}},
#			{"label": "Refuse", "win": {"Karma": 5}},
#		],
#	},

# --- TEMPLATE 7: a story in two parts (copy both scenarios together) ----------
# The first part can happen once. Helping sets the flag "helped_stranger".
# The second part can only happen after that, when you are at least 16.
#	{
#		"id": "stranger_in_rain", "title": "The Stranger in the Rain",
#		"once": true,
#		"text": "Write how the story begins.",
#		"image": "village",
#		"min_age": 10,
#		"choices": [
#			{"label": "Help", "win": {"Karma": 3, "flag": ["helped_stranger"]},
#				"win_text": "Write what happens when you help."},
#			{"label": "Walk past", "win": {}},
#		],
#	},
#	{
#		"id": "stranger_returns", "title": "The Stranger Returns",
#		"once": true,
#		"text": "Write how the story goes on, years later.",
#		"image": "tavern",
#		"needs": {"age": 16, "flag": ["helped_stranger"]},
#		"choices": [
#			{"label": "Accept the gift", "needs": {"Willpower": 30},
#				"win": {"Gold": 50, "Reputation": 3}},
#			{"label": "Ask to be taught instead", "meet": "Master", "win": {}},
#		],
#	},

# =============================================================================
#  YOUR SCENARIOS GO IN THIS LIST
# =============================================================================

const SCENARIOS = [
	# An example to show how a finished scenario looks. Change it or delete it.
	{
		"text": "A fortune teller waves you over to her stall. \"Three coins, and I will read your fate.\"",
		"image": "village",
		"min_age": 8,
		"choices": [
			{"label": "Pay for a reading", "percent": 50,
				"win": {"Gold": -3, "Happiness": 10},
				"win_text": "\"A dragon sleeps in your shadow,\" she whispers. You walk a little taller.",
				"lose": {"Gold": -3, "Happiness": -5},
				"lose_text": "\"Beware of water. And stairs. And geese.\" You regret the three coins."},
			{"label": "Guess her trick", "stat": "Smarts", "difficulty": 55,
				"win": {"Smarts": 3, "Reputation": 1},
				"win_text": "She reads faces, not fates. You tell her so, and she grins.",
				"lose": {}, "lose_text": "You cannot work out how she knew your name."},
			{"label": "Walk past", "win": {}},
		],
	},

	# Paste your own scenarios below this line.

]
