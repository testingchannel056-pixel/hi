extends RefCounted

# Scenarios that come from your work. Each one only shows up while you walk
# one of the life paths in its "needs". Same format as ENCOUNTERS in
# world_data.gd.

const SCENARIOS = [
	{
		"text": "No rain for sixty days. The millet is turning to straw in the field.",
		"image": "village", "min_age": 13, "needs": {"path": ["Farmer"]},
		"choices": [
			{"label": "Carry water from the river, bucket by bucket", "stat": "Strength", "difficulty": 13,
				"win": {"Gold": 10, "Willpower": 3}, "win_text": "You save a third of the crop, which is a third more than your neighbours.",
				"lose": {"Health": -12}, "lose_text": "The field dies anyway, and nearly takes you with it."},
			{"label": "Dig a channel with the whole village", "win": {"Reputation": 3, "Karma": 2},
				"win_text": "It takes three weeks. Everyone's field gets a little, and nobody starves."},
			{"label": "Sell the land while it is still worth something", "win": {"Gold": 25, "Happiness": -8}},
		],
	},
	{
		"text": "The provincial examination is announced. Three days in a cell with a brush, an ink stone and your own head.",
		"image": "village", "min_age": 16, "unique": true, "needs": {"path": ["Scholar", "Teacher"]},
		"choices": [
			{"label": "Sit the examination", "stat": "Smarts", "difficulty": 75,
				"win": {"Reputation": 15, "Gold": 40, "Happiness": 10},
				"win_text": "Your name is posted on the wall in gold ink. Your family will tell this story for three generations.",
				"lose": {"Happiness": -8, "Willpower": 3}, "lose_text": "Your name is not on the wall. There is always next time, they say."},
			{"label": "Sell essays to richer candidates instead", "win": {"Gold": 35, "Karma": -4}},
			{"label": "Stay home", "win": {}},
		],
	},
	{
		"text": "A swordsman in travelling clothes sets a broken blade on your bench. \"They say you are good. Prove it.\"",
		"image": "village", "min_age": 14, "needs": {"path": ["Craftsman"]},
		"choices": [
			{"label": "Reforge it as it was", "stat": "Strength", "difficulty": 14,
				"win": {"Gold": 25, "Reputation": 4}, "win_text": "He tests the edge on a hair, nods once, and overpays.",
				"lose": {"Reputation": -2}, "lose_text": "The weld shows. He pays for the charcoal and nothing else."},
			{"label": "Tell him honestly that it cannot be saved", "win": {"Karma": 2, "Reputation": 1}},
			{"label": "Forge him a new one and study the old", "stat": "Martial Insight", "difficulty": 14,
				"win": {"Gold": 15, "Martial Insight": 1}, "win_text": "The way the old blade broke tells you how its owner fights.",
				"lose": {"Gold": 10}},
		],
	},
	{
		"text": "A stranger offers you a cartload of silk at half its price. He keeps glancing at the road behind him.",
		"image": "tavern", "min_age": 15, "needs": {"path": ["Merchant"]},
		"choices": [
			{"label": "Buy it all", "percent": 55,
				"win": {"Gold": 60}, "win_text": "It sells in a week. You do not ask where it came from.",
				"lose": {"Gold": -40, "Reputation": -3}, "lose_text": "The magistrate's men arrive the next morning. The silk was his."},
			{"label": "Buy it, then report him", "win": {"Gold": 15, "Karma": -2}},
			{"label": "Send him on his way", "win": {"Karma": 1}},
		],
	},
	{
		"text": "A rival trader has been telling the whole market that your scales are false.",
		"image": "village", "min_age": 15, "needs": {"path": ["Merchant"]},
		"choices": [
			{"label": "Have your scales tested in public", "win": {"Reputation": 4}},
			{"label": "Spread a worse rumour about him", "stat": "Smarts", "difficulty": 55,
				"win": {"Gold": 20, "Karma": -3}, "lose": {"Reputation": -4}},
			{"label": "Undercut his prices until he leaves town", "win": {"Gold": -20, "Reputation": 2}},
		],
	},
	{
		"text": "A village two valleys over is burning with fever. Nobody who goes in has come out.",
		"image": "fire", "min_age": 16, "needs": {"path": ["Physician"]},
		"choices": [
			{"label": "Go", "stat": "Smarts", "difficulty": 65,
				"win": {"Reputation": 12, "Karma": 10, "Health": -10},
				"win_text": "You boil every cup, burn every blanket and sleep four hours in ten days. The dying stops.",
				"lose": {"Health": -30, "Karma": 5}, "lose_text": "You catch it yourself. They carry you out on a door."},
			{"label": "Send medicine and instructions", "win": {"Gold": -15, "Karma": 4}},
			{"label": "It is not your village", "win": {"Karma": -3}},
		],
	},
	{
		"text": "A rich man offers you ten times your fee to say that his elder brother died of illness.",
		"image": "home", "min_age": 18, "needs": {"path": ["Physician"]},
		"choices": [
			{"label": "Take the money", "win": {"Gold": 60, "Karma": -10}},
			{"label": "Refuse, and tell the magistrate what you saw", "win": {"Karma": 6, "Reputation": 5}},
			{"label": "Refuse, and say nothing", "win": {"Karma": 1}},
		],
	},
	{
		"text": "One pupil at the back never speaks, and solves in a morning what takes the others a month.",
		"image": "home", "min_age": 25, "unique": true, "needs": {"path": ["Teacher"]},
		"choices": [
			{"label": "Take the pupil as your own disciple", "meet": "Disciple", "win": {"Happiness": 8, "Reputation": 3}},
			{"label": "Recommend them to a great sect", "win": {"Karma": 3, "Reputation": 2}},
			{"label": "Teach them like all the others", "win": {}},
		],
	},
	{
		"text": "A wounded stag leads you deep into the forest, to a clearing where the air itself seems to hum.",
		"image": "forest", "min_age": 13, "needs": {"path": ["Hunter"]},
		"choices": [
			{"label": "Take the stag", "win": {"Gold": 15}},
			{"label": "Sit down and breathe", "win": {"Qi": 15, "Willpower": 2},
				"win_text": "The stag watches you until dusk. You let it go."},
			{"label": "Mark the place and tell no one", "item": "Spirit Herb", "win": {}},
		],
	},
	{
		"text": "The caravan you are guarding stops. Twenty riders are waiting across the pass.",
		"image": "mountain", "min_age": 15, "needs": {"path": ["Guard"]},
		"choices": [
			{"label": "Hold the line", "fight": "bandit", "win": {"Gold": 30, "Reputation": 6}},
			{"label": "Bargain: a toll, and no blood", "stat": "Smarts", "difficulty": 55,
				"win": {"Gold": 10, "Reputation": 2}, "lose": {"Gold": -10, "Reputation": -3}},
			{"label": "Slip away in the confusion", "win": {"Reputation": -8, "Karma": -4}},
		],
	},
	{
		"text": "The magistrate's own strongbox is being moved tonight, with four guards and a bored clerk.",
		"image": "mountain", "min_age": 15, "needs": {"path": ["Jianghu Outlaw"]},
		"choices": [
			{"label": "Take it by force", "fight": "duelist", "win": {"Gold": 80, "Karma": -6, "Reputation": 3}},
			{"label": "Take it by stealth", "stat": "Agility", "difficulty": 15,
				"win": {"Gold": 80, "Karma": -4}, "lose": {"Health": -20, "Gold": -10}},
			{"label": "Leave half of it on the doorsteps of the poor", "stat": "Agility", "difficulty": 15,
				"win": {"Gold": 40, "Karma": 8, "Reputation": 6}, "lose": {"Health": -20}},
		],
	},
	{
		"text": "The elders set you a test before the whole clan: three exchanges with their best swordsman.",
		"image": "sect", "min_age": 14, "unique": true, "needs": {"path": ["Sect Heir", "Martial Disciple"]},
		"choices": [
			{"label": "Meet him head on", "fight": "duelist", "friendly": true, "win": {"Reputation": 10, "Happiness": 6}},
			{"label": "Ask for one more year to prepare", "win": {"Reputation": -3, "Willpower": 2}},
		],
	},
]
