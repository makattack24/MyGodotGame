extends Node

## Weather System - Manages weather states, transitions, and effects
## Add to group "WeatherSystem" so other scripts can find it.

signal weather_changed(new_weather: String, old_weather: String)

# ─── Weather Types ───
enum Weather {
	CLEAR,
	CLOUDY,
	RAIN,
	HEAVY_RAIN,
	THUNDERSTORM,
	SNOW,
	FOG,
	SANDSTORM,
}

# Human-readable names
const WEATHER_NAMES: Dictionary = {
	Weather.CLEAR: "Clear",
	Weather.CLOUDY: "Cloudy",
	Weather.RAIN: "Rain",
	Weather.HEAVY_RAIN: "Heavy Rain",
	Weather.THUNDERSTORM: "Thunderstorm",
	Weather.SNOW: "Snow",
	Weather.FOG: "Fog",
	Weather.SANDSTORM: "Sandstorm",
}

# Icon characters for HUD display
const WEATHER_ICONS: Dictionary = {
	Weather.CLEAR: "☀",
	Weather.CLOUDY: "☁",
	Weather.RAIN: "🌧",
	Weather.HEAVY_RAIN: "🌧",
	Weather.THUNDERSTORM: "⛈",
	Weather.SNOW: "❄",
	Weather.FOG: "🌫",
	Weather.SANDSTORM: "🌪",
}

# ─── Configuration ───
@export var min_weather_duration: float = 120.0   # Minimum seconds a weather lasts
@export var max_weather_duration: float = 360.0   # Maximum seconds
@export var transition_duration: float = 5.0      # Seconds to blend between weathers

# Biome-specific weather weights  {biome_name: {Weather enum : weight}}
var biome_weather_weights: Dictionary = {
	"Starter Plains": {
		Weather.CLEAR: 50, Weather.CLOUDY: 25, Weather.RAIN: 15,
		Weather.HEAVY_RAIN: 5, Weather.THUNDERSTORM: 3, Weather.FOG: 2,
	},
	"Forest": {
		Weather.CLEAR: 30, Weather.CLOUDY: 25, Weather.RAIN: 25,
		Weather.HEAVY_RAIN: 10, Weather.THUNDERSTORM: 5, Weather.FOG: 5,
	},
	"Tundra": {
		Weather.CLEAR: 25, Weather.CLOUDY: 25, Weather.SNOW: 35,
		Weather.FOG: 10, Weather.HEAVY_RAIN: 5,
	},
	"Taiga": {
		Weather.CLEAR: 20, Weather.CLOUDY: 25, Weather.RAIN: 15,
		Weather.SNOW: 25, Weather.FOG: 10, Weather.THUNDERSTORM: 5,
	},
	"Desert": {
		Weather.CLEAR: 55, Weather.CLOUDY: 15, Weather.SANDSTORM: 20,
		Weather.FOG: 5, Weather.RAIN: 5,
	},
	"Swamp": {
		Weather.CLEAR: 15, Weather.CLOUDY: 20, Weather.RAIN: 30,
		Weather.HEAVY_RAIN: 15, Weather.THUNDERSTORM: 10, Weather.FOG: 10,
	},
}

# Default weights when biome isn't in the table
var default_weights: Dictionary = {
	Weather.CLEAR: 40, Weather.CLOUDY: 25, Weather.RAIN: 20,
	Weather.HEAVY_RAIN: 8, Weather.THUNDERSTORM: 4, Weather.FOG: 3,
}

# ─── State ───
var current_weather: int = Weather.CLEAR
var previous_weather: int = Weather.CLEAR
var weather_timer: float = 0.0
var weather_duration: float = 180.0
var transition_progress: float = 1.0  # 1.0 = fully transitioned
var is_transitioning: bool = false
var current_biome: String = "Starter Plains"

# ─── Day tracking ───
var day_count: int = 1  # Starts on day 1
var last_day_time: float = -1.0

# Day-of-week names
const DAY_NAMES: Array = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

func _ready() -> void:
	add_to_group("WeatherSystem")
	# Pick an initial weather duration
	weather_duration = randf_range(min_weather_duration, max_weather_duration)
	weather_timer = 0.0

func _process(delta: float) -> void:
	# Track day changes via the DayNightCycle
	_update_day_count()
	
	# Weather timer
	weather_timer += delta
	if weather_timer >= weather_duration:
		weather_timer = 0.0
		_pick_next_weather()
	
	# Transition blending
	if is_transitioning:
		transition_progress += delta / transition_duration
		if transition_progress >= 1.0:
			transition_progress = 1.0
			is_transitioning = false

# ─── Day tracking ───
func _update_day_count() -> void:
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night and "time_of_day" in day_night:
		var t: float = day_night.time_of_day
		# Detect midnight crossing (time wraps from ~1.0 back to ~0.0)
		if last_day_time > 0.9 and t < 0.1:
			day_count += 1
		last_day_time = t

func get_day_name() -> String:
	# day_count 1 = Mon, 2 = Tue, etc.  Cycles every 7
	var index: int = (day_count - 1) % 7
	return DAY_NAMES[index]

func get_day_count() -> int:
	return day_count

# ─── Weather selection ───
func _pick_next_weather() -> void:
	var weights: Dictionary = biome_weather_weights.get(current_biome, default_weights)
	var new_weather: int = _weighted_random(weights)
	# Avoid picking the same weather twice in a row (unless only one option)
	if new_weather == current_weather and weights.size() > 1:
		new_weather = _weighted_random(weights)
	set_weather(new_weather)

func set_weather(new_weather: int) -> void:
	if new_weather == current_weather and not is_transitioning:
		return
	previous_weather = current_weather
	current_weather = new_weather
	is_transitioning = true
	transition_progress = 0.0
	weather_duration = randf_range(min_weather_duration, max_weather_duration)
	weather_timer = 0.0
	weather_changed.emit(get_weather_name(), WEATHER_NAMES.get(previous_weather, "Clear"))

func set_biome(biome_name: String) -> void:
	current_biome = biome_name

func get_weather_name() -> String:
	return WEATHER_NAMES.get(current_weather, "Clear")

func get_weather_icon() -> String:
	return WEATHER_ICONS.get(current_weather, "☀")

func get_intensity() -> float:
	"""Returns 0.0-1.0 representing how intense the current weather is (for VFX)."""
	if is_transitioning:
		return transition_progress
	return 1.0

func is_rainy() -> bool:
	return current_weather in [Weather.RAIN, Weather.HEAVY_RAIN, Weather.THUNDERSTORM]

func is_snowy() -> bool:
	return current_weather == Weather.SNOW

func is_foggy() -> bool:
	return current_weather == Weather.FOG

func is_stormy() -> bool:
	return current_weather == Weather.THUNDERSTORM

func is_sandstorm() -> bool:
	return current_weather == Weather.SANDSTORM

# ─── Utility ───
func _weighted_random(weights: Dictionary) -> int:
	var total: float = 0.0
	for w in weights.values():
		total += w
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for key in weights.keys():
		cumulative += weights[key]
		if roll <= cumulative:
			return key
	# Fallback
	return weights.keys()[0]
