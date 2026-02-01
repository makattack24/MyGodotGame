extends Node

# Save file path
const SAVE_PATH = "user://savegame.save"

# Auto-save settings
@export var auto_save_enabled: bool = true
@export var auto_save_interval: float = 60.0  # Auto-save every 60 seconds

var auto_save_timer: Timer

func _ready() -> void:
	if auto_save_enabled:
		setup_auto_save()

func setup_auto_save() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.one_shot = false
	auto_save_timer.connect("timeout", Callable(self, "auto_save"))
	add_child(auto_save_timer)
	auto_save_timer.start()

func auto_save() -> void:
	save_game()
	print("Auto-saved game")
	# Show notification for auto-save
	var main = get_tree().root.find_child("Main", true, false)
	if main:
		var hud = main.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Auto-saved", 1.5)

func save_game() -> void:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("Error: Could not open save file for writing")
		return
	
	var save_data = {}
	
	# Get all nodes in the "persist" group
	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		# Check if the node has a save method
		if not node.has_method("save"):
			print("Persist node '%s' is missing a save() function, skipped" % node.name)
			continue
		
		# Call the node's save function
		var node_data = node.call("save")
		save_data[node.get_path()] = node_data
	
	# Convert to JSON and save
	var json_string = JSON.stringify(save_data)
	save_file.store_line(json_string)
	save_file.close()
	print("Game saved successfully")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found")
		return false
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		print("Error: Could not open save file for reading")
		return false
	
	var json_string = save_file.get_line()
	save_file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Error parsing save file")
		return false
	
	var save_data = json.get_data()
	
	# Load data into nodes
	for node_path in save_data.keys():
		var node = get_node_or_null(node_path)
		if node and node.has_method("load_data"):
			node.call("load_data", save_data[node_path])
	
	print("Game loaded successfully")
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
