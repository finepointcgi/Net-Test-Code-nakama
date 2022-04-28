extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var Player = preload("res://player.tscn")
onready var players_node := $Players
var players_alive := {}
var players_setup := {}
signal game_started ()
var runcount = 0
const PORT = 27015
# Called when the node enters the scene tree for the first time.
func _ready():
	if get_tree().is_network_server():
		var players = OnlineMatch.get_player_names_by_peer_id()
		game_start(players)
	pass

func game_start(players: Dictionary) -> void:
	rpc("_do_game_setup", players)

remotesync func _do_game_setup(players: Dictionary) -> void:
	runcount += 1
	print("Run count: " + str(runcount))
	get_tree().set_pause(true)
	print(players)
	players_alive = players
	var player_index := 1
	for peer_id in players:
		var other_player = Player.instance()
		other_player.name = str(peer_id)
		players_node.add_child(other_player)
		
		other_player.set_network_master(peer_id)
		other_player.set_player_name(players[peer_id])
		other_player.position = $SpawnPoints.get_node(str(player_index)).position
		#other_player.connect("player_dead", self, "_on_player_dead", [peer_id])
		
		player_index += 1
	
	var my_id := get_tree().get_network_unique_id()
	var my_player := players_node.get_node(str(my_id))
	my_player.player_controlled = true
	rpc_id(1, "_finished_game_setup", my_id)
	
	# Records when each player has finished setup so we know when all players are ready.
mastersync func _finished_game_setup(player_id: int) -> void:
	players_setup[player_id] = players_alive[player_id]
	if players_setup.size() == players_alive.size():
		# Once all clients have finished setup, tell them to start the game.
		rpc("_do_game_start")

# Actually start the game on this client.
remotesync func _do_game_start() -> void:
	emit_signal("game_started")
	get_tree().set_pause(false)
