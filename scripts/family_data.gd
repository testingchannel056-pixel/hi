extends RefCounted

# Scenarios about your family. They use the same format as ENCOUNTERS in
# world_data.gd, with one extra: a name in curly brackets, such as {Sibling},
# is replaced by that person's name, and the scenario only shows up while
# you have such a person in your life.

const SCENARIOS = [
	{
		"text": "{Sibling} wants to leave home and join a sect. Your parents will not hear of it.",
		"image": "home", "min_age": 10, "max_age": 30,
		"choices": [
			{"label": "Speak up for {Sibling}", "win": {"Sibling": 10, "Father": -3, "Mother": -3},
				"win_text": "The argument lasts three days. In the end your father packs the bag himself."},
			{"label": "Side with your parents", "win": {"Sibling": -8, "Father": 3, "Mother": 3}},
			{"label": "Offer to train {Sibling} yourself", "stat": "Martial Insight", "difficulty": 13,
				"win": {"Sibling": 12}, "win_text": "It turns out you are a patient teacher.",
				"lose": {"Sibling": -3}, "lose_text": "It turns out you are a terrible teacher."},
		],
	},
	{
		"text": "{Sibling} has gambled away a month's wages and begs you to tell no one.",
		"image": "tavern", "min_age": 14,
		"choices": [
			{"label": "Cover the debt quietly", "win": {"Gold": -15, "Sibling": 10}},
			{"label": "Make {Sibling} work it off beside you", "win": {"Sibling": 4, "Willpower": 2}},
			{"label": "Tell the whole family at dinner", "win": {"Sibling": -12, "Karma": -1}},
		],
	},
	{
		"text": "{Sibling} and you are sent to sell the harvest in town. On the way home, the purse feels light.",
		"image": "village", "min_age": 8, "max_age": 20,
		"choices": [
			{"label": "Count it together", "stat": "Smarts", "difficulty": 45,
				"win": {"Sibling": 5, "Smarts": 2}, "win_text": "The merchant short-changed you both. You march back and get it.",
				"lose": {"Gold": -3}, "lose_text": "Neither of you can work out where it went."},
			{"label": "Accuse {Sibling} of taking some", "win": {"Sibling": -8}},
			{"label": "Say nothing and make up the difference", "win": {"Gold": -5, "Karma": 1}},
		],
	},
	{
		"text": "{Spouse} wakes with a fever that will not break.",
		"image": "home",
		"choices": [
			{"label": "Fetch the best physician in the province", "win": {"Gold": -25, "Spouse": 8}},
			{"label": "Nurse {Spouse} yourself", "stat": "Smarts", "difficulty": 55,
				"win": {"Spouse": 12}, "win_text": "On the fourth night the fever breaks. You have not slept.",
				"lose": {"Spouse": -5, "Happiness": -5}, "lose_text": "You do everything wrong. A neighbour takes over."},
			{"label": "Pray at the shrine", "percent": 50,
				"win": {"Spouse": 5, "Willpower": 2}, "lose": {"Happiness": -6}},
		],
	},
	{
		"text": "{Spouse} says, quietly, that you love the sword more than your own home.",
		"image": "home",
		"choices": [
			{"label": "Promise to be home more, and mean it", "win": {"Spouse": 8, "Happiness": 3}},
			{"label": "Take {Spouse} travelling for a month", "win": {"Gold": -20, "Spouse": 12, "Happiness": 8}},
			{"label": "Say nothing", "win": {"Spouse": -6}},
		],
	},
	{
		"text": "{Child} asks you why people fight.",
		"image": "home",
		"choices": [
			{"label": "\"To protect what they love.\"", "win": {"Child": 6, "Karma": 1}},
			{"label": "\"To find out who is strongest.\"", "win": {"Child": 3}},
			{"label": "Change the subject", "win": {"Child": -4}},
		],
	},
	{
		"text": "{Child} comes home with a black eye and will not say who did it.",
		"image": "village",
		"choices": [
			{"label": "Teach {Child} how to block", "win": {"Child": 6}},
			{"label": "Sit with {Child} until the story comes out", "win": {"Child": 8, "Happiness": 2}},
			{"label": "Go and find the other child's parents", "win": {"Child": -3, "Reputation": -1}},
		],
	},
	{
		"text": "Your mother's hands shake now when she pours the tea.",
		"image": "home", "min_age": 30,
		"choices": [
			{"label": "Send money home every month", "win": {"Gold": -20, "Mother": 10, "Karma": 2}},
			{"label": "Visit more often", "win": {"Mother": 8, "Happiness": 3}},
			{"label": "You are too busy", "win": {"Mother": -8, "Karma": -2}},
		],
	},
	{
		"text": "{Master} sets you to carrying water up the mountain for a month, and will not say why.",
		"image": "mountain", "min_age": 10,
		"choices": [
			{"label": "Carry it without a word", "win": {"Master": 6, "Willpower": 3}},
			{"label": "Ask why", "win": {"Master": -2, "Smarts": 2},
				"win_text": "\"Because the buckets leak. Think about it.\""},
			{"label": "Mend the buckets at night", "stat": "Smarts", "difficulty": 55,
				"win": {"Master": 8, "Martial Insight": 1}, "win_text": "{Master} looks at the dry path, and for once says nothing at all.",
				"lose": {"Master": -3}, "lose_text": "Your mending makes them leak worse."},
		],
	},
	{
		"text": "{Master} has an errand for you: a sealed letter, to an old enemy three valleys away.",
		"image": "mountain", "min_age": 12,
		"choices": [
			{"label": "Deliver it unopened", "win": {"Master": 5, "Reputation": 2}},
			{"label": "Read it first", "percent": 50,
				"win": {"Smarts": 2}, "win_text": "It is an invitation to tea. Forty years of enmity, and an invitation to tea.",
				"lose": {"Master": -6}, "lose_text": "The seal cannot be put back. {Master} knows the moment you return."},
			{"label": "Say you are no messenger", "win": {"Master": -4}},
		],
	},
	{
		"text": "{Master} coughs blood into a sleeve, and thinks you did not see.",
		"image": "home", "min_age": 18,
		"choices": [
			{"label": "Fetch medicine, whatever it costs", "win": {"Gold": -20, "Master": 10, "Karma": 2}},
			{"label": "Pretend you saw nothing", "win": {"Master": 2}},
			{"label": "Ask to be taught everything while there is time", "win": {"Master": -4, "Qi": 10},
				"win_text": "A long silence. Then: \"Sit down. We start tonight.\""},
		],
	},
	{
		"text": "Your father asks, gruffly, when you intend to settle down.",
		"image": "home", "min_age": 22, "max_age": 40,
		"choices": [
			{"label": "\"When I meet the right person.\"", "win": {"Father": 2}},
			{"label": "\"The martial path leaves no room for it.\"", "win": {"Father": -4, "Willpower": 2}},
			{"label": "Ask him how he met your mother", "win": {"Father": 8, "Happiness": 4},
				"win_text": "You have never heard him talk for so long."},
		],
	},
]
