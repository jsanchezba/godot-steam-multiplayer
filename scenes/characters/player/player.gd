class_name Player extends CharacterBody2D

@onready var player_name: Label = $PlayerName
@onready var sprite: AnimatedSprite2D = $Sprite
const speed = 200.0
var current_delta

var id: int = 0
var username: String = ''
#func _enter_tree() -> void:
	#set_multiplayer_authority(str(name).to_int())
	
func _ready() -> void:
	set_multiplayer_authority(str(name).to_int())
	player_name.text = username

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		update_player_position.rpc(name, position)

func _physics_process(delta: float) -> void:
	current_delta = delta
	var direction = Input.get_vector('left', 'right', 'up', 'down')
	if is_multiplayer_authority():
		
		velocity = direction * speed
		
		move_and_slide()
		
	if direction:
		sprite.flip_h = true if direction.x == -1 else false
		sprite.play('run')
	else:
		sprite.play('idle')

@rpc('any_peer', 'call_local', 'unreliable')
func update_player_position(entity_id: String, updated_position: Vector2):
	if not is_multiplayer_authority():
		if name == entity_id:
			position = lerp(position, updated_position, current_delta * 15)
	
