extends RefCounted

# Data about the people in your life: temperaments, trades, and what a bond
# of a certain strength is called. The rules are in scripts/npc_manager.gd,
# and the roles themselves (Father, Friend, Rival...) are ROLES in world_data.gd.

# "warmth" is added every time your bond with someone of this temperament
# grows: warm people are easy to get close to, cold ones are not.
const PERSONALITIES = {
	"Kind": {"warmth": 2},
	"Cheerful": {"warmth": 2},
	"Loyal": {"warmth": 1},
	"Quiet": {"warmth": 0},
	"Cunning": {"warmth": 0},
	"Hot-tempered": {"warmth": -1},
	"Stern": {"warmth": -2},
	"Proud": {"warmth": -2},
}

# What ordinary people do for a living...
const OCCUPATIONS = ["Farmer", "Weaver", "Blacksmith", "Merchant", "Scholar", "Physician", "Hunter",
	"Guard", "Innkeeper", "Fisher", "Carpenter", "Storyteller"]
# ...and the trades of those who live by the sword. People with one of these
# can grow in cultivation over the years.
const MARTIAL_OCCUPATIONS = ["Sect Disciple", "Sect Elder", "Wandering Swordsman", "Wandering Master",
	"Young Swordsman", "Clan Swordsman", "Clan Swordswoman", "Escort Guard"]

# What a bond is called, from weakest to strongest: [bond needed, name].
const BOND_NAMES = [[0, "Stranger"], [15, "Acquaintance"], [35, "Friend"], [60, "Close friend"], [85, "Devoted"]]
# The same for family, where "stranger" would sound wrong.
const FAMILY_BOND_NAMES = [[0, "Estranged"], [15, "Distant"], [35, "Warm"], [60, "Close"], [85, "Devoted"]]

# The most history lines kept for one person.
const HISTORY_LENGTH = 12
