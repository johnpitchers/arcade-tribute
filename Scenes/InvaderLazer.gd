extends Area

var velocity: int = 12
var life: int = 6
var color: Color = Color(1, 1, 0, 1)
var muted:bool = false

signal player_hit
signal rescued_ship_hit
signal barrier_hit


func _ready():
	connect("player_hit",get_node("/root/GameWorld/Player"), "playerHit")
	connect("rescued_ship_hit",get_node("/root/GameWorld/Player"), "rescuedShipHit")
	connect("barrier_hit",get_node("/root/GameWorld/Formation/Barriers"),"barrierDestroy")
	$Timer.start(life)
	assignColor()
	if !muted:
		$AudioStreamPlayer.play()


func assignColor():
	$MeshInstance.mesh.material.emission = color
	$MeshInstance.mesh.material.albedo_color = color


func _process(delta):
	translate(Vector3(0, velocity * delta, 0))
	rotation.z = lerp_angle(rotation.z,PI,delta*2)
	$MeshInstance.rotate_y(5*delta)


func _on_Timer_timeout():
	self.queue_free()


func _on_InvaderLazer_area_shape_entered(area_rid: RID, area: Area, area_shape_index: int, local_shape_index: int) -> void:
	var collider_groups = area.get_groups();
	if (collider_groups.has('Player')):
		emit_signal("player_hit")
		queue_free()
	if (collider_groups.has('RescuedShip')):
		emit_signal("rescued_ship_hit")
		queue_free()
	if (collider_groups.has("Bricks")):
		emit_signal("barrier_hit",area)
		queue_free()
