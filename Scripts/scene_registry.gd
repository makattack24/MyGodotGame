extends Node

## Autoload that scans scene directories and registers them by name.
## Usage: SceneRegistry.get_scene("campfire") — no hardcoded paths needed.
## If you move/rename folders, just update the scan_dirs array below.

# Directories to scan for .tscn files (add more as needed)
var scan_dirs: Array[String] = [
	"res://Scenes/",
	"res://Scenes/ObjectScenes/",
	"res://Prefabs/",
]

# Internal registry: scene_name -> PackedScene
var _scenes: Dictionary = {}

func _ready() -> void:
	_scan_all_directories()
	print("[SceneRegistry] Registered ", _scenes.size(), " scenes: ", _scenes.keys())

func _scan_all_directories() -> void:
	for dir_path in scan_dirs:
		_scan_directory(dir_path)

func _scan_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_warning("[SceneRegistry] Could not open directory: " + dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var scene_key = file_name.get_basename()  # "campfire.tscn" -> "campfire"
			var full_path = dir_path.path_join(file_name)
			var scene = load(full_path)
			if scene:
				_scenes[scene_key] = scene
			else:
				push_warning("[SceneRegistry] Failed to load scene: " + full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

## Get a scene by name (without extension). Returns null if not found.
func get_scene(scene_name: String) -> PackedScene:
	if _scenes.has(scene_name):
		return _scenes[scene_name]
	push_warning("[SceneRegistry] Scene not found: " + scene_name)
	return null

## Check if a scene is registered.
func has_scene(scene_name: String) -> bool:
	return _scenes.has(scene_name)

## Get all registered scene names.
func get_all_scene_names() -> Array:
	return _scenes.keys()

## Manually register a scene (for dynamically created scenes).
func register_scene(scene_name: String, scene: PackedScene) -> void:
	_scenes[scene_name] = scene

## Re-scan all directories (useful after adding new scenes at runtime).
func refresh() -> void:
	_scenes.clear()
	_scan_all_directories()
