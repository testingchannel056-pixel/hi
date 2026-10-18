extends RefCounted

# Draws a character's portrait from their look (see character_data.gd).
#
# Nothing here is a picture file. The portrait is written as SVG, which is a
# drawing described in text ("a circle here, a curve there, filled with this
# colour"), and Godot turns that text into a picture. That is why any skin,
# hair and eye colour works, and why the same person can be drawn as a
# child, in their prime and old.
#
# A portrait is 512 x 512. Everything is measured in those pixels, with
# (0, 0) at the top left, and the face is centred on x = 256.
#
# The layers, from the back to the front:
#   backdrop -> hair behind the body -> body -> clothes -> head -> face
#   -> beard and marks -> hair in front -> the gold ring
#
# To use it:
#   var picture = Art.texture({"gender": "Male", "age": 25, "look": look,
#       "outfit": "martial", "backdrop": "plain"})

const Data = preload("res://scripts/character_data.gd")
const UiTheme = preload("res://ui_pack/murim_theme.gd")

const CACHE_LIMIT = 48        # finished portraits kept in memory
const EYE_APART = 38.0        # how far each eye is from the middle of the face
# Each eye shape: [half its width, how far it opens, how much the outer corner lifts]
const EYE_SIZES = [[25.0, 10.5, 6.5], [24.0, 12.0, 3.5], [24.0, 15.0, 2.0]]
# The hair that covers the top of the head in most styles. Its lower edge is the hairline.
const CAP = "M172,228 C160,150 196,82 256,82 C316,82 352,150 340,228 C338,204 334,186 326,170 C312,146 286,134 256,134 C226,134 200,146 186,170 C178,186 174,204 172,228 Z"
# The same with a point in the middle of the hairline.
const CAP_PEAK = "M172,228 C160,150 196,82 256,82 C316,82 352,150 340,228 C338,204 334,186 326,170 C314,148 290,130 266,135 L256,147 L246,135 C222,130 198,148 186,170 C178,186 174,204 172,228 Z"
# A thin lock that hangs in front of the left ear. "%s" is how far down it reaches.
const SIDE_LOCK = "M186,176 C173,214 174,262 182,%s C188,%s 193,%s 193,%s C188,262 190,214 199,180 Z"

static var cache = {}


# Returns the portrait as a texture. The same character is only drawn once.
static func texture(character):
	var key = key_of(character)
	if not cache.has(key):
		if cache.size() >= CACHE_LIMIT:
			cache.clear()
		var image = Image.new()
		if image.load_svg_from_string(svg(character), 1.0) != OK:
			push_warning("character_art.gd: the portrait could not be drawn.")
			return null
		image.generate_mipmaps()
		cache[key] = ImageTexture.create_from_image(image)
	return cache[key]


# A short text that is different for every different-looking portrait.
static func key_of(character):
	var gender = character.get("gender", "Male")
	var look = Data.complete(character.get("look", {}), gender, int(character.get("seed", 0)))
	var life = Data.life_stage(int(character.get("age", 25)), int(character.get("cultivation", 0)))
	var key = "%s|%s|%s|%s" % [gender, life, character.get("outfit", ""), character.get("backdrop", "")]
	for part in Data.PARTS:
		key += "|%d" % look[part["key"]]
	return key


# ---------------------------------------------------------------------------
# The whole portrait
# ---------------------------------------------------------------------------

static func svg(character):
	var k = setup(character)
	var hair_parts = hair_layers(k)
	var layers = [
		'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">',
		definitions(k),
		backdrop(k),
		'<g clip-path="url(#round)">',
		hair_parts["back"],
		body(k),
		clothes(k),
		head(k),
		face(k),
		beard(k),
		mark(k),
		hair_parts["front"],
		anime_finish(k),
		'</g>',
		'<circle cx="256" cy="256" r="240" fill="none" stroke="%s" stroke-width="5"/>' % hx(UiTheme.GOLD),
		'<circle cx="256" cy="256" r="246" fill="none" stroke="%s" stroke-width="2"/>' % hx(UiTheme.GOLD.darkened(0.45)),
		'<circle cx="256" cy="256" r="234" fill="none" stroke="%s" stroke-width="1.5" stroke-opacity="0.6"/>' % hx(UiTheme.GOLD.lightened(0.3)),
		'</svg>',
	]
	return "\n".join(layers)


# Works out everything the layers need: sizes, and every colour as text.
static func setup(character):
	var gender = character.get("gender", "Male")
	var male = gender == "Male"
	var life = Data.life_stage(int(character.get("age", 25)), int(character.get("cultivation", 0)))
	var look = Data.complete(character.get("look", {}), gender, int(character.get("seed", 0)))
	var k = figure(male, life, look["build"])
	k["male"] = male
	k["life"] = life
	k["look"] = look

	var skin = Color(Data.SKINS[look["skin"]][1])
	k["skin"] = hx(skin)
	k["skin_light"] = hx(skin.lightened(0.14))
	k["shade"] = hx(Color(skin.r * 0.76, skin.g * 0.62, skin.b * 0.58))
	k["deep"] = hx(Color(skin.r * 0.52, skin.g * 0.38, skin.b * 0.36))
	var lip = skin.lerp(Color("c25a5c"), 0.75 if not male else 0.45)
	k["lip"] = hx(lip)
	k["lip_dark"] = hx(lip.darkened(0.3))

	var locks = Color(Data.HAIR_COLOURS[look["hair_colour"]][1])
	if life == "elder":
		locks = locks.lerp(Color("d8dae0"), 0.8)   # age turns any hair grey
	k["hair"] = hx(locks)
	k["hair_light"] = hx(locks.lightened(0.22))
	k["hair_dark"] = hx(locks.darkened(0.4))
	# Eyebrows and beards are a darker shade of the hair.
	k["brow"] = hx(locks.darkened(0.35 if locks.get_luminance() < 0.5 else 0.45))

	var eye = Color(Data.EYE_COLOURS[look["eye_colour"]][1])
	k["eye"] = hx(eye)
	k["eye_light"] = hx(eye.lightened(0.35))
	k["eye_dark"] = hx(eye.darkened(0.6))

	var outfit = Data.OUTFITS.get(character.get("outfit", ""), Data.OUTFITS[Data.DEFAULT_OUTFIT])
	var robe = Color(outfit[0])
	k["robe"] = hx(robe)
	k["robe_light"] = hx(robe.lightened(0.16))
	k["robe_dark"] = hx(robe.darkened(0.35))
	k["trim"] = hx(Color(outfit[1]))
	k["trim_dark"] = hx(Color(outfit[1]).darkened(0.35))
	k["inner"] = hx(Color(outfit[2]))
	k["patched"] = character.get("outfit", "") == "beggar"

	var place = Data.BACKDROPS.get(character.get("backdrop", ""), Data.BACKDROPS["plain"])
	k["sky"] = hx(Color(place[0]))
	k["sky_edge"] = hx(Color(place[1]))
	k["hill"] = hx(Color(place[1]).lerp(Color(place[0]), 0.35))
	k["gold"] = hx(UiTheme.GOLD)
	k["red"] = hx(UiTheme.RED)
	k["jade"] = hx(UiTheme.JADE)
	return k


# The sizes of a face and body. Men, women, children and the three builds
# differ here and nowhere else.
#   eye_y, nose_y, mouth_y   how far down the face each one sits
#   jaw_x, jaw_y             the corner of the jaw (jaw_x is counted from the middle)
#   chin_x, chin_y           the corner of the chin
#   neck, shoulder           half the width of the neck and of the shoulders
#   shoulder_y               how high the shoulders sit (smaller is higher)
#   trap                     how much muscle rises from the shoulder to the neck
#   open                     how far the collar opens down the chest
static func figure(male, life, build):
	var k = {}
	if life == "child":
		k = {"eye_y": 229.0, "nose_y": 262.0, "mouth_y": 281.0, "jaw_x": 58.0, "jaw_y": 268.0,
			"chin_x": 20.0, "chin_y": 304.0, "neck": 26.0, "shoulder": 116.0, "shoulder_y": 438.0,
			"trap": 6.0, "open": 0.0}
	elif male:
		k = {"eye_y": 218.0, "nose_y": 266.0, "mouth_y": 290.0, "jaw_x": 59.0, "jaw_y": 284.0,
			"chin_x": 25.0, "chin_y": 322.0, "neck": [38.0, 46.0, 54.0][build],
			"shoulder": [174.0, 202.0, 230.0][build], "shoulder_y": [414.0, 404.0, 394.0][build],
			"trap": [10.0, 22.0, 36.0][build], "open": [34.0, 54.0, 72.0][build]}
	else:
		k = {"eye_y": 220.0, "nose_y": 264.0, "mouth_y": 287.0, "jaw_x": 51.0, "jaw_y": 282.0,
			"chin_x": 11.0, "chin_y": 316.0, "neck": [28.0, 32.0, 37.0][build],
			"shoulder": [136.0, 154.0, 174.0][build], "shoulder_y": [424.0, 416.0, 408.0][build],
			"trap": [6.0, 12.0, 20.0][build], "open": [6.0, 12.0, 18.0][build]}
	if life == "youth":
		k["neck"] *= 0.9
		k["shoulder"] *= 0.9
		k["shoulder_y"] += 6.0
		k["trap"] *= 0.7
		if male:
			k["jaw_x"] = 56.0
			k["chin_x"] = 21.0
			k["chin_y"] = 319.0
	elif life == "elder":
		k["neck"] *= 0.94
		k["shoulder"] *= 0.95
	return k


# ---------------------------------------------------------------------------
# The layers
# ---------------------------------------------------------------------------

# Colours that fade from one shade to another, used by the layers below.
static func definitions(k):
	return "\n".join([
		'<defs>',
		'<clipPath id="round"><circle cx="256" cy="256" r="238"/></clipPath>',
		'<radialGradient id="sky" cx="256" cy="190" r="310" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>' % [k["sky"], k["sky_edge"]],
		'<linearGradient id="hair" x1="0" y1="60" x2="0" y2="430" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="%s"/><stop offset="0.3" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [k["hair_light"], k["hair"], k["hair_dark"]],
		'<linearGradient id="robe" x1="40" y1="0" x2="472" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="%s"/><stop offset="0.5" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [k["robe_light"], k["robe"], k["robe_dark"]],
		'<linearGradient id="skin" x1="176" y1="0" x2="340" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="%s"/><stop offset="0.45" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [k["skin_light"], k["skin"], k["shade"]],
		'</defs>',
	])


# The round picture behind the character: a night sky, a moon and far hills.
static func backdrop(k):
	return "\n".join([
		'<circle cx="256" cy="256" r="240" fill="url(#sky)"/>',
		'<g clip-path="url(#round)">',
		'<circle cx="384" cy="132" r="34" fill="#f4ecd4" fill-opacity="0.5"/>',
		'<circle cx="384" cy="132" r="46" fill="#f4ecd4" fill-opacity="0.1"/>',
		'<path d="M0,372 L92,236 L150,318 L214,214 L292,330 L368,246 L512,392 L512,512 L0,512 Z" fill="%s" fill-opacity="0.75"/>' % k["hill"],
		'<path d="M0,424 L120,330 L206,404 L318,318 L420,402 L512,350 L512,512 L0,512 Z" fill="%s" fill-opacity="0.8"/>' % k["sky_edge"],
		'</g>',
	])


# Neck, shoulders and chest. Clothes are drawn over most of it.
static func body(k):
	var n = k["neck"]
	var s = k["shoulder"]
	var y = k["shoulder_y"]
	var t = k["trap"]
	var top = k["jaw_y"] - 12.0
	var outline = "M%.1f,%.1f L%.1f,%.1f %s L%.1f,%.1f Z" % [256 - n, top, 256 - n - 2, y - 58,
		torso_outline(n, s, y, t), 256 + n, top]
	var layers = [path(outline, "url(#skin)")]
	# The shadow the jaw throws on the neck.
	layers.append('<path d="M%.1f,%.1f L%.1f,%.1f L%.1f,%.1f Q256,%.1f %.1f,%.1f Z" fill="%s" fill-opacity="0.55"/>' % [
		256 - n, top, 256 + n, top, 256 + n, k["chin_y"] + 14, k["chin_y"] + 52, 256 - n, k["chin_y"] + 14, k["shade"]])
	# The two muscles of the neck, on anyone who is not a small child.
	if k["life"] != "child":
		for side in [-1, 1]:
			layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="2.6" stroke-opacity="0.4" stroke-linecap="round"/>' % [
				256 + side * (n - 7), k["jaw_y"] + 16, 256 + side * 16, y - 76, 256 + side * 5, y - 44, k["deep"]])
	return "\n".join(layers)


# The line of the shoulders, from the left side of the neck, around the
# bottom of the picture, to the right side of the neck. The body and the
# clothes share it, so that cloth lies exactly on the shoulders.
static func torso_outline(n, s, y, t):
	return "C%.1f,%.1f %.1f,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,512 L%.1f,512 C%.1f,%.1f %.1f,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f" % [
		256 - n - 10, y - 30 - t, 256 - s + 72, y - 6 - t * 0.5, 256 - s + 30, y,
		256 - s + 4, y + 4, 256 - s - 16, y + 36, 256 - s - 20,
		256 + s + 20,
		256 + s + 16, y + 36, 256 + s - 4, y + 4, 256 + s - 30, y,
		256 + s - 72, y - 6 - t * 0.5, 256 + n + 10, y - 30 - t, 256 + n + 2, y - 58]


# A robe with a crossed collar. The collar opens further down the chest on
# a broad build.
static func clothes(k):
	var n = k["neck"]
	var s = k["shoulder"]
	var y = k["shoulder_y"]
	var left = Vector2(256 - n - 2, y - 58)     # where the collar leaves the neck
	var right = Vector2(256 + n + 2, y - 58)
	var meet = Vector2(250, y + k["open"])      # where the two sides cross
	# The upper side runs on past the crossing to the bottom of the picture.
	var end = right + (meet - right) * ((512.0 - right.y) / (meet.y - right.y))
	var robe = "M%.1f,%.1f %s Z" % [left.x, left.y, torso_outline(n, s, y, k["trap"])]
	var layers = [path(robe, "url(#robe)")]
	# Folds in the cloth, running out from the collar over each shoulder.
	for side in [-1, 1]:
		layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="3" stroke-opacity="0.45" stroke-linecap="round"/>' % [
			256 + side * (n + 30), y - 14, 256 + side * (s - 46), y + 34, 256 + side * (s - 20), y + 104, k["robe_dark"]])
		layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="2.4" stroke-opacity="0.35" stroke-linecap="round"/>' % [
			256 + side * (n + 54), y + 26, 256 + side * (s - 70), y + 62, 256 + side * (s - 64), y + 112, k["robe_dark"]])
	if k["patched"]:
		layers.append('<path d="M%.1f,%.1f l34,-6 l8,30 l-36,8 Z" fill="%s" stroke="%s" stroke-width="2" stroke-dasharray="5 4"/>' % [
			256 + s - 110, y + 44, k["trim"], k["inner"]])
	# The chest that shows in the opening, with its shadows.
	layers.append('<path d="M%.1f,%.1f L%.1f,%.1f L%.1f,%.1f Z" fill="url(#skin)"/>' % [left.x, left.y, right.x, right.y, meet.x, meet.y])
	layers.append('<path d="M%.1f,%.1f L%.1f,%.1f L%.1f,%.1f Z" fill="%s" fill-opacity="0.28"/>' % [
		right.x, right.y, meet.x, meet.y, meet.x + (right.x - meet.x) * 0.45, right.y + 4, k["shade"]])
	if k["open"] > 20:
		# Collarbones, and the line down the middle of a strong chest.
		for side in [-1, 1]:
			layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="2.6" stroke-opacity="0.45" stroke-linecap="round"/>' % [
				253 + side * 7, y - 32, 253 + side * 24, y - 41, 253 + side * (n - 12), y - 38, k["deep"]])
		layers.append('<path d="M253,%.1f L%.1f,%.1f" fill="none" stroke="%s" stroke-width="2.4" stroke-opacity="0.4" stroke-linecap="round"/>' % [
			y - 22, meet.x + 1, meet.y - 20, k["deep"]])
		if k["open"] > 50:
			for side in [-1, 1]:
				layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="2.4" stroke-opacity="0.32" stroke-linecap="round"/>' % [
					252 + side * 5, meet.y - 24, 252 + side * 20, meet.y - 20, 252 + side * 30, meet.y - 34, k["deep"]])
	else:
		# A closed collar shows the edge of the robe worn underneath.
		layers.append('<path d="M%.1f,%.1f L%.1f,%.1f L%.1f,%.1f" fill="none" stroke="%s" stroke-width="9" stroke-linejoin="round"/>' % [
			left.x + 7, left.y + 3, meet.x, meet.y - 13, right.x - 7, right.y + 3, k["inner"]])
	# The collar itself: the band along both edges, and where it stands up beside the neck.
	layers.append('<path d="M%.1f,%.1f L%.1f,%.1f" fill="none" stroke="%s" stroke-width="17" stroke-linecap="round"/>' % [left.x, left.y, meet.x, meet.y, k["trim"]])
	layers.append('<path d="M%.1f,%.1f L%.1f,%.1f" fill="none" stroke="%s" stroke-width="17" stroke-linecap="round"/>' % [right.x, right.y, end.x, end.y, k["trim"]])
	layers.append('<path d="M%.1f,%.1f L%.1f,%.1f" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.7"/>' % [
		right.x - 7, right.y + 5, end.x - 9, end.y, k["trim_dark"]])
	for side in [-1, 1]:
		layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="13" stroke-linecap="round"/>' % [
			256 + side * (n + 2), y - 58, 256 + side * (n + 3), y - 70, 256 + side * (n - 3), y - 80, k["trim"]])
	return "\n".join(layers)


# The face without its features: ears, the shape of the head, and shading.
static func head(k):
	var jx = k["jaw_x"]
	var jy = k["jaw_y"]
	var cx = k["chin_x"]
	var cy = k["chin_y"]
	var shape = "M180,212 C180,146 210,100 256,100 C302,100 332,146 332,212 C332,244 %.1f,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f Q256,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f C%.1f,%.1f 180,244 180,212 Z" % [
		256 + jx + 8, jy - 18, 256 + jx, jy,
		256 + jx - 10, jy + 18, 256 + cx + 14, cy - 3, 256 + cx, cy,
		cy + 9, 256 - cx, cy,
		256 - cx - 14, cy - 3, 256 - jx + 10, jy + 18, 256 - jx, jy,
		256 - jx - 8, jy - 18]
	var ear_y = k["eye_y"] + 16
	var layers = []
	for side in [-1, 1]:
		layers.append('<ellipse cx="%.1f" cy="%.1f" rx="11" ry="21" fill="%s"/>' % [256 + side * 78, ear_y, k["skin"] if side < 0 else k["shade"]])
		layers.append('<path d="M%.1f,%.1f q%.1f,10 0,24" fill="none" stroke="%s" stroke-width="2.4" stroke-opacity="0.6" stroke-linecap="round"/>' % [
			256 + side * 80, ear_y - 12, side * -7.0, k["deep"]])
	layers.append(path(shape, "url(#skin)"))
	# The side of the face away from the light, and the shadow of the hair on the forehead.
	layers.append('<path d="M332,212 C332,244 %.1f,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f C312,240 318,222 332,212 Z" fill="%s" fill-opacity="0.2"/>' % [
		256 + jx + 8, jy - 18, 256 + jx, jy,
		256 + jx - 10, jy + 18, 256 + cx + 14, cy - 3, 256 + cx, cy,
		256 + cx + 8, cy - 20, 256 + jx - 24, jy - 4, 256 + jx - 20, jy - 40, k["deep"]])
	layers.append('<path d="M186,174 C200,146 226,136 256,136 C286,136 312,146 326,174 C312,160 286,152 256,152 C226,152 200,160 186,174 Z" fill="%s" fill-opacity="0.3"/>' % k["deep"])
	if k["male"] and k["life"] != "child":
		# The hollow under a man's cheekbone.
		for side in [-1, 1]:
			layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="7" stroke-opacity="0.13" stroke-linecap="round"/>' % [
				256 + side * (jx + 6), jy - 36, 256 + side * (jx - 8), jy - 12, 256 + side * (jx - 26), jy + 8, k["deep"]])
	else:
		# A little colour in the cheeks.
		for side in [-1, 1]:
			layers.append('<ellipse cx="%.1f" cy="%.1f" rx="17" ry="10" fill="#e0706c" fill-opacity="0.16"/>' % [256 + side * 46, k["eye_y"] + 30])
	if k["life"] == "elder":
		# The lines of a long life.
		layers.append('<path d="M222,166 Q256,159 290,166 M230,178 Q256,172 282,178" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.4" stroke-linecap="round"/>' % k["deep"])
		for side in [-1, 1]:
			layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="2.2" stroke-opacity="0.42" stroke-linecap="round"/>' % [
				256 + side * 20, k["nose_y"] - 2, 256 + side * 31, k["nose_y"] + 14, 256 + side * 27, k["mouth_y"] + 6, k["deep"]])
			layers.append('<path d="M%.1f,%.1f l%.1f,-4 M%.1f,%.1f l%.1f,3" fill="none" stroke="%s" stroke-width="1.8" stroke-opacity="0.4" stroke-linecap="round"/>' % [
				256 + side * 64, k["eye_y"] + 2, side * 9.0, 256 + side * 64, k["eye_y"] + 7, side * 9.0, k["deep"]])
			layers.append('<path d="M%.1f,%.1f q%.1f,6 %.1f,2" fill="none" stroke="%s" stroke-width="1.8" stroke-opacity="0.35" stroke-linecap="round"/>' % [
				256 + side * 22, k["eye_y"] + 16, side * 12.0, side * 26.0, k["deep"]])
	return "\n".join(layers)


# Eyebrows, eyes, nose and mouth.
static func face(k):
	var size = EYE_SIZES[k["look"]["eyes"]]
	var w = size[0]
	var h = size[1]
	var lift = size[2]
	if not k["male"]:
		w += 1.0
		h += 1.5
	if k["life"] == "child":
		w += 2.0
		h += 3.5
		lift = min(lift, 2.0)
	var ey = k["eye_y"]
	var layers = []
	for side in [-1, 1]:
		var x = 256 + side * EYE_APART
		var outer = Vector2(x + side * w, ey - lift)
		var inner = Vector2(x - side * w, ey + 2)
		var upper = "M%.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f" % [outer.x, outer.y,
			x + side * w * 0.45, ey - h - lift * 0.6, x - side * w * 0.35, ey - h, inner.x, inner.y]
		var lower = "C%.1f,%.1f %.1f,%.1f %.1f,%.1f Z" % [x - side * w * 0.45, ey + h * 0.7,
			x + side * w * 0.5, ey + h * 0.75, outer.x, outer.y]
		var clip = "eye_left" if side < 0 else "eye_right"
		var iris = h + 2.5
		layers.append('<clipPath id="%s"><path d="%s %s"/></clipPath>' % [clip, upper, lower])
		layers.append('<path d="%s %s" fill="#f6f2ea"/>' % [upper, lower])
		layers.append('<g clip-path="url(#%s)">' % clip)
		layers.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [x, ey - 1, iris, k["eye_dark"]])
		layers.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [x, ey - 1, iris - 2.2, k["eye"]])
		layers.append('<path d="M%.1f,%.1f a%.1f,%.1f 0 0 0 %.1f,0 Z" fill="%s" fill-opacity="0.75"/>' % [
			x - iris + 2.2, ey - 1, iris - 2.2, iris - 2.2, (iris - 2.2) * 2, k["eye_light"]])
		layers.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#0c0a0d"/>' % [x, ey - 1, iris * 0.42])
		layers.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#000000" fill-opacity="0.28"/>' % [x - w - 2, ey - h - 8, w * 2 + 4, h * 0.75 + 8])
		layers.append('</g>')
		layers.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffffff" fill-opacity="0.95"/>' % [x - 3.6, ey - 3.6, max(h * 0.24, 2.0)])
		layers.append('<circle cx="%.1f" cy="%.1f" r="1.3" fill="#ffffff" fill-opacity="0.7"/>' % [x + 3.6, ey + 1.6])
		# The lashes above, a faint line below, and the fold of the eyelid.
		layers.append('<path d="%s" fill="none" stroke="#1a1210" stroke-width="%.1f" stroke-linecap="round"/>' % [upper, 4.2 if k["male"] else 4.8])
		layers.append('<path d="M%.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="1.5" stroke-opacity="0.55" stroke-linecap="round"/>' % [
			outer.x, outer.y, x + side * w * 0.5, ey + h * 0.75, x - side * w * 0.1, ey + h * 0.74, x - side * w * 0.5, ey + h * 0.5, k["deep"]])
		layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" stroke-width="1.6" stroke-opacity="0.5" stroke-linecap="round"/>' % [
			x + side * (w - 3), ey - lift - 5, x, ey - h - 7, x - side * (w - 5), ey - 4, k["deep"]])
		if not k["male"]:
			layers.append('<path d="M%.1f,%.1f l%.1f,-6" fill="none" stroke="#1a1210" stroke-width="3" stroke-linecap="round"/>' % [outer.x, outer.y, side * 7.0])
		# The eyebrow: thick near the nose and pointed at the far end.
		var thick = 2.4 if not k["male"] else (4.6 if k["life"] != "child" else 3.0)
		var near = Vector2(x - side * (w - 1), ey - h - (11 if k["male"] else 14))
		var far = Vector2(x + side * (w + 7), ey - h - 15 - lift * 0.9)
		var arch = Vector2(x + side * 5, min(near.y, far.y) - (3 if k["male"] else 6))
		layers.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f Q%.1f,%.1f %.1f,%.1f Z" fill="%s"/>' % [
			near.x, near.y - thick, arch.x, arch.y - thick, far.x, far.y,
			arch.x, arch.y + thick * 0.9, near.x, near.y + thick, k["brow"]])

	# The nose: a shadow down one side of it, and the curve under its tip.
	var ny = k["nose_y"]
	if k["male"] and k["life"] != "child":
		layers.append('<path d="M259,%.1f L268,%.1f L259,%.1f Z" fill="%s" fill-opacity="0.2"/>' % [ey + 14, ny - 7, ny - 2, k["deep"]])
		layers.append('<path d="M251,%.1f C248,%.1f 242,%.1f 247,%.1f Q256,%.1f 266,%.1f" fill="none" stroke="%s" stroke-width="2.6" stroke-opacity="0.75" stroke-linecap="round"/>' % [
			ey + 16, ny - 22, ny - 10, ny - 3, ny + 5, ny - 3, k["deep"]])
	else:
		layers.append('<path d="M250,%.1f Q256,%.1f 263,%.1f" fill="none" stroke="%s" stroke-width="2.3" stroke-opacity="0.7" stroke-linecap="round"/>' % [ny - 4, ny + 3, ny - 4, k["deep"]])
		layers.append('<path d="M258,%.1f L263,%.1f" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.25" stroke-linecap="round"/>' % [ey + 18, ny - 10, k["deep"]])

	# The mouth.
	var my = k["mouth_y"]
	if k["life"] == "child":
		layers.append('<path d="M246,%.1f Q256,%.1f 266,%.1f" fill="none" stroke="%s" stroke-width="2.8" stroke-linecap="round"/>' % [my, my + 7, my, k["lip_dark"]])
	elif k["male"]:
		layers.append('<path d="M240,%.1f Q256,%.1f 272,%.1f Q256,%.1f 240,%.1f Z" fill="%s" fill-opacity="0.55"/>' % [my + 1, my + 12, my + 1, my + 3, my + 1, k["lip"]])
		layers.append('<path d="M237,%.1f Q247,%.1f 256,%.1f Q265,%.1f 275,%.1f" fill="none" stroke="%s" stroke-width="2.8" stroke-linecap="round"/>' % [my, my - 3.5, my - 1, my - 3.5, my, k["lip_dark"]])
		layers.append('<path d="M246,%.1f Q256,%.1f 266,%.1f" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.4" stroke-linecap="round"/>' % [my + 10, my + 13, my + 10, k["deep"]])
	else:
		layers.append('<path d="M240,%.1f Q248,%.1f 256,%.1f Q264,%.1f 272,%.1f Q256,%.1f 240,%.1f Z" fill="%s"/>' % [my, my - 6, my - 3, my - 6, my, my + 3, my, k["lip_dark"]])
		layers.append('<path d="M241,%.1f Q256,%.1f 271,%.1f Q256,%.1f 241,%.1f Z" fill="%s"/>' % [my + 1, my + 14, my + 1, my + 4, my + 1, k["lip"]])
		layers.append('<ellipse cx="258" cy="%.1f" rx="6" ry="2" fill="#ffffff" fill-opacity="0.3"/>' % [my + 6.5])
	return "\n".join(layers)


# A man's beard. Children have none, whatever was chosen.
static func beard(k):
	var kind = k["look"]["beard"]
	if kind == 0 or not k["male"] or k["life"] == "child" or k["life"] == "youth":
		return ""
	var my = k["mouth_y"]
	var cy = k["chin_y"]
	var moustache = '<path d="M233,%.1f Q245,%.1f 256,%.1f Q267,%.1f 279,%.1f Q267,%.1f 256,%.1f Q245,%.1f 233,%.1f Z" fill="%s"/>' % [
		my - 4, my - 13, my - 8, my - 13, my - 4, my - 5, my - 5, my - 5, my - 4, k["brow"]]
	if kind == 1:
		return "\n".join([
			'<path d="M197,%.1f C202,%.1f 228,%.1f 256,%.1f C284,%.1f 310,%.1f 315,%.1f C306,%.1f 284,%.1f 256,%.1f C228,%.1f 206,%.1f 197,%.1f Z" fill="%s" fill-opacity="0.24"/>' % [
				my - 30, cy - 14, cy + 6, cy + 7, cy + 6, cy - 14, my - 30, my, cy - 12, cy - 10, cy - 12, my, my - 30, k["brow"]],
			'<path d="M234,%.1f Q256,%.1f 278,%.1f Q256,%.1f 234,%.1f Z" fill="%s" fill-opacity="0.22"/>' % [my - 5, my - 14, my - 5, my - 6, my - 5, k["brow"]],
		])
	if kind == 2:
		return "\n".join([moustache,
			'<path d="M241,%.1f Q256,%.1f 271,%.1f Q270,%.1f 256,%.1f Q242,%.1f 241,%.1f Z" fill="%s"/>' % [
				my + 14, my + 10, my + 14, cy + 12, cy + 20, cy + 12, my + 14, k["brow"]],
		])
	return "\n".join([
		'<path d="M186,%.1f C188,%.1f 214,%.1f 256,%.1f C298,%.1f 324,%.1f 326,%.1f C320,%.1f 304,%.1f 282,%.1f C272,%.1f 240,%.1f 230,%.1f C208,%.1f 192,%.1f 186,%.1f Z" fill="%s"/>' % [
			my - 54, my, cy + 12, cy + 16, cy + 12, my, my - 54,
			my - 22, my + 4, my + 10, my + 2, my + 2, my + 10, my + 4, my - 22, my - 54, k["brow"]],
		moustache,
	])


# A scar, a beauty mark, or a mark of cinnabar on the forehead.
static func mark(k):
	var kind = k["look"]["mark"]
	var ey = k["eye_y"]
	if kind == 1:
		return '<path d="M199,%.1f L204,%.1f M209,%.1f L216,%.1f" fill="none" stroke="#a5524e" stroke-width="3.4" stroke-opacity="0.85" stroke-linecap="round"/><path d="M199,%.1f L204,%.1f M209,%.1f L216,%.1f" fill="none" stroke="#f3d6cc" stroke-width="1.2" stroke-opacity="0.8" stroke-linecap="round"/>' % [
			ey - 34, ey - 14, ey + 14, ey + 40, ey - 34, ey - 14, ey + 14, ey + 40]
	if kind == 2:
		return '<circle cx="303" cy="%.1f" r="2.8" fill="#2a1a15"/>' % [ey + 22]
	if kind == 3:
		return '<path d="M256,150 C249,160 249,171 256,178 C263,171 263,160 256,150 Z" fill="#c2302c"/><circle cx="244" cy="170" r="2.4" fill="#c2302c"/><circle cx="268" cy="170" r="2.4" fill="#c2302c"/>'
	return ""


# ---------------------------------------------------------------------------
# Hair. Each style gives two layers: "back" goes behind the body, "front"
# goes over the face and the clothes.
# ---------------------------------------------------------------------------

static func hair_layers(k):
	var style = k["look"]["hair"]
	var shine = '<path d="M206,122 Q256,99 306,122" fill="none" stroke="#ffffff" stroke-width="9" stroke-opacity="0.15" stroke-linecap="round"/>'
	var back = []
	var front = []
	if k["male"]:
		if style == 0:      # Topknot: hair tied up, held by a pin
			front = [hair(CAP_PEAK), shine,
				'<ellipse cx="256" cy="68" rx="31" ry="25" fill="url(#hair)"/>',
				'<path d="M236,58 Q256,46 276,58" fill="none" stroke="%s" stroke-width="5" stroke-opacity="0.6" stroke-linecap="round"/>' % k["hair_light"],
				'<rect x="233" y="86" width="46" height="11" rx="4" fill="%s"/>' % k["jade"],
				'<path d="M208,64 L304,76" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>' % k["gold"],
				'<circle cx="208" cy="64" r="6" fill="%s"/>' % k["gold"],
				side_locks(302, [-1, 1])]
		elif style == 1:    # Long and loose: parted in the middle, falling past the shoulders
			back = [hair("M166,210 C140,300 132,420 146,512 L366,512 C380,420 372,300 346,210 C330,112 182,112 166,210 Z")]
			front = [curtains(232), shine, long_locks()]
		elif style == 2:    # High ponytail, tied with red cord
			back = [hair("M268,68 C344,40 424,112 412,252 C406,342 386,412 374,482 C368,488 356,484 356,474 C372,382 376,272 344,172 C330,132 300,100 268,96 Z")]
			front = [hair(CAP), fringe(), shine,
				'<ellipse cx="274" cy="78" rx="18" ry="9" fill="%s" transform="rotate(-24 274 78)"/>' % k["red"],
				side_locks(292, [-1])]
		elif style == 3:    # Short and wild
			front = [hair("M170,216 L158,170 L178,176 L170,128 L194,146 L196,98 L220,122 L232,74 L254,108 L276,70 L290,112 L320,88 L316,130 L346,118 L334,160 L354,170 L342,216 C338,184 320,152 298,140 L286,166 L270,138 L252,172 L238,138 L220,164 L212,140 C192,154 176,186 170,216 Z"), shine]
		else:               # Headband: loose hair held back by a strip of cloth
			back = [hair("M168,206 C148,272 148,336 170,380 L342,380 C364,336 364,272 344,206 C330,112 182,112 168,206 Z")]
			front = [hair(CAP), shine,
				'<path d="M178,168 Q256,144 334,168 L334,186 Q256,162 178,186 Z" fill="%s"/>' % k["trim"],
				'<path d="M332,172 C356,192 364,234 354,276 L344,272 C352,236 346,204 326,186 Z" fill="%s"/>' % k["trim"],
				'<rect x="238" y="151" width="36" height="21" rx="4" fill="%s"/>' % k["gold"],
				'<rect x="244" y="156" width="24" height="11" rx="2" fill="none" stroke="%s" stroke-width="1.6"/>' % k["trim_dark"],
				side_locks(300, [-1, 1])]
	else:
		if style == 0:      # Bun and hairpin
			front = [hair(CAP), sweep(), shine,
				'<ellipse cx="256" cy="62" rx="39" ry="31" fill="url(#hair)"/>',
				'<path d="M230,50 Q256,34 282,50" fill="none" stroke="%s" stroke-width="6" stroke-opacity="0.55" stroke-linecap="round"/>' % k["hair_light"],
				'<path d="M206,48 L312,74" fill="none" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>' % k["gold"],
				'<circle cx="314" cy="75" r="7" fill="%s"/>' % k["red"],
				'<path d="M314,82 L314,112" fill="none" stroke="%s" stroke-width="2"/>' % k["gold"],
				'<path d="M314,110 l-5,10 l5,8 l5,-8 Z" fill="%s"/>' % k["jade"],
				side_locks(332, [-1, 1])]
		elif style == 1:    # Long and flowing, with a flower in it
			back = [hair("M160,200 C120,300 110,430 130,512 L382,512 C402,430 392,300 352,200 C332,104 180,104 160,200 Z")]
			front = [hair(CAP), sweep(), shine, long_locks(), flower(190, 152, k)]
		elif style == 2:    # Twin buns, with a straight fringe
			front = ['<circle cx="190" cy="88" r="31" fill="url(#hair)"/>', '<circle cx="322" cy="88" r="31" fill="url(#hair)"/>',
				hair(CAP),
				hair("M184,188 L184,170 C198,146 226,132 256,132 C286,132 314,146 328,170 L328,188 C310,181 288,178 256,178 C224,178 202,181 184,188 Z"),
				hair("M170,204 L191,200 L194,270 L175,270 Z"), hair("M342,204 L321,200 L318,270 L337,270 Z"), shine,
				'<path d="M168,112 l44,0 l-8,10 l-28,0 Z" fill="%s"/>' % k["red"],
				'<path d="M300,112 l44,0 l-8,10 l-28,0 Z" fill="%s"/>' % k["red"]]
		elif style == 3:    # High ponytail, tied with a ribbon
			back = [hair("M268,68 C344,40 424,112 412,252 C406,342 386,412 374,482 C368,488 356,484 356,474 C372,382 376,272 344,172 C330,132 300,100 268,96 Z")]
			front = [hair(CAP), sweep(), shine,
				'<path d="M272,78 l-30,-20 l6,26 Z" fill="%s"/>' % k["red"], '<path d="M272,78 l34,-12 l-10,26 Z" fill="%s"/>' % k["red"],
				'<circle cx="272" cy="78" r="7" fill="%s"/>' % k["gold"],
				side_locks(322, [-1])]
		else:               # Side braid over one shoulder
			front = [curtains(214), shine, braid(k), side_locks(318, [1])]
	return {"back": "\n".join(back), "front": "\n".join(front)}


# One piece of hair, filled with the hair colour.
static func hair(outline):
	return '<path d="%s" fill="url(#hair)"/>' % outline


# Thin locks in front of the ears. "reach" is how far down they hang, and
# "sides" is -1 for the left, 1 for the right, or both.
static func side_locks(reach, sides):
	var lock = hair(SIDE_LOCK % [reach, reach + 5, reach + 1, reach - 6])
	var layers = []
	for side in sides:
		layers.append(lock if side < 0 else mirrored(lock))
	return "\n".join(layers)


# Hair parted in the middle and swept to both sides. "reach" is how far
# down the sides come.
static func curtains(reach):
	var half = hair("M258,90 C212,94 172,140 168,%d C176,%d 186,%d 190,%d C202,180 228,150 258,128 Z" % [reach, reach + 6, reach + 2, reach - 10])
	return "\n".join([half, mirrored(half), '<path d="M256,92 L256,126" fill="none" stroke="#000000" stroke-width="2" stroke-opacity="0.35"/>'])


# Long locks that fall in front of the shoulders, down to the chest.
static func long_locks():
	var lock = hair("M178,212 C158,292 154,384 168,484 C180,490 196,486 198,474 C190,392 192,302 201,224 Z")
	return "\n".join([lock, mirrored(lock)])


# A fringe swept across the forehead from a parting on one side.
static func sweep():
	return "\n".join([
		hair("M292,94 C250,98 204,130 180,208 C186,216 196,214 202,204 C224,170 262,148 302,138 Z"),
		hair("M292,94 C318,104 336,142 339,208 C331,208 327,202 325,196 C319,168 309,150 298,138 Z"),
	])


# A choppy fringe of loose strands.
static func fringe():
	return hair("M188,166 C194,144 212,132 226,134 L220,182 L238,138 L250,190 L262,138 L280,184 L288,134 C304,134 320,146 324,166 C312,146 286,130 256,130 C226,130 200,146 188,166 Z")


# A braid that hangs over the left shoulder, tied at its end.
static func braid(k):
	var layers = []
	for i in 9:
		var x = 188 - i * 1.2 + (4 if i % 2 == 0 else -4)
		layers.append('<ellipse cx="%.1f" cy="%.1f" rx="16" ry="15" fill="url(#hair)" stroke="%s" stroke-width="1.5" stroke-opacity="0.7"/>' % [x, 246 + i * 22.0, k["hair_dark"]])
	layers.append('<rect x="166" y="434" width="30" height="11" rx="4" fill="%s"/>' % k["red"])
	layers.append(hair("M170,446 L192,446 L186,486 L176,486 Z"))
	return "\n".join(layers)


# A small five-petalled flower worn in the hair.
static func flower(x, y, k):
	var layers = []
	for i in 5:
		var angle = TAU * i / 5.0 - PI / 2
		layers.append('<circle cx="%.1f" cy="%.1f" r="7.5" fill="#f2a9c4"/>' % [x + cos(angle) * 9.0, y + sin(angle) * 9.0])
	layers.append('<circle cx="%.1f" cy="%.1f" r="4.5" fill="%s"/>' % [x, y, k["gold"]])
	return "\n".join(layers)


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

# A filled shape.
static func path(outline, fill):
	return '<path d="%s" fill="%s"/>' % [outline, fill]


# The same drawing flipped to the other side of the face.
static func mirrored(drawing):
	return '<g transform="translate(512 0) scale(-1 1)">%s</g>' % drawing


# A colour written as text, such as "#c9a961".
static func hx(colour):
	return "#" + colour.to_html(false)


# Small cel highlights and robe embroidery remain crisp at phone resolution.
static func anime_finish(k):
	var layers = []
	for side in [-1, 1]:
		var x = 256 + side * (k["shoulder"] - 64)
		var y = k["shoulder_y"] + 44
		layers.append('<path d="M%.1f,%.1f l12,-12 l12,12 l-12,12 Z M%.1f,%.1f l0,16" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.65"/>' % [x - 12, y, x, y + 14, k["trim"]])
		layers.append('<path d="M%.1f,%.1f l10,-2" fill="none" stroke="#fff6ed" stroke-width="3" stroke-linecap="round" stroke-opacity="0.4"/>' % [256 + side * 58 - 5, k["eye_y"] + 37])
	layers.append('<path d="M34,200 A230,230 0 0 1 180,38 M333,475 A230,230 0 0 0 478,307" fill="none" stroke="#9ae8ed" stroke-width="2" stroke-opacity="0.6"/>')
	layers.append('<path d="M256,18 l9,13 l-9,13 l-9,-13 Z" fill="#e4c887" stroke="#3d3243" stroke-width="2"/>')
	return "\n".join(layers)
