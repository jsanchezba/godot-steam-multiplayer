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

func spawn_player(id: int, username: String):
	var new_player: Player = player_scene.instantiate()
	new_player.name = str(id)
	new_player.id = id
	new_player.username = username
	get_tree().root.call_deferred('add_child', new_player)
	print_debug('[INFO] -> JOINS player ' + new_player.name)
	if is_multiplayer_authority():
		SceneManager.player = new_player

func _on_game_started() -> void:
	game_started.rpc()

@rpc('any_peer', 'call_local', 'reliable')
func game_started():
	var uid = SteamNetwork.socket.get_unique_id()
	SceneManager.change_scene('level_1')
	spawn_player(uid, SteamManager.steam_username)
	var players = SteamNetwork.players
	for player in players:
		spawn_player(player, players[player])
		print('Spawned player %s' % players[player])
		
	lobby_UI.hide()
