class_name Player extends CharacterBody2D

const speed = 300.0
@onready var player_name: Label = $PlayerName

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	
func _ready() -> void:
	if name:
		player_name.text = str(name)

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		var direction = Input.get_vector('left', 'right', 'up', 'down')
		
		velocity = direction * speed
		
		move_and_slide()
