extends Node

const scene_dir_path = 'res://scenes/levels/'
var player: Player
var current_scene: Node2D

signal update_position

func _ready() -> void:
	pass

func change_scene(to: String) -> void:
	print_debug('[INFO] -> Loading scene ' + to)
	if current_scene:
		print('remove scene')
		get_tree().root.call_deferred('remove_child', current_scene)
		
	var full_path = scene_dir_path + to + '/' + to + '.tscn'
	current_scene = load(full_path).instantiate()
	get_tree().root.call_deferred('add_child', current_scene)
	
func update_player_position(safe_position: Vector2):
	print_debug('[INFO] -> Emit player position')
	update_position.emit(safe_position)
