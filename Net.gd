extends Node


var nakama_client: NakamaClient
var nakama_session: NakamaSession
var nakama_socket: NakamaSocket
 

func _ready():
	connect_to_nakama()

func connect_to_nakama() -> void:
	# Connect to a local Nakama instance using all the default settings.
	nakama_client = Nakama.create_client('defaultkey', '34.125.184.102', 7350, 'http', 
		Nakama.DEFAULT_TIMEOUT, NakamaLogger.LOG_LEVEL.ERROR)
 
	# Login to Nakama using "device authentication".
	var device_id = OS.get_unique_id()
	nakama_session = yield(nakama_client.authenticate_device_async(device_id, "Example"), 'completed')
	if nakama_session.is_exception():
		print ("Unable to connect to Nakama")
		get_tree().quit()
 
	# Open a realtime socket to Nakama.
	nakama_socket = Nakama.create_socket_from(nakama_client)
	yield(nakama_socket.connect_async(nakama_session), "completed")
 
	print ("Connected to Nakama!")
 
	join_an_online_match()

func join_an_online_match() -> void:
	# We can configure OnlineMatch before using it:
	OnlineMatch.min_players = 2
	OnlineMatch.max_players = 4
	OnlineMatch.client_version = 'dev'
	OnlineMatch.ice_servers = [{ "urls": ["stun:stun.l.google.com:19302"] }]
	OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.AUTO
 
	# Connect to all of OnlineMatch's signals.
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("match_created", self, "_on_OnlineMatch_match_created")
	OnlineMatch.connect("match_joined", self, "_on_OnlineMatch_match_joined")
	OnlineMatch.connect("matchmaker_matched", self, "_on_OnlineMatch_matchmaker_matched")
	OnlineMatch.connect("player_joined", self, "_on_OnlineMatch_player_joined")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	OnlineMatch.connect("player_status_changed", self, "_on_OnlineMatch_player_status_changed")
	OnlineMatch.connect("match_ready", self, "_on_OnlineMatch_match_ready")
	OnlineMatch.connect("match_not_ready", self, "_on_OnlineMatch_match_not_ready")
 
	# Join the matchmaking queue.
	OnlineMatch.start_matchmaking(nakama_socket)
 
	print ("Joined the matchmaking queue...")
	
	
func _on_OnlineMatch_error(message: String) -> void:
	print("ERROR: %s" % message)
 
func _on_OnlineMatch_disconnected() -> void:
	print("Disconnected from match.")
	
	
func _on_OnlineMatch_player_joined(player: OnlineMatch.Player) -> void:
	print("Player joined: %s" % player.username)
 
func _on_OnlineMatch_player_left(player: OnlineMatch.Player) -> void:
	print("Player left: %s" % player.username)

func _on_OnlineMatch_player_status_changed(player: OnlineMatch.Player, status) -> void:
	print("Player status changed: %s -> %s" % [player.username, status])
	if player.peer_id != get_tree().get_network_unique_id() && status == OnlineMatch.PlayerStatus.CONNECTED:
		rpc_id(player.peer_id, "receive_message", "Hi! We're connected now :-)")
 
remote func receive_message(message: String) -> void:
	print("Message from %s: %s" % [get_tree().get_rpc_sender_id(), message])
	
func _on_OnlineMatch_match_not_ready() -> void:
	print("The match isn't ready to start")
 
func _on_OnlineMatch_match_ready(players: Dictionary) -> void:
	print("The match is ready to start! Here are players:")
	for player in players.values():
		print ("- %s" % player.username)
 
	OnlineMatch.start_playing()
	if get_tree().is_network_server():
		rpc("start_game")
 
remotesync func start_game() -> void:
	print ("The host told me it's time to start the game!")
	get_tree().change_scene("res://gameWorld.tscn")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
