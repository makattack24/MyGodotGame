
extends Resource
class_name CardData

## Data definition for a single card type. Create .tres files in Resources/CardData/.

@export var card_name: String = ""           ## Unique identifier, e.g. "fireball"
@export var display_name: String = ""        ## Shown on card, e.g. "Fireball"
@export var cost: int = 1                    ## Mana / resource cost
@export var ability: String = ""             ## Short ability label, e.g. "Damage"
@export var description: String = ""         ## Longer description, e.g. "Deal 3 damage"
@export var card_type: String = "Wood"       ## Category shown at bottom
@export var texture: Texture2D = null        ## Card art (optional override)
