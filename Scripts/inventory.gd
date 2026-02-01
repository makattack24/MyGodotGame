extends Node

signal inventory_updated  # Signal emitted when inventory is updated

var inventory: Dictionary = {
    "wood": 0,
    "coin": 0,
    "axe": 1  # Start with 1 axe
}

# Item textures - add your item textures here
var item_textures: Dictionary = {
    "wood": preload("res://Assets/woodItem.png"),
    "coin": preload("res://Assets/coin.png"),
    "axe": preload("res://Assets/WoodAxe.png")
}

func _ready() -> void:
    # Add to persist group for saving/loading
    add_to_group("persist")

func add_item(item_name: String, amount: int = 1) -> void:
    if inventory.has(item_name):
        inventory[item_name] += amount
    else:
        inventory[item_name] = amount

    print("Added ", amount, " ", item_name, " to inventory. New count: ", inventory[item_name])
    emit_signal("inventory_updated")

func remove_item(item_name: String, amount: int = 1) -> bool:
    if inventory.has(item_name) and inventory[item_name] >= amount:
        inventory[item_name] -= amount
        emit_signal("inventory_updated")
        return true
    return false

func get_item_count(item_name: String) -> int:
    if inventory.has(item_name):
        return inventory[item_name]
    return 0

func get_item_texture(item_name: String) -> Texture2D:
    if item_textures.has(item_name):
        return item_textures[item_name]
    return null

func print_inventory() -> void:
    for item in inventory.keys():
        print(item, ": ", inventory[item])

# Save inventory data
func save() -> Dictionary:
    return {
        "inventory": inventory.duplicate()
    }

# Load inventory data
func load_data(data: Dictionary) -> void:
    if data.has("inventory"):
        inventory = data["inventory"].duplicate()
        emit_signal("inventory_updated")
