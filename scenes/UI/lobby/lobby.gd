class_name Lobby extends CanvasLayer

@onready var lobby_name_value: TextEdit = %LobbyNameValue
@onready var message_input: TextEdit = %MessageInput
@onready var messages_container: RichTextLabel = %MessagesContainer


func _ready() -> void:
	if !SteamNetwork.lobby_created.is_connected(_on_lobby_created):
		SteamNetwork.lobby_created.connect(_on_lobby_created)
		
	if not SteamNetwork.lobby_message_received.is_connected(_on_message_received):
		SteamNetwork.lobby_message_received.connect(_on_message_received)

func _process(delta: float) -> void:
	pass

func _on_create_lobby_pressed() -> void:
	SteamNetwork.create_lobby()

func _on_join_lobby_pressed() -> void:
	SteamNetwork.join_lobby(int(lobby_name_value.text))
	
func _on_invite_friend_pressed() -> void:
	#Steam.activateGameOverlay('LobbyInvite')
	var friend_list = Steam.getUserSteamFriends()
	for friend in friend_list:
		if friend.name == 'Nelcu':
			print('Inviting friend %s' % friend.id)
			#Steam.activateGameOverlayInviteDialog(friend.id)

func _on_lobby_created(this_lobby_id: int):
	lobby_name_value.text = str(this_lobby_id)

func _on_message_button_pressed() -> void:
	var message = message_input.text
	Steam.sendLobbyChatMsg(SteamNetwork.lobby_id, message)
	message_input.text = ''

func _on_matchmaking_pressed() -> void:
	SteamNetwork.lobby_matchmaking()

func _on_message_received(username: String, message: String) -> void:
	messages_container.add_text(username + ': ' + message + '\n')
