extends Node2D

@onready var entrance_markers: Node2D = $EntranceMarkers

func _ready() -> void:
	update_player_position()
	
func update_player_position() -> void:
	for entrance in entrance_markers.get_children():
		if entrance is Marker2D and entrance.name == 'Main':
			SceneManager.update_player_position(entrance.global_position)
