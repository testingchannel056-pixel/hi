extends TextureRect
## Layered anime portrait: chosen appearance, aging, outfit, and faction backdrop.
##
## Use:
##     const Portrait = preload("res://ui_pack/portrait.gd")
##     var portrait = Portrait.new()
##     portrait.custom_minimum_size = Vector2(240, 240)
##     add_child(portrait)
##     portrait.set_profile({"gender": "male", "age": 17, "looks": 72, "seed": 1234})
##
## Nobody picks a face. The picture is one of the ready-made avatars in portraits/:
##     looks   -> 10 columns, Looks 0-9 on the left up to 90-100 on the right
##     age     -> young (under 18), adult (18-35), mature (36-50), elder (51+)
##     gender  -> male or female
##     seed    -> which set of people to use, once there is more than one sheet (see SETS)
##
## Adults and mature characters with very low Looks use the separate "ugly" faces.
## Each avatar already has its own round frame and background, so nothing is drawn around it.

const Art = preload("res://scripts/character_art.gd")

const LOOKS_MAX = 100            # change this if your Looks stat does not run from 0 to 100
const TIERS = 10
const SETS = 1                   # how many sheets have been sliced into portraits/ (sets 0, 1, 2 ...)
const UGLY_BELOW_TIER = 2        # Looks under 20: adults and mature characters get the "ugly" faces
const LOOKS_WORDS = ["Hideous", "Ugly", "Homely", "Plain", "Ordinary", "Pleasant", "Good-looking", "Striking", "Stunning", "Peerless"]

static var texture_cache = {}

var current_file = ""


func _init():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Updates the portrait. Safe to call every time the player changes.
func set_profile(profile):
	var character = profile.duplicate(true)
	character["gender"] = "Female" if str(profile.get("gender", "Male")).to_lower().begins_with("f") else "Male"
	var key = Art.key_of(character)
	if key == current_file:
		return
	current_file = key
	texture = Art.texture(character)


## Returns the avatar file name for a profile, without ".png".
static func pick(profile):
	var gender = "female" if str(profile.get("gender", "")).to_lower().left(1) in ["f", "w"] else "male"
	var stage = stage_for_age(int(profile.get("age", 18)))
	var tier = tier_for_looks(profile.get("looks", LOOKS_MAX / 2.0))
	if tier < UGLY_BELOW_TIER and stage in ["adult", "mature"]:
		stage = "ugly"
	var seed_value = absi(int(profile.get("seed", hash(str(profile.get("name", ""))))))
	return "avatar_%s_%s_%d_%d" % [gender, stage, tier, seed_value % SETS]


## Looks 0-9 is tier 0, 10-19 is tier 1 ... 90-100 is tier 9.
static func tier_for_looks(looks):
	return clampi(int(float(looks) * TIERS / LOOKS_MAX), 0, TIERS - 1)


## A word for a Looks value, for showing next to the number.
static func looks_word(looks):
	return LOOKS_WORDS[tier_for_looks(looks)]


static func stage_for_age(age):
	if age < 18:
		return "young"
	if age < 36:
		return "adult"
	if age < 51:
		return "mature"
	return "elder"
