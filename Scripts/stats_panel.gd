extends CanvasLayer

# Stats panel that appears over the pause menu

signal closed

@onready var panel: PanelContainer = $PanelContainer
@onready var stats_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/StatsList
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

var update_timer: float = 0.0

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func _process(delta: float) -> void:
	if not visible:
		return
	# Refresh stats every 0.5s while open
	update_timer -= delta
	if update_timer <= 0:
		update_timer = 0.5
		refresh_stats()

func show_stats() -> void:
	visible = true
	refresh_stats()

func hide_stats() -> void:
	visible = false

func _on_close_pressed() -> void:
	hide_stats()
	closed.emit()

func refresh_stats() -> void:
	# Clear existing stat rows
	for child in stats_list.get_children():
		child.queue_free()
	
	# Build stat entries
	var stats = [
		["Play Time", GameStats.get_play_time_formatted()],
		["", ""],  # separator
		["Enemies Killed", str(GameStats.enemies_killed)],
		["Damage Dealt", str(GameStats.damage_dealt)],
		["Damage Taken", str(GameStats.damage_taken)],
		["Deaths", str(GameStats.deaths)],
		["", ""],  # separator
		["Trees Chopped", str(GameStats.trees_chopped)],
		["Rocks Mined", str(GameStats.rocks_mined)],
		["Bushes Destroyed", str(GameStats.bushes_destroyed)],
		["", ""],  # separator
		["Items Collected", str(GameStats.items_collected)],
		["Coins Collected", str(GameStats.coins_collected)],
		["Hearts Collected", str(GameStats.hearts_collected)],
		["", ""],  # separator
		["Items Placed", str(GameStats.items_placed)],
		["Walls Placed", str(GameStats.walls_placed)],
		["Items Picked Up", str(GameStats.items_picked_up)],
		["", ""],  # separator
		["Distance Traveled", GameStats.get_distance_formatted()],
	]
	
	for entry in stats:
		if entry[0] == "":
			# Add separator
			var sep = HSeparator.new()
			sep.add_theme_constant_override("separation", 4)
			stats_list.add_child(sep)
		else:
			_add_stat_row(entry[0], entry[1])

func _add_stat_row(label_text: String, value_text: String) -> void:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var value = Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.modulate = Color(0.9, 0.85, 0.5)  # Gold-ish color for values
	
	row.add_child(label)
	row.add_child(value)
	stats_list.add_child(row)
