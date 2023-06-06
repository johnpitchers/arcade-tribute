extends Area

var velocity:float = Config.player.lazerVelocity
var life: float = velocity /  100.0

onready var explosion = preload("res://Scenes/Explosion.tscn")
onready var fly_out_label = preload("res://Scenes/FlyoutLabel.tscn")

signal barrier_hit

func _ready():
	connect("barrier_hit",get_node("/root/GameWorld/Formation/Barriers"),"barrierDestroy")
	if State.gameMode == 2:
		life *= 1.35
	$Timer.start(life)


func assignColor(col:Color = Color(1, 1, 1, 1)):
	$MeshInstance.mesh.material.emission = col
	$MeshInstance.mesh.material.albedo_color = col


func _process(delta):
	translate(Vector3(0, velocity * delta, 0))


func _on_Timer_timeout():
	self.queue_free()


func _on_LazerA_area_shape_entered(
	area_rid: RID, area: Area, area_shape_index: int, local_shape_index: int
) -> void:
	var groups = area.get_groups()
	if State.gameState != State.STATE_PLAYING:
		return
	var collided_with = area
	if collided_with:
		var collider_groups = collided_with.get_groups()
		
		# I'm undecided what the better approach is here. Do we handle the collisions
		# here or hand off to what ever we collided with?
		# Below is a mixure of signals, calling functions directly on the collided area
		# and handling the collission here.
		
		if collider_groups.has("Bricks"):
			emit_signal("barrier_hit",area)
			self.queue_free()
			
		# Let the mother ship handle the collision
		if collider_groups.has("MotherShip"):
			self.queue_free()
			collided_with.hitByPlayer(self.global_translation)
		
		# Let the lazer handle the collision
		if collider_groups.has("Invaders"):
			# collided_with is the Area. We need the parent Invader object
			var collided_with_area = collided_with
			collided_with = collided_with.get_parent()
			self.queue_free()
			collided_with.lives -= 1
			var explosion_instance = explosion.instance()

			# I've add a portion of the players lazerLevel to the alien's lives to offset the
			# power that comes with higher lazer levels. Especially at level 3, the
			# game becomes too easy otherwise. In bonus levels lives are ignored.
			if collided_with.lives < 1 || State.is_bonus_level:
				if collided_with.has_captured_player:
					reparentCapturedToPlayer(collided_with)
				get_node("/root/GameWorld").add_child(explosion_instance)
				var override_color = collided_with.get("explosion_color")
				if override_color:
					explosion_instance.overrideColor = override_color
				explosion_instance.init(
					collided_with.global_translation,
					40,
					1,
					collided_with.get_node("Area/Mesh").scale.x +0.4,
					"Invaders"
				)
				State.score += collided_with.scoreValue
				var fly_out_instance = fly_out_label.instance()
				fly_out_instance.init(str(collided_with.scoreValue), collided_with.global_translation)
				get_node("/root/GameWorld").add_child(fly_out_instance)
				collided_with.queue_free()
			else:
				collided_with_area.rotate_x(rand_range(-0.5, 0.5))
				collided_with_area.rotate_y(rand_range(-0.5, 0.5))
				collided_with_area.rotate_z(rand_range(-0.5, 0.5))
				collided_with_area.global_translation.y = (
					collided_with_area.global_translation.y
					+ rand_range(0.3, 0.7)
				)
				get_node("/root/GameWorld").add_child(explosion_instance)
				explosion_instance.init(collided_with.global_translation, 6, 1, 0.1, "Invaders")


func reparentCapturedToPlayer(collided_with):
	var stand_in_player_mesh = collided_with.find_node("StandInPlayerMesh")
	if !stand_in_player_mesh: return
	var pos = stand_in_player_mesh.global_translation
	var rot = stand_in_player_mesh.global_rotation
	var scl = stand_in_player_mesh.scale
	var player = get_node("/root/GameWorld/Player")
	collided_with.remove_child(stand_in_player_mesh)
	player.add_child(stand_in_player_mesh)
	#player.has_captured_player = true
	stand_in_player_mesh.set_owner(player)
	stand_in_player_mesh.global_translation = pos
	stand_in_player_mesh.global_rotation = rot
	stand_in_player_mesh.scale = scl
	player.moveRescuedIntoPosition()
	State.captured_player_in_formation = false
	# Give the player their life back
	State.player.lives = State.player.lives + 1
