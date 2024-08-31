extends Node2D

@export var player_scene: PackedScene
@onready var lobby_UI: Lobby = $Lobby

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_player_connected(id: int) -> void:
	pass

func spawn_player(id: int):
	var new_player = player_scene.instantiate()
	new_player.name = str(id)
	call_deferred('add_child', new_player)
	print_debug('[INFO] -> JOINS player ' + new_player.name)
	if is_multiplayer_authority():
		SceneManager.player = new_player

func _on_game_started() -> void:
	game_started.rpc()

@rpc('any_peer', 'call_local', 'reliable')
func game_started():
	spawn_player(1)
	var players = SteamNetwork.players
	for player in players:
		spawn_player(player)
		print('Spawned player %s' % players[player])
		
	lobby_UI.hide()
	SceneManager.change_scene('level_1')
