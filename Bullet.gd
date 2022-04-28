extends Area2D

var speed = 750
var playerWhoShot
var timetolive = 100
func _physics_process(delta):
	timetolive -= delta
	if timetolive < 0:
		queue_free()
	position += transform.x * speed * delta

func _on_Bullet_body_entered(body):
	print("hit player: " + str(body))
	if body.is_in_group("players"):
		if body.name != playerWhoShot:
			body.die(get_tree().get_network_unique_id())
	
