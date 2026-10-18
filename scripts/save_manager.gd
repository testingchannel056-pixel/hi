extends RefCounted

# Writes a life to a file and reads it back.
#
# The save is plain JSON, so it can be opened in any text editor. In Godot,
# Project > Open User Data Folder shows where it is kept.
#
# What goes into the save is decided by life_data() in game.gd. This script
# only looks after the file.

const SAVE_FILE = "life.json"
const BACKUP_FILE = "life_backup.json"   # the save before the newest one
const NEW_FILE = "life_new.json"         # only exists while a save is being written
const FOLDER = "user://"
const VERSION = 1   # raise this when a later change needs old saves to be converted


static func has_life():
	return load_life() != null


# Saves a life. Returns true if it worked.
static func save_life(data):
	# Write to a spare file first. If the game is closed halfway through, the
	# save that was already there is still whole.
	var file = FileAccess.open(FOLDER + NEW_FILE, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	# Then the old save becomes the backup, and the new file becomes the save.
	var folder = DirAccess.open(FOLDER)
	if folder.file_exists(SAVE_FILE):
		if folder.file_exists(BACKUP_FILE):
			folder.remove(BACKUP_FILE)
		folder.rename(SAVE_FILE, BACKUP_FILE)
	return folder.rename(NEW_FILE, SAVE_FILE) == OK


# Returns the saved life, or null if there is none that can be read. If the
# newest save is missing or damaged, the next best one is used.
static func load_life():
	for file in [SAVE_FILE, NEW_FILE, BACKUP_FILE]:
		var data = read(FOLDER + file)
		if data != null:
			return data
	return null


static func read(path):
	if not FileAccess.file_exists(path):
		return null
	var json = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	var data = json.data
	if not data is Dictionary or not data.get("player") is Dictionary:
		return null
	return whole_numbers(data)


# Removes the saved life (when a life ends).
static func delete_life():
	var folder = DirAccess.open(FOLDER)
	for file in [SAVE_FILE, BACKUP_FILE, NEW_FILE]:
		if folder.file_exists(file):
			folder.remove(file)


# JSON turns every number into a decimal: 18 comes back as 18.0. The game
# counts in whole numbers, so this turns them back, however deep they sit.
static func whole_numbers(value):
	if value is float and value == floor(value):
		return int(value)
	if value is Array:
		for i in value.size():
			value[i] = whole_numbers(value[i])
	if value is Dictionary:
		for key in value:
			value[key] = whole_numbers(value[key])
	return value
