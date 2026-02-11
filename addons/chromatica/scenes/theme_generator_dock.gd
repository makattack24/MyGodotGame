@tool
extends Control

@onready var colors_grid = $MainContainer/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/ScrollContainer/ColorsGrid
@onready var file_dialog = $FileDialog
@onready var generate_button = $MainContainer/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/ButtonsContainer/GenerateButton
@onready var save_button = $MainContainer/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/ButtonsContainer/SaveButton

var current_theme: Theme
var color_pickers: Dictionary = {}

var default_colors = {
	"base": Color("#15191e"),
	"primary": Color("#605dff"),
	"secondary": Color("#f43098"),
	"accent": Color("#00d3bb"),
	"neutral": Color("#191e24"),
	"info": Color("#00bafe"),
	"success": Color("#00d390"),
	"warning": Color("#fcb700"),
	"error": Color("#ff627d")
}

var presets = {
	"Default Dark": {
		"base": Color("#15191e"),
		"primary": Color("#605dff"),
		"secondary": Color("#f43098"),
		"accent": Color("#00d3bb"),
		"neutral": Color("#191e24"),
		"info": Color("#00bafe"),
		"success": Color("#00d390"),
		"warning": Color("#fcb700"),
		"error": Color("#ff627d")
	},
	"AMOLED Dark": {
		"base": Color("#000000"),
		"primary": Color("#8B5CF6"),
		"secondary": Color("#22D3EE"),
		"accent": Color("#F472B6"),
		"neutral": Color("#0A0A0A"),
		"info": Color("#38BDF8"),
		"success": Color("#22C55E"),
		"warning": Color("#FACC15"),
		"error": Color("#EF4444")
	},
	"Material You": {
		"base": Color("#1C1B1F"),
		"primary": Color("#D0BCFF"),
		"secondary": Color("#CCC2DC"),
		"accent": Color("#EFB8C8"),
		"neutral": Color("#938F99"),
		"info": Color("#90CAF9"),
		"success": Color("#81C784"),
		"warning": Color("#FFB74D"),
		"error": Color("#F2B8B5")
	},
	"Ocean Blue": {
		"base": Color("#0a1929"),
		"primary": Color("#3399ff"),
		"secondary": Color("#66b2ff"),
		"accent": Color("#5BE9B9"),
		"neutral": Color("#132f4c"),
		"info": Color("#00b0ff"),
		"success": Color("#00e676"),
		"warning": Color("#ffc107"),
		"error": Color("#f44336")
	},
	"Forest Green": {
		"base": Color("#1a2e1a"),
		"primary": Color("#4caf50"),
		"secondary": Color("#8bc34a"),
		"accent": Color("#00bcd4"),
		"neutral": Color("#263238"),
		"info": Color("#03a9f4"),
		"success": Color("#4caf50"),
		"warning": Color("#ff9800"),
		"error": Color("#f44336")
	},
	"Purple Haze": {
		"base": Color("#1e1428"),
		"primary": Color("#9c27b0"),
		"secondary": Color("#e91e63"),
		"accent": Color("#00e5ff"),
		"neutral": Color("#2a1f3d"),
		"info": Color("#29b6f6"),
		"success": Color("#66bb6a"),
		"warning": Color("#ffa726"),
		"error": Color("#ef5350")
	}
}


func _ready() -> void:
	_create_color_pickers()
	_generate_theme()
	save_button.disabled = true


func _create_color_pickers() -> void:
	var preset_container = VBoxContainer.new()
	preset_container.add_theme_constant_override("separation", 8)
	
	var preset_label = Label.new()
	preset_label.text = "Presets"
	preset_label.theme_type_variation = "LabelLarge"
	preset_container.add_child(preset_label)
	
	var preset_option = OptionButton.new()
	for preset_name in presets.keys():
		preset_option.add_item(preset_name)
	preset_option.selected = 0
	preset_option.item_selected.connect(_on_preset_selected)
	preset_container.add_child(preset_option)
	
	var separator = HSeparator.new()
	preset_container.add_child(separator)
	
	colors_grid.add_child(preset_container)
	
	for color_key in default_colors.keys():
		var container = HBoxContainer.new()
		container.add_theme_constant_override("separation", 12)
		
		var label = Label.new()
		label.text = color_key.capitalize()
		label.custom_minimum_size.x = 100
		label.theme_type_variation = "BodyMedium"
		container.add_child(label)
		
		var color_picker_button = ColorPickerButton.new()
		color_picker_button.color = default_colors[color_key]
		color_picker_button.custom_minimum_size = Vector2(120, 32)
		color_picker_button.edit_alpha = false
		container.add_child(color_picker_button)
		
		color_pickers[color_key] = color_picker_button
		colors_grid.add_child(container)


func _on_preset_selected(index: int) -> void:
	var preset_name = presets.keys()[index]
	var preset_colors = presets[preset_name]
	
	for color_key in preset_colors.keys():
		if color_pickers.has(color_key):
			color_pickers[color_key].color = preset_colors[color_key]
	
	_generate_theme()

func _get_current_colors() -> Dictionary:
	var colors = {}
	for color_key in color_pickers.keys():
		colors[color_key] = color_pickers[color_key].color
	return colors


func _generate_theme() -> void:
	generate_button.disabled = true
	generate_button.text = "Generation..."
	
	await get_tree().process_frame
	
	var colors = _get_current_colors()
	
	var font_regular: Font = null
	var font_medium: Font = null
	
	if FileAccess.file_exists("res://addons/chromatica/fonts/roboto/Roboto-Regular.ttf"):
		font_regular = load("res://addons/chromatica/fonts/roboto/Roboto-Regular.ttf")
	if FileAccess.file_exists("res://addons/chromatica/fonts/roboto/Roboto-Medium.ttf"):
		font_medium = load("res://addons/chromatica/fonts/roboto/Roboto-Medium.ttf")
	
	if font_regular == null:
		font_regular = SystemFont.new()
	if font_medium == null:
		font_medium = SystemFont.new()
	
	current_theme = ThemeGenerator.generate_theme(colors, font_regular, font_medium)
	theme = current_theme
	
	generate_button.disabled = false
	generate_button.text = "Generate"
	save_button.disabled = false
	
	print("✓ Theme generated successfully!")


func _on_generate_button_pressed() -> void:
	_generate_theme()


func _on_save_button_pressed() -> void:
	if current_theme == null:
		push_warning("There is no theme to save!")
		return
	
	file_dialog.current_dir = "res://"
	file_dialog.popup_centered()


func _on_file_dialog_dir_selected(dir: String) -> void:
	if current_theme == null:
		return
	
	var file_path = dir.path_join("material3_theme.tres")
	
	var file_exists = FileAccess.file_exists(file_path)
	if file_exists:
		print("⚠ The file already exists, overwriting...")
	
	var error = ResourceSaver.save(current_theme, file_path)
	if error == OK:
		print("✓ Theme saved:", file_path)
	else:
		push_error("✗ Error saving theme: ", error)
