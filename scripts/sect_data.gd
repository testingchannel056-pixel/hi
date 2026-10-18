extends RefCounted

# Scenarios for someone who leads a sect of their own. Same format as
# ENCOUNTERS in world_data.gd, with three extra things "win" and "lose" can
# change: "Disciples", "Elders" and "Sect Fame".

const SCENARIOS = [
	{
		"text": "A senior disciple stands up in the hall and says, before everyone, that you are no longer fit to lead.",
		"image": "sect", "min_age": 16, "weight": 3, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Duel him before the whole sect", "fight": "duelist", "friendly": true,
				"win": {"Sect Fame": 5, "Disciples": 2}, "win_text": "He kneels. So do the ones who were watching to see which way it went.",
				"lose": {"Disciples": -4, "Sect Fame": -5}, "lose_text": "He does not take your seat. He takes a third of your disciples and leaves."},
			{"label": "Hear him out", "stat": "Smarts", "difficulty": 55,
				"win": {"Disciples": 3, "Karma": 2}, "win_text": "He had a point. You change two rules and keep a loyal man.",
				"lose": {"Disciples": -3}, "lose_text": "You argue badly. People drift away over the following weeks."},
			{"label": "Expel him and his friends", "win": {"Disciples": -3, "Karma": -3}},
		],
	},
	{
		"text": "Torches on the mountain road. A rival school has come to burn yours.",
		"image": "fire", "min_age": 16, "weight": 3, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Meet them at the gate yourself", "fight": "cultist", "mercy": true,
				"win": {"Sect Fame": 8, "Reputation": 5}, "win_text": "Their leader goes down the steps faster than he came up.",
				"lose": {"Disciples": -5, "Gold": -30}, "lose_text": "The gate falls. They take what they like and leave the rest burning."},
			{"label": "Hold the walls and wait for dawn", "stat": "Martial Insight", "difficulty": 15,
				"win": {"Sect Fame": 4}, "win_text": "By morning they have run out of torches and of nerve.",
				"lose": {"Disciples": -3}},
			{"label": "Pay them to leave", "needs": {"Gold": 50}, "win": {"Gold": -50, "Sect Fame": -4}},
		],
	},
	{
		"text": "The terraces failed this year. The rice store will not last the winter.",
		"image": "mountain", "min_age": 16, "weight": 3, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Buy grain at any price", "needs": {"Gold": 40}, "win": {"Gold": -40, "Disciples": 1}},
			{"label": "Send the disciples down the mountain to work", "win": {"Gold": 10, "Sect Fame": -2}},
			{"label": "Tighten every belt, yours first", "win": {"Health": -10, "Willpower": 3, "Disciples": -1}},
		],
	},
	{
		"text": "A wandering master of some fame asks, over tea, whether your sect has room for an old sword.",
		"image": "sect", "min_age": 16, "weight": 3, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Welcome him as an elder", "needs": {"Gold": 30}, "win": {"Gold": -30, "Elders": 1, "Sect Fame": 3}},
			{"label": "Test him first", "fight": "duelist", "friendly": true,
				"win": {"Elders": 1, "Sect Fame": 5, "Reputation": 3}, "win_text": "\"Good,\" he says from the floor. \"I will not serve a weak leader.\"",
				"lose": {"Sect Fame": -2}, "lose_text": "He helps you up, thanks you for the tea, and leaves."},
			{"label": "Decline politely", "win": {}},
		],
	},
	{
		"text": "A disciple digging a well strikes a stone chest. Inside, wrapped in oilcloth: a manual.",
		"image": "cave", "min_age": 16, "weight": 2, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Study it yourself, in private", "stat": "Martial Insight", "difficulty": 15,
				"win": {"Martial Insight": 2, "Qi Capacity": 10},
				"lose": {"Health": -10}, "lose_text": "It was written for a different kind of body than yours."},
			{"label": "Place it in the library for everyone", "win": {"Sect Fame": 6, "Disciples": 2, "Karma": 2}},
			{"label": "Sell it", "win": {"Gold": 80, "Sect Fame": -3}},
		],
	},
	{
		"text": "Two of your best disciples have stopped speaking to each other. Half the hall has taken sides.",
		"image": "sect", "min_age": 16, "weight": 3, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Send them on a mission together", "percent": 60,
				"win": {"Disciples": 1, "Sect Fame": 2}, "win_text": "They come back with matching scars and one story between them.",
				"lose": {"Disciples": -2}, "lose_text": "Only one of them comes back."},
			{"label": "Make them spar until it is out of them", "win": {"Sect Fame": 1}},
			{"label": "Let it be", "win": {"Disciples": -2}},
		],
	},
	{
		"text": "The season's tournament between the lesser sects is announced. Yours is invited for the first time.",
		"image": "sect", "min_age": 16, "weight": 2, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Send your best disciples", "percent": 45,
				"win": {"Sect Fame": 10, "Disciples": 3, "Reputation": 4}, "win_text": "They take the banner. Applicants are at the gate before they are home.",
				"lose": {"Sect Fame": -2}, "lose_text": "They are knocked out in the first round, politely."},
			{"label": "Step onto the stage yourself", "fight": "duelist", "friendly": true,
				"win": {"Sect Fame": 8, "Reputation": 8}, "lose": {"Sect Fame": -3}},
			{"label": "Stay home", "win": {}},
		],
	},
	{
		"text": "A farmer brings a barefoot child to your gate. \"Breaks everything they touch. Maybe you can use that.\"",
		"image": "sect", "min_age": 20, "weight": 2, "needs": {"leads_sect": true},
		"choices": [
			{"label": "Take the child as your own disciple", "meet": "Disciple", "win": {"Disciples": 1, "Happiness": 4}},
			{"label": "Enrol the child with the others", "win": {"Disciples": 1}},
			{"label": "Send them home", "win": {}},
		],
	},
]
