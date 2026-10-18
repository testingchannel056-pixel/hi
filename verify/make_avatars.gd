extends SceneTree

# Draws the five avatar portraits into res://avatars/.
# Run from the project folder with:
#   godot --headless --script res://tools/make_avatars.gd
# You don't need this to play the game. Replace the PNGs with your own art
# (32x32 pixels) any time you like.

const SIZE = 32
const OUTLINE = Color(0.09, 0.07, 0.1)
const SKIN = Color(0.96, 0.8, 0.66)
const SKIN_DARK = Color(0.83, 0.62, 0.5)
const BLUSH = Color(0.95, 0.6, 0.55)
const HAIR = Color(0.16, 0.15, 0.2)
const HAIR_LIGHT = Color(0.29, 0.28, 0.36)
const WHITE = Color(0.93, 0.93, 0.95)
const WHITE_DARK = Color(0.72, 0.73, 0.78)
const EYE = Color(0.12, 0.1, 0.14)
const GOLD = Color(0.85, 0.7, 0.4)

var img: Image


func _init():
	DirAccess.make_dir_recursive_absolute("res://avatars")
	save("baby", baby)
	save("child", child)
	save("youth", youth)
	save("adult", adult)
	save("elder", elder)
	quit()


func save(file_name, draw):
	img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	draw.call()
	outline()
	img.save_png("res://avatars/%s.png" % file_name)


# --- Drawing helpers ---

func px(x, y, c):
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		img.set_pixel(x, y, c)


# Draws a pixel and its mirror image on the other side of the face.
func mpx(x, y, c):
	px(x, y, c)
	px(SIZE - 1 - x, y, c)


func rect(x, y, w, h, c):
	for j in h:
		for i in w:
			px(x + i, y + j, c)


func mrect(x, y, w, h, c):
	rect(x, y, w, h, c)
	rect(SIZE - x - w, y, w, h, c)


# Filled ellipse. Only rows from y_min to y_max are drawn.
func ellipse(cx, cy, rx, ry, c, y_min = 0, y_max = SIZE):
	for y in range(max(y_min, 0), min(y_max + 1, SIZE)):
		for x in SIZE:
			var dx = (x + 0.5 - cx) / rx
			var dy = (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(x, y, c)


# Dark line around everything that has been drawn.
func outline():
	var copy = img.duplicate()
	for y in SIZE:
		for x in SIZE:
			if copy.get_pixel(x, y).a > 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < SIZE and n.y < SIZE and copy.get_pixel(n.x, n.y).a > 0:
					img.set_pixel(x, y, OUTLINE)
					break


# Head with a shaded lower edge.
func head(cy, rx, ry):
	ellipse(16, cy, rx, ry, SKIN_DARK)
	ellipse(16, cy - 1, rx, ry - 0.5, SKIN)


# Shoulders in a robe with a crossed collar.
func robe(width, color, dark, trim):
	ellipse(16, 33, width, 9, color)
	ellipse(16, 35, width - 2, 8, dark, 28)
	rect(14, 21, 4, 4, SKIN_DARK)
	for i in 7:
		mpx(12 + i / 2, 24 + i, trim)
		mpx(13 + i / 2, 24 + i, trim)
	rect(15, 24, 2, 3, SKIN_DARK)


func topknot(color, light, band):
	rect(14, 1, 4, 4, color)
	rect(15, 0, 2, 1, color)
	rect(14, 1, 1, 2, light)
	rect(13, 5, 6, 1, band)


# --- The five ages ---

func baby():
	# Swaddling cloth
	var cloth = Color(0.88, 0.82, 0.68)
	var cloth_dark = Color(0.72, 0.64, 0.5)
	ellipse(16, 31, 11, 8, cloth)
	for i in 8:
		mpx(8 + i, 25 + i, cloth_dark)
	head(15, 9.5, 9)
	# A little tuft of hair
	rect(15, 4, 2, 3, HAIR)
	mpx(14, 6, HAIR)
	# Big eyes
	mrect(10, 14, 3, 3, EYE)
	px(10, 14, WHITE)
	px(19, 14, WHITE)
	mrect(8, 18, 2, 1, BLUSH)
	rect(15, 20, 2, 1, Color(0.75, 0.38, 0.38))


func child():
	var tunic = Color(0.6, 0.4, 0.26)
	robe(10, tunic, Color(0.47, 0.3, 0.2), Color(0.86, 0.78, 0.6))
	head(14, 8.5, 8.5)
	# Two hair buns tied with red string
	ellipse(8, 4.5, 3, 3, HAIR)
	ellipse(24, 4.5, 3, 3, HAIR)
	mpx(7, 3, HAIR_LIGHT)
	# Fringe
	ellipse(16, 11, 9, 7, HAIR, 0, 10)
	mrect(7, 11, 2, 3, HAIR)
	rect(12, 6, 5, 1, HAIR_LIGHT)
	mrect(12, 11, 2, 1, HAIR)
	mrect(9, 7, 2, 1, Color(0.85, 0.27, 0.27))
	# Face
	mrect(11, 14, 2, 3, EYE)
	px(11, 14, WHITE)
	px(19, 14, WHITE)
	mrect(9, 18, 2, 1, BLUSH)
	rect(15, 19, 2, 1, Color(0.7, 0.36, 0.36))


func youth():
	robe(12, Color(0.25, 0.42, 0.66), Color(0.18, 0.31, 0.52), WHITE)
	head(14, 7.5, 9)
	topknot(HAIR, HAIR_LIGHT, Color(0.8, 0.25, 0.25))
	ellipse(16, 10.5, 8.2, 6, HAIR, 0, 9)
	rect(11, 7, 5, 1, HAIR_LIGHT)
	rect(13, 5, 6, 1, Color(0.85, 0.27, 0.27))
	# Side locks
	mrect(8, 10, 1, 8, HAIR)
	mrect(9, 10, 1, 3, HAIR)
	# Face
	mrect(10, 12, 3, 1, HAIR)
	mrect(11, 14, 2, 2, EYE)
	px(11, 14, WHITE)
	px(19, 14, WHITE)
	px(16, 17, SKIN_DARK)
	rect(14, 20, 4, 1, Color(0.68, 0.38, 0.36))


func adult():
	robe(13, Color(0.2, 0.22, 0.33), Color(0.14, 0.15, 0.24), GOLD)
	head(14, 7.5, 9.5)
	topknot(HAIR, HAIR_LIGHT, GOLD)
	# Hairpin through the topknot
	rect(10, 3, 12, 1, GOLD)
	ellipse(16, 10.5, 8.2, 6, HAIR, 0, 9)
	rect(11, 7, 5, 1, HAIR_LIGHT)
	rect(13, 5, 6, 1, GOLD)
	mrect(8, 10, 1, 6, HAIR)
	# Stern brows and narrow eyes
	mrect(10, 12, 4, 1, HAIR)
	mpx(13, 13, HAIR)
	mrect(11, 14, 2, 1, EYE)
	mrect(11, 15, 2, 1, SKIN_DARK)
	rect(16, 16, 1, 2, SKIN_DARK)
	rect(14, 20, 4, 1, Color(0.6, 0.36, 0.34))
	# Jaw shadow
	mpx(10, 20, SKIN_DARK)
	mpx(11, 21, SKIN_DARK)


func elder():
	robe(12, Color(0.5, 0.5, 0.56), Color(0.38, 0.38, 0.45), WHITE)
	head(14, 7.5, 9.5)
	topknot(WHITE, Color(1, 1, 1), Color(0.5, 0.36, 0.24))
	rect(11, 3, 10, 1, Color(0.5, 0.36, 0.24))
	# Receding white hair
	ellipse(16, 10, 8.2, 6, WHITE, 0, 7)
	mrect(8, 8, 1, 9, WHITE)
	mrect(9, 8, 1, 3, WHITE)
	rect(12, 5, 4, 1, Color(1, 1, 1))
	# Wrinkles
	rect(13, 9, 6, 1, SKIN_DARK)
	mrect(9, 16, 2, 1, SKIN_DARK)
	# Bushy brows and kind, narrow eyes
	mrect(9, 12, 4, 1, WHITE)
	mpx(9, 13, WHITE)
	mrect(11, 14, 2, 1, EYE)
	rect(16, 16, 1, 2, SKIN_DARK)
	# Moustache and long beard
	mrect(11, 19, 4, 1, WHITE)
	mpx(10, 20, WHITE)
	rect(15, 20, 2, 1, Color(0.6, 0.36, 0.34))
	ellipse(16, 23, 4.5, 6, WHITE, 21)
	rect(15, 29, 2, 1, WHITE)
	rect(15, 23, 1, 5, WHITE_DARK)
	mpx(13, 24, WHITE_DARK)
