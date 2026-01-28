extends Node

signal inventory_updated  # Signal emitted when inventory is updated

var inventory: Dictionary[String, int] = {
	"wood": 0
}

func add_item(item_name: String, amount: int = 1) -> void:
	if inventory.has(item_name):
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount

	print("Added ", amount, " ", item_name, " to inventory. New count: ", inventory[item_name])

	emit_signal("inventory_updated")  # Emit signal when inventory is updated

func print_inventory() -> void:
	for item in inventory.keys():
		print(item, ": ", inventory[item])