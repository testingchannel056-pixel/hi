@tool
extends EditorScript

# Optional tool: makes a PNG copy of every character layer.
#
# The layers in res://assets/character/ are SVG pictures. Godot uses them just
# like PNGs, so you don't need this to run the game. Use it only if you want
# PNG files, for example to paint over them in an art program.
#
# How to run: open this script in Godot's script editor, then File > Run.
# Afterwards, change FILE_TYPE to ".png" in scripts/character_visual.gd.

const FOLDER = "res://assets/character/"


func _run():
	for part in ["skin", "eyes", "hair"]:
		for file in DirAccess.get_files_at(FOLDER + part):
			if file.ends_with(".svg"):
				var image = Image.new()
				image.load_svg_from_string(FileAccess.get_file_as_string(FOLDER + part + "/" + file))
				image.save_png(FOLDER + part + "/" + file.replace(".svg", ".png"))
				print("Saved ", part, "/", file.replace(".svg", ".png"))
	EditorInterface.get_resource_filesystem().scan()
