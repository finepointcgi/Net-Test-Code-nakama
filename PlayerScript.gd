extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var move_speed = 200 
puppet var repl_pos = Vector2()
puppet var repl_rot = 0.0
export var Bullet : PackedScene
var action_primary = false
var player_controlled = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if player_controlled:
		# Initialize the movement vector
		var move_dir = Vector2(0, 0)
		
		# Poll the actions keys
		if (Input.is_action_pressed("ui_up")):
			# Negative Y will move the actor UP on the screen
			move_dir.y -= 1
		if (Input.is_action_pressed("ui_down")):
			# Positive Y will move the actor DOWN on the screen
			move_dir.y += 1
		if (Input.is_action_pressed("ui_left")):
			# Negative X will move the actor LEFT on the screen
			move_dir.x -= 1
		if (Input.is_action_pressed("ui_right")):
			# Positive X will move the actor RIGHT on the screen
			move_dir.x += 1
		
		var shooting = false
		if (Input.is_action_just_pressed("Attack")):
			shoot(global_transform, self)
			shooting = true
			
		
		look_at(get_global_mouse_position())
		
		# Apply the movement formula to obtain the new actor position
		position += move_dir.normalized() * move_speed * delta 
		rpc("update_remote_player", global_position, rotation, shooting, global_transform, name)
		

remotesync func shoot(shootpos, playerwhoshot):
	var b : Area2D = Bullet.instance()
	print("shooting")
	get_tree().get_root().get_node("gameWorld").add_child(b)
	b.transform = shootpos
	b.playerWhoShot = playerwhoshot
	
remotesync func die(id):
	if id == get_tree().get_network_unique_id():
		pass
		#get_tree().get_root().get_node("gameWorld").endgame(false)
	#Game.CheckEndGame()
	queue_free()
	
puppet func update_remote_player(_position: Vector2, rot, is_attacking: bool, gTransform, playerwhoshot) -> void:
	global_position = _position
	global_rotation = rot
	if is_attacking :
		shoot(gTransform, playerwhoshot)
		pass

func set_player_name(name):
	name = name
