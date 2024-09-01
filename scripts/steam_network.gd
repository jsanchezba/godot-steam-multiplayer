extends Node

var lobby_id: int = 0
var lobby_members_max: int = 2
var is_host: bool = false
var matchmake_phase = 0
var players: Dictionary
var lobby_members: Dictionary

var socket = null
signal lobby_created(_lobby_id: int, _name: String)
signal lobby_joined(_lobby_id: int, _name: String)
signal lobby_message_received(message: String)
signal lobby_join_failed(reason: String)
signal player_connected(id: int, username: String)
signal player_disconnected(id: int)
signal lobby_members_changed

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created.bind())
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connection)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func _process(delta: float) -> void:
	pass
	
func create_lobby() -> void:
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, lobby_members_max)

func _on_lobby_created(_connect: int, new_lobby_id: int) -> void:
	if _connect == 1:
		lobby_id = new_lobby_id
		is_host = true
		print('Created lobby: %s ' % lobby_id)
		
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, 'name', 'TBP Lobby')
		Steam.allowP2PPacketRelay(true)
		print_debug('[INFO] -> Creating socket connection..')
		create_socket()

		var lobby_name = Steam.getLobbyData(lobby_id,  'name')
		lobby_created.emit(lobby_id, lobby_name)

func join_lobby(_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % _lobby_id)
	Steam.joinLobby(_lobby_id)

func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = _lobby_id
		
		var id = Steam.getLobbyOwner(_lobby_id)
		if id != Steam.getSteamID():
			connect_socket(id)
		
		var lobby_name = Steam.getLobbyData(lobby_id,  'name')
		lobby_joined.emit(lobby_id, lobby_name)
		
		get_lobby_members()
	else:
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		lobby_join_failed.emit(FAIL_REASON)

func get_lobby_members() -> void:
	lobby_members.clear()
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members[member_steam_id] = member_steam_name
		
	lobby_members_changed.emit()
func get_friends_lobbies() -> Dictionary:
	var results: Dictionary = {}
	
	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)
		
		if game_info.size() > 0:
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']
			
			if app_id != Steam.getAppID() or lobby is String:
				# Either not in this game, or not in a lobby
				continue

			results[steam_id] = lobby
	return results

func join_frield_lobby():
	var friends_lobbies: Dictionary = get_friends_lobbies()
	var lobbies = friends_lobbies.values()
	if lobbies.size() > 0:
		join_lobby(lobbies[0])

func lobby_matchmaking() -> void:
	matchmake_phase = 0
	matchmaking_loop()

func matchmaking_loop():
	if matchmake_phase < 4:
		Steam.addRequestLobbyListDistanceFilter(matchmake_phase)
		Steam.requestLobbyList()
	else:
		print("[STEAM] Failed to automatically match you with a lobby. Please try again.")

func _on_lobby_match_list(lobbies: Array) -> void:
	print('finding lobbies...')
	var attempting_join: bool = false
	for this_lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_nums: int = Steam.getNumLobbyMembers(this_lobby)
		
		if lobby_nums < lobby_members_max and not attempting_join:
			attempting_join = true
			print("Attempting to join lobby...")
			print_debug('Joining lobby %s' % this_lobby)
			Steam.joinLobby(this_lobby)
			
	# No lobbies that matched were found, go onto the next phase
	if not attempting_join:
		matchmake_phase += 1
		matchmaking_loop()

func create_socket() -> void:
	socket = SteamMultiplayerPeer.new()
	socket.create_host(0)
	multiplayer.set_multiplayer_peer(socket)
	
func connect_socket(steam_id: int) -> void:
	print('Connecting to %s' % steam_id)
	socket = SteamMultiplayerPeer.new()
	socket.create_client(steam_id, 0)
	multiplayer.set_multiplayer_peer(socket)

func send_message(message: String) -> void:
	var sent = Steam.sendLobbyChatMsg(lobby_id, message)
	if not sent:
		print_debug('[ERROR] -> Message not send')

func _on_player_connected(id: int):
	print('player connected')
	register_player.rpc_id(id, SteamManager.steam_username)
	player_connected.emit(id, SteamManager.steam_username)
	get_lobby_members()
	#print(id)
	#var steam_username = Steam.getFriendPersonaName(id)
	#print(steam_username)
	#players[id] = steam_username

func _on_player_disconnected(id: int):
	print('player disconnected')
	unregister_player.rpc(id)
	player_disconnected.emit(id, SteamManager.steam_username)
	get_lobby_members()

func _on_connection():
	print('conection success')
	
func _on_connection_failed():
	multiplayer.set_network_peer(null)
	print('connection failed')

func _on_server_disconnected():
	print('Server disconnected')

func _on_lobby_message(_lobby_id: int, user: int, buffer: String, chat_type: int):
	var username = Steam.getFriendPersonaName(user)
	lobby_message_received.emit(username + ': ' + buffer + '\n')

@rpc('any_peer', 'call_local', 'reliable')
func register_player(_name):
	var id = multiplayer.get_remote_sender_id()
	print('Registered player name %s' % _name)
	print('Registered player ID %s' % id)
	players[id] = _name

@rpc('any_peer', 'call_local', 'reliable')
func unregister_player(id):
	players.erase(id)

func _on_lobby_chat_update(_lobby_id: int, change_id: int, making_change_id: int, chat_state: int):
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		send_message('%s has joined the lobby.' % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		send_message('%s has left the lobby.' % changer_name)
	else:
		send_message('%s did... something.' % changer_name)

	get_lobby_members()
