extends SceneTree

# Draws the character layers into res://assets/character/.
# Run from the project folder with:
#   godot --headless --script res://tools/make_character.gd
#
# Every picture is 512x512 with a transparent background, and every picture is
# drawn in the same coordinates, so the layers line up when stacked:
#   skin (bottom)  ->  eyes  ->  hair (top)
#
# The art is written as SVG shapes. {base}, {shade} and so on are replaced with
# the colours below, which is how one drawing becomes several colour choices.
# To add a colour, add one line to the right list and run this script again.
# You don't need this script to play the game.

const OUT = "res://assets/character/"

var skin_colors = {
	"light": {"base": "#f7dcc6", "shade": "#e6b59e", "line": "#6b4034"},
	"medium": {"base": "#dda87e", "shade": "#c0845f", "line": "#54301f"},
	"dark": {"base": "#94603f", "shade": "#74452b", "line": "#33190e"},
}

var eye_colors = {
	"brown": {"iris": "#9a643a", "dark": "#55301a", "light": "#d39a5e"},
	"blue": {"iris": "#4f93dc", "dark": "#24518f", "light": "#9fd4f7"},
	"green": {"iris": "#56a968", "dark": "#28663a", "light": "#a5e0a0"},
	"red": {"iris": "#d5463e", "dark": "#84201d", "light": "#f59a80"},
}

var hair_colors = {
	"black": {"base": "#2d2d3a", "shade": "#1a1a23", "hi": "#50526a", "line": "#0d0d13"},
	"brown": {"base": "#74503a", "shade": "#523423", "hi": "#9a7152", "line": "#2c190f"},
	"blonde": {"base": "#ebca72", "shade": "#c9a04b", "hi": "#f8e7a6", "line": "#6e5220"},
	"red": {"base": "#b8432f", "shade": "#89291d", "hi": "#de7253", "line": "#4b130d"},
	"white": {"base": "#eceef4", "shade": "#c2c8d8", "hi": "#ffffff", "line": "#6a718a"},
}

const HEADER = '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><g transform="translate(256 215) scale(1.15) translate(-256 -215)" stroke-linejoin="round" stroke-linecap="round">'
const FOOTER = '</g></svg>'
const MIRROR = '<g transform="translate(512 0) scale(-1 1)">'

const FACE = "M 170 196 C 166 118 210 86 256 86 C 302 86 346 118 342 196 C 342 228 338 250 330 266 C 318 290 290 314 268 322 C 260 325 252 325 244 322 C 222 314 194 290 182 266 C 174 250 170 228 170 196 Z"

const EAR = """
<path d="M 178 204 C 158 194 146 214 152 238 C 156 254 168 264 180 256 Z" fill="{base}" stroke="{line}" stroke-width="5"/>
<path d="M 170 218 C 161 222 161 238 169 246" fill="none" stroke="{shade}" stroke-width="4"/>
"""

const SKIN = """
<path d="M 222 286 L 222 366 C 218 386 188 398 150 408 C 106 420 80 442 72 484 L 68 530 L 444 530 L 440 484 C 432 442 406 420 362 408 C 324 398 294 386 290 366 L 290 286 Z" fill="{base}" stroke="{line}" stroke-width="5"/>
<path d="M 225 300 L 287 300 L 287 346 C 276 372 236 372 225 346 Z" fill="{shade}"/>
<path d="M 238 420 C 216 427 192 427 170 421" fill="none" stroke="{shade}" stroke-width="4"/>
<path d="M 274 420 C 296 427 320 427 342 421" fill="none" stroke="{shade}" stroke-width="4"/>
{ears}
<path d="{face}" fill="{base}"/>
<path d="M 342 196 C 342 228 338 250 330 266 C 318 290 290 314 268 322 C 262 324 258 325 256 325 C 284 312 306 290 316 264 C 324 244 328 220 328 196 Z" fill="{shade}"/>
<path d="{face}" fill="none" stroke="{line}" stroke-width="5"/>
<path d="M 258 258 L 263 273 L 254 275 Z" fill="{shade}"/>
<path d="M 257 252 C 255 262 252 268 249 272 L 255 275" fill="none" stroke="{line}" stroke-width="3"/>
<path d="M 238 297 C 248 302 264 302 274 297" fill="none" stroke="{line}" stroke-width="3"/>
<path d="M 250 308 C 254 310 258 310 262 308" fill="none" stroke="{shade}" stroke-width="3"/>
"""

# One eye (the one on the left of the picture). The other is a mirror image.
const EYE = """
<g clip-path="url(#eye)">
<path d="M 190 228 C 198 212 220 206 238 217 L 238 232 C 226 241 204 241 190 228 Z" fill="#fbfbfd"/>
<ellipse cx="214" cy="224" rx="14" ry="16" fill="{dark}"/>
<ellipse cx="214" cy="227" rx="11.5" ry="12" fill="{iris}"/>
<ellipse cx="214" cy="225" rx="5.5" ry="8" fill="#1b151b"/>
<ellipse cx="214" cy="234" rx="7" ry="3.5" fill="{light}"/>
<path d="M 190 228 C 198 212 220 206 238 217 L 238 222 C 220 212 200 217 192 229 Z" fill="#1b151b" fill-opacity="0.25"/>
</g>
<path d="M 187 229 C 196 209 220 203 240 216" fill="none" stroke="#221c24" stroke-width="6"/>
<path d="M 188 229 L 179 221 L 192 219 Z" fill="#221c24" stroke="#221c24" stroke-width="2"/>
<path d="M 198 238 C 208 242 222 242 232 237" fill="none" stroke="#221c24" stroke-width="2.5" stroke-opacity="0.7"/>
<path d="M 196 206 C 206 199 224 198 236 204" fill="none" stroke="#3a2a2a" stroke-width="2.5" stroke-opacity="0.4"/>
<path d="M 184 197 C 198 186 222 187 242 197 L 241 203 C 222 194 200 193 186 202 Z" fill="#2a2228" stroke="#2a2228" stroke-width="2"/>
"""

const EYES = """
<defs><clipPath id="eye"><path d="M 190 228 C 198 212 220 206 238 217 L 238 232 C 226 241 204 241 190 228 Z"/></clipPath></defs>
{eye}
{mirror}{eye}</g>
<circle cx="209" cy="219" r="4" fill="#ffffff"/>
<circle cx="219" cy="230" r="2" fill="#ffffff"/>
<circle cx="293" cy="219" r="4" fill="#ffffff"/>
<circle cx="303" cy="230" r="2" fill="#ffffff"/>
"""

const CAP = "M 180 292 C 170 266 160 240 158 214 C 150 196 144 172 150 146 C 154 106 188 70 240 62 C 262 58 292 60 312 70 C 346 86 364 124 364 160 C 364 184 360 200 356 216 C 354 244 346 270 334 294 C 334 268 331 240 330 216 C 329 196 328 178 326 162 Q 324 180 314 190 Q 310 162 300 140 Q 298 172 284 192 Q 278 158 264 130 Q 266 176 252 204 Q 244 168 228 140 Q 228 172 208 190 Q 204 170 194 156 C 190 176 185 196 184 214 C 183 240 182 266 180 292 Z"

const HAIR = """
<path d="M 292 76 C 318 34 380 40 408 84 C 436 130 440 210 426 276 C 416 326 398 376 374 412 C 384 364 390 306 386 250 C 382 190 368 140 340 104 Z" fill="{base}" stroke="{line}" stroke-width="5"/>
<path d="M 340 104 C 368 140 382 190 386 250 C 390 306 384 364 374 412 C 396 366 404 300 400 244 C 396 184 380 136 352 104 Z" fill="{shade}"/>
<path d="M 336 62 C 378 74 408 140 412 232" fill="none" stroke="{line}" stroke-width="2.5" stroke-opacity="0.5"/>
<path d="M 300 80 L 324 52 L 340 64 L 316 92 Z" fill="#3b8a8f" stroke="#17373a" stroke-width="4"/>
<path d="{cap}" fill="{base}"/>
<path d="M 312 70 C 346 86 364 124 364 160 C 364 184 360 200 356 216 C 354 244 346 270 334 294 C 340 262 344 236 344 214 C 348 190 350 170 348 150 C 344 116 332 90 312 70 Z" fill="{shade}"/>
<path d="M 180 138 C 202 114 232 103 262 105 C 292 103 320 112 342 134 L 336 142 L 326 128 L 318 138 L 304 122 L 296 134 L 278 118 L 268 132 L 254 118 L 244 132 L 228 122 L 220 136 L 206 130 L 198 144 L 190 140 Z" fill="{hi}" fill-opacity="0.8"/>
<path d="M 272 66 C 266 90 263 110 264 130" fill="none" stroke="{line}" stroke-width="2.5" stroke-opacity="0.55"/>
<path d="M 240 72 C 228 96 224 118 228 140" fill="none" stroke="{line}" stroke-width="2.5" stroke-opacity="0.55"/>
<path d="M 206 90 C 196 112 192 134 194 156" fill="none" stroke="{line}" stroke-width="2.5" stroke-opacity="0.55"/>
<path d="M 300 74 C 304 98 304 120 300 140" fill="none" stroke="{line}" stroke-width="2.5" stroke-opacity="0.55"/>
<path d="M 330 96 C 334 118 332 140 326 162" fill="none" stroke="{line}" stroke-width="2.5" stroke-opacity="0.55"/>
<path d="{cap}" fill="none" stroke="{line}" stroke-width="5"/>
"""


func _init():
	var skin = SKIN.format({"ears": EAR + MIRROR + EAR + "</g>", "face": FACE})
	var eyes = EYES.format({"eye": EYE, "mirror": MIRROR})
	var hair = HAIR.format({"cap": CAP})
	for color in skin_colors:
		save("skin/%s.png" % color, skin.format(skin_colors[color]))
	for color in eye_colors:
		save("eyes/%s.png" % color, eyes.format(eye_colors[color]))
	for color in hair_colors:
		save("hair/%s.png" % color, hair.format(hair_colors[color]))
	quit()


func save(file, art):
	var image = Image.new()
	var error = image.load_svg_from_string(HEADER + art + FOOTER)
	if error != OK:
		print("Could not draw ", file)
		return
	DirAccess.make_dir_recursive_absolute((OUT + file).get_base_dir())
	image.save_png(OUT + file)
	print("Saved ", OUT + file)
