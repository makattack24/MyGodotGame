# Scripts/day_night_cycle.gd
extends Node

@export var overlay_path: NodePath = NodePath("DayNightOverlay/DayNightOverlayRect")
@export var day_length: float = 300.0 # seconds for a full day cycle
@export var night_color: Color = Color(0, 0, 0.2, 0.5) # dark blue, semi-transparent
@export var dusk_color: Color = Color(0.2, 0.1, 0.2, 0.3) # purple-ish, less transparent
@export var dawn_color: Color = Color(0.8, 0.6, 0.3, 0.2) # orange, faint
@export var day_color: Color = Color(0, 0, 0, 0) # fully transparent (day)
@export var start_time: float = 0.25 # 0.0 = midnight, 0.5 = noon

var time_of_day: float = 0.0 # 0.0-1.0, where 1.0 is a full cycle

var overlay: ColorRect = null

func _ready():
	# Defer initialization to ensure the overlay node exists in the tree
	call_deferred("_init_overlay")

func _init_overlay():
	var node = get_node_or_null(overlay_path)
	if node == null:
		push_warning("DayNightOverlayRect node not found! Day/night cycle will not be visible.")
		overlay = null
	else:
		if node is ColorRect:
			overlay = node
		else:
			push_warning("Node at overlay_path is not a ColorRect!")
	time_of_day = start_time

func _process(delta):
	time_of_day = fmod(time_of_day + delta / day_length, 1.0)
	overlay.color = get_overlay_color(time_of_day)

func get_overlay_color(t: float) -> Color:
	# t: 0.0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk, 1.0 = midnight
	if t < 0.25:
		# Night to dawn
		return night_color.lerp(dawn_color, t / 0.25)
	elif t < 0.35:
		# Dawn to day
		return dawn_color.lerp(day_color, (t - 0.25) / 0.1)
	elif t < 0.65:
		# Day
		return day_color
	elif t < 0.75:
		# Day to dusk
		return day_color.lerp(dusk_color, (t - 0.65) / 0.1)
	elif t < 1.0:
		# Dusk to night
		return dusk_color.lerp(night_color, (t - 0.75) / 0.25)
	else:
		return night_color
