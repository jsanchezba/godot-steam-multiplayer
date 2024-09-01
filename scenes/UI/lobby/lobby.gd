class_name Lobby extends CanvasLayer

@onready var lobby_id_value: LineEdit = %LobbyIDValue
@onready var lobby_name_value: LineEdit = %LobbyNameValue
@onready var message_input: LineEdit = %MessageInput
@onready var messages_container: RichTextLabel = %MessagesContainer
@onready var member_list: RichTextLabel = %MemberList
@onready var accept_dialog: AcceptDialog = %AcceptDialog

var is_message_focused: bool = false

signal game_started

func _ready() -> void:
	if !SteamNetwork.lobby_joined.is_connected(_on_lobby_joined):
		SteamNetwork.lobby_joined.connect(_on_lobby_joined)
		
	if not SteamNetwork.lobby_message_received.is_connected(_on_message_received):
		SteamNetwork.lobby_message_received.connect(_on_message_received)
		
	if not SteamNetwork.lobby_members_changed.is_connected(_on_lobby_members_changed):
		SteamNetwork.lobby_members_changed.connect(_on_lobby_members_changed)
	SteamNetwork.lobby_join_failed.connect(_on_lobby_join_failed)

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

func _on_lobby_joined(_lobby_id: int, _name: String):
	lobby_id_value.text = str(_lobby_id)
	lobby_name_value.text = _name

func _on_message_button_pressed() -> void:
	send_message()

func _on_matchmaking_pressed() -> void:
	SteamNetwork.join_frield_lobby()

func _on_message_received(message: String) -> void:
	messages_container.add_text(message + '\n')

func _on_play_button_pressed() -> void:
	if not multiplayer.is_server():
		accept_dialog.title = 'Cannot start game'
		accept_dialog.dialog_text = 'Not lobby owner'
		accept_dialog.show()
	elif not SteamNetwork.lobby_id:
		accept_dialog.title = 'Cannot start game'
		accept_dialog.dialog_text = 'Lobby not created'
		accept_dialog.show()
	else:
		game_started.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('enter'):
		send_message()
		
func _on_message_input_focus_entered() -> void:
	is_message_focused = true

func _on_message_input_focus_exited() -> void:
	is_message_focused = false
	
func send_message():
	var message = message_input.text
	Steam.sendLobbyChatMsg(SteamNetwork.lobby_id, message)
	message_input.text = ''

func _on_lobby_members_changed():
	member_list.text = ''
	var members = SteamNetwork.lobby_members
	for member in members:
		member_list.add_text(members[member] + '\n')

func _on_lobby_join_failed(reason: String) -> void:
	accept_dialog.title = 'Cannot join lobby'
	accept_dialog.dialog_text = reason
	accept_dialog.show()
