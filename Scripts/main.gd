extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var player: Node2D = $Player
@onready var object_spawner: Node2D = $ObjectSpawner

func _process(_delta: float) -> void:
	ground.generate_around(player.global_position)
	object_spawner.spawn_objects_around(player.global_position)
