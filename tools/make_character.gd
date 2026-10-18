@tool
extends EditorScript

# Optional tool: saves a PNG copy of the character sprite sheet.
#
# The sheet (res://assets/character/character_sheet.svg) is an SVG picture.
# Godot uses it just like a PNG, so you don't need this to run the game. Use
# it only if you want a PNG, for example to paint over it in an art program.
#
# How to run: open this script in Godot's script editor, then File > Run.
# To use the PNG afterwards, drag it onto the Texture of the three sprites in
# character_customization.tscn.

const SHEET = "res://assets/character/character_sheet.svg"


func _run():
	var image = Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string(SHEET))
	image.save_png(SHEET.replace(".svg", ".png"))
	print("Saved ", SHEET.replace(".svg", ".png"))
	EditorInterface.get_resource_filesystem().scan()
