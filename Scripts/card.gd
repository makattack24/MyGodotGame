extends Node2D

## Card scene — works both as a collectible world pickup AND a UI display.
## Assign a CardData resource to configure the card's stats.
## When placed in the world, the player walks over it to collect it.

# ==============================
# CONFIGURATION
# ==============================

@export var card_data: CardData = null          ## Assign a CardData .tres resource
@export var pickup_sound: AudioStream = null    ## Optional pickup sound

# ==============================
# NODE REFERENCES
# ==============================

@onready var cost_label: Label = $CardLayout/CardCost
@onready var ability_label: Label = $CardLayout/CardAbility
@onready var description_label: Label = $CardLayout/CardDescription
@onready var type_label: Label = $CardLayout/CardType
@onready var pickup_area: Area2D = $Area2D

var audio_player: AudioStreamPlayer2D
var _collected: bool = false

# ==============================
# LIFECYCLE
# ==============================

func _ready() -> void:
	# Apply card data to labels
	if card_data:
		_apply_card_data(card_data)

	# Setup audio
	if has_node("AudioStreamPlayer2D"):
		audio_player = $AudioStreamPlayer2D
	else:
		audio_player = AudioStreamPlayer2D.new()
		add_child(audio_player)
	if pickup_sound:
		audio_player.stream = pickup_sound

	# Connect pickup collision
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)

# ==============================
# CARD DATA
# ==============================

func _apply_card_data(data: CardData) -> void:
	cost_label.text = str(data.cost)
	ability_label.text = data.ability
	description_label.text = data.description
	type_label.text = data.card_type

## Set card data at runtime (e.g. when spawning from code).
func set_card_data_resource(data: CardData) -> void:
	card_data = data
	if is_inside_tree():
		_apply_card_data(data)

## Convenience setters for individual fields.
func set_card_fields(cost: int, ability: String, description: String, card_type: String) -> void:
	cost_label.text = str(cost)
	ability_label.text = ability
	description_label.text = description
	type_label.text = card_type

# ==============================
# PICKUP
# ==============================

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("Player"):
		_pickup()

func _pickup() -> void:
	_collected = true

	var item_name: String = card_data.card_name if card_data else "card"

	# Add to inventory
	Inventory.add_item(item_name, 1)
	Inventory.discover_card(item_name)
	Inventory.show_pickup_text(item_name, 1, global_position)
	print("Picked up card: ", item_name)

	# Track stat
	if get_node_or_null("/root/GameStats"):
		GameStats.record_item_collected(item_name)

	# Hide visuals immediately
	$Sprite2D.visible = false
	$CardLayout.visible = false
	pickup_area.set_deferred("monitoring", false)

	# Play sound then free, or free immediately
	if audio_player and audio_player.stream:
		audio_player.play()
		await audio_player.finished
		queue_free()
	else:
		queue_free()

