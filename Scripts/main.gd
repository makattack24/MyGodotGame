extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var player: Node2D = $Player

func _process(_delta: float) -> void:
	ground.generate_around(player.global_position)
