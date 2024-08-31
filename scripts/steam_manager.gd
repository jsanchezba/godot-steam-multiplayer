extends Node

var steam_id: int = 0
var steam_username: String = ''

func _init() -> void:
	OS.set_environment('SteamAppId', str(480))
	OS.set_environment('SteamGameId', str(480))

func _ready() -> void:
	Steam.steamInit()
	Steam.initRelayNetworkAccess()
	
	var is_running = Steam.isSteamRunning()
	if is_running:
		print_debug('[INFO] - > Steam is running')
	else:
		print_debug('[ERROR] - > Steam is not running')
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func _process(delta: float) -> void:
	Steam.run_callbacks()
