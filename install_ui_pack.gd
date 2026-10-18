@tool
extends EditorScript

# Unpacks the UI pack zip from your Downloads folder into res://ui_pack/.
#
# HOW TO RUN IT (once)
#   1. In Godot, double-click this file in the FileSystem dock.
#   2. In the script editor's menu, choose File > Run (Ctrl+Shift+X).
#   3. Read what it says in the Output panel at the bottom, and wait while
#      Godot imports the new pictures and sounds.
#
# It only adds files and replaces files of the same name. It deletes nothing.
# When it has run, this file is no longer needed and can be deleted.

const ZIP = "C:/Users/testi/Downloads/ui_pack (2).zip"
const FOLDER = "ui_pack/"   # the folder inside the zip, and the folder it goes to in the project


func _run():
	var count = install(ZIP)
	if count > 0:
		print("UI pack: %d files unpacked into res://%s. Godot is importing them now." % [count, FOLDER])
		# Tells the editor to look at the project folder again and import what is new.
		EditorInterface.get_resource_filesystem().scan()


# Copies every file of the pack out of the zip. Returns how many were written.
func install(zip_path):
	var zip = ZIPReader.new()
	if zip.open(zip_path) != OK:
		print("UI pack: could not open %s. Is the zip still in your Downloads folder?" % zip_path)
		return 0
	var count = 0
	for file in zip.get_files():
		# Only the pack's own folder is unpacked, and folders themselves are skipped.
		if not file.begins_with(FOLDER) or file.ends_with("/") or file.contains(".."):
			continue
		var target = "res://" + file
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var out = FileAccess.open(target, FileAccess.WRITE)
		if out == null:
			print("UI pack: could not write %s" % target)
			continue
		out.store_buffer(zip.read_file(file))
		out.close()
		count += 1
	zip.close()
	if count == 0:
		print("UI pack: the zip has no \"%s\" folder in it, so nothing was unpacked." % FOLDER)
	return count
