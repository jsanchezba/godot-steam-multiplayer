class_name Player extends CharacterBody2D

@onready var player_name: Label = $PlayerName
const speed = 300.0
var current_delta

#func _enter_tree() -> void:
	#set_multiplayer_authority(str(name).to_int())
	
func _ready() -> void:
	set_multiplayer_authority(str(name).to_int())
	if name:
		player_name.text = str(name)

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		update_player_position.rpc(name, position)

func _physics_process(delta: float) -> void:
	current_delta = delta
	if is_multiplayer_authority():
		var direction = Input.get_vector('left', 'right', 'up', 'down')
		
		velocity = direction * speed
		
		move_and_slide()

@rpc('any_peer', 'call_local', 'unreliable')
func update_player_position(entity_id: String, updated_position: Vector2):
	if not is_multiplayer_authority():
		if name == entity_id:
			position = lerp(position, updated_position, current_delta * 15)
	
