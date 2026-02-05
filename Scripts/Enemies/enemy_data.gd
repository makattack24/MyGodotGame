extends Resource
class_name EnemyData

## Configuration data for enemy types - makes it easy to create new enemies

@export_group("Stats")
@export var enemy_name: String = "Enemy"
@export var max_health: int = 3
@export var knockback_strength: float = 300.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0

@export_group("Movement")
@export var move_speed: float = 120.0
@export var aggro_range: float = 200.0
@export var return_home_range: float = 400.0

@export_group("Loot")
@export var coin_drop_chance: float = 1.0
@export var min_coins: int = 1
@export var max_coins: int = 3
@export var heart_drop_chance: float = 0.15

@export_group("Visual")
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(0.65, 0.65)
@export var hit_color: Color = Color(1, 0.3, 0.3)
@export var glow_enabled: bool = false

@export_group("Audio")
@export var hit_sound: AudioStream
@export var death_sound: AudioStream
@export var attack_sound: AudioStream
