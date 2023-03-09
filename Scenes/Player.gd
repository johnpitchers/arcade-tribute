extends Area

var momentum = Vector3.ZERO
var lazer = preload("res://Scenes/PlayerLazer.tscn")
var explosion = preload("res://Scenes/Explosion.tscn")
var type = "player"
var is_dead: bool = true
var is_disabled: bool = true
var is_captured: bool = false
var can_shoot: bool = false
var is_first_lazer_muted:bool = true

var dev_has_rescued_ship:bool = false # Overrides has_rescued_ship for testing

const FIRE_RATE = 0.2


func _ready() -> void:
	pass


func init():
	playerReset()


func _process(delta: float) -> void:
	if State.gameState == State.STATE_PLAYING:
		handlePlayerInput(delta)


func playerHit():
	var explosionInstance = explosion.instance()
	explosionInstance.overrideColor = Color(1,1,1,1)
	get_node("/root/GameWorld").add_child(explosionInstance)
	explosionInstance.init(global_translation, 150, 1.8, 0.6, "Player")
	if State.player.has_rescued_ship:
		self.translation = $RescuedShip.global_translation
		deactivateRescuedShip()
		return
	is_dead = true
	is_disabled = true
	visible = false
	$CollisionShape.disabled = true
	$DeathTimer.start()


func rescuedShipHit():
	var explosionInstance = explosion.instance()
	explosionInstance.overrideColor = Color(1,1,1,1)
	get_node("/root/GameWorld").add_child(explosionInstance)
	explosionInstance.init($RescuedShip.global_translation, 150, 1, 0.75, "Player")
	deactivateRescuedShip()


func playerInTractorBeam():
	is_dead = true
	is_disabled = true
	is_captured = true
	visible = false
	$CollisionShape.disabled = true
	$DeathTimer.start()


func playerReset():
	if is_dead && !is_captured:
		removePowerUps()
	is_captured = false
	can_shoot = true
	translation = Vector3.ZERO
	if State.player.has_rescued_ship:
		translation = -$RescuedShip.translation/2
	momentum.x = 0
	makeInvulnerable()
	if State.player.has_rescued_ship:
		activateRescuedShip()
	else:
		deactivateRescuedShip()
	is_dead = false
	is_disabled = false


func activateRescuedShip():
	State.player.has_rescued_ship = true
	$RescuedShip.visible = true
	#$RescuedShip.monitorable = true
	$RescuedShip.set_collision_layer_bit(0, true)
	$RescuedShip.monitorable = true
	$RescuedShip.monitorable = true


func deactivateRescuedShip():
	State.player.has_rescued_ship = false
	$RescuedShip.visible = false
	#$RescuedShip.monitorable = false #Does not work
	$RescuedShip.set_collision_layer_bit(0, false)
	$RescuedShip.monitorable = false
	$RescuedShip.monitorable = false


func moveRescuedIntoPosition():
	var rescued: Spatial = self.find_node("StandInPlayerMesh")
	var duration: float = 4
	$RescuedShip/MoveTween.interpolate_property(
		rescued,
		"translation",
		rescued.translation,
		$RescuedShip.translation,
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_IN_OUT
	)
	$RescuedShip/MoveTween.start()
	$RescuedShip/RotateTween.interpolate_property(
		rescued,
		"rotation",
		rescued.rotation,
		$RescuedShip.rotation + Vector3(0, 0, 4 * PI),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_IN_OUT
	)
	$RescuedShip/RotateTween.start()


func _on_RotateTween_tween_all_completed() -> void:
	var rescued: Spatial = self.find_node("StandInPlayerMesh")
	rescued.queue_free()
	activateRescuedShip()


func slideOut():
	is_disabled = true
	$SlideAwayAnimation.play("SlideAway")


func handlePlayerInput(delta):
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction != 0 && !is_disabled:
		momentum.x = lerp(
			momentum.x,
			direction * Config.player.maxSpeed * delta,
			Config.player.acceleration * delta
		)
	else:
		momentum.x = lerp(momentum.x, 0, Config.player.acceleration * delta)
	self.translation += momentum
	$Mesh.rotation.y = momentum.x / 2
	$RescuedShip/Mesh.rotation.y = momentum.x / 2
	if (
		Input.is_action_pressed("ui_shoot")
		&& can_shoot
		&& !is_dead
		&& !is_disabled
		&& $FireRateTimer.is_stopped()
	):
		$FireRateTimer.wait_time = getFireRate()
		$FireRateTimer.start()
		fireLazer(translation)
		if State.player.has_rescued_ship:
			fireLazer($RescuedShip.global_translation)
		playShootSound()

func getFireRate():
	var fireRate = FIRE_RATE
	# Apply dual fire rate powerup. Not quite double. Sorry.
	# We need to carefully limit fire power so it's not too powerful.
	if State.player.fireRateIncreased: fireRate = fireRate / 1.6
	# Slow down slightly for each increase in lazerLevel
	fireRate = fireRate * (1 + State.player.lazerLevel/4)
	return fireRate


func playShootSound():
	# Lazer fires as soon as the scene is loaded. When the lazer is first
	# instanced it causes some stutter. Mute it so it's not noticable.
	if is_first_lazer_muted:
		is_first_lazer_muted = false
		return
		
	$ShootSound.volume_db = 1
	$SecondShootSound.volume_db = 1
	match State.player.lazerLevel:
		1:
			$ShootSound.pitch_scale = 1
			$SecondShootSound.pitch_scale = 1
		2:
			$ShootSound.pitch_scale = 0.9
			$SecondShootSound.pitch_scale = 0.8
		3:
			$ShootSound.pitch_scale = 0.8
			$SecondShootSound.pitch_scale = 0.7
	$ShootSound.play()
	if State.player.has_rescued_ship:
		$SecondShootSound.play()


func fireLazer(pos):
	pos = pos + Vector3(0,1.1,0)
	match State.player.lazerLevel:
		1:
			var lazerInstance = lazer.instance()
			if is_first_lazer_muted:
				lazerInstance.assignColor(Color(0,0,0,0.01))
			else:
				lazerInstance.assignColor(Color(1,1,1,1))
			lazerInstance.translation = pos
			#lazerInstance.translation.y = 0
			lazerInstance.rotation = rotation
			get_parent().add_child(lazerInstance)
		2:
			var offset = 0.4
			for i in range(2):
				var lazerInstance = lazer.instance()
				lazerInstance.assignColor(Color(0.3,1,0.5,1))
				lazerInstance.translation = pos
				lazerInstance.translation.z = 0
				lazerInstance.translate(Vector3(offset, 0, 0))
				offset = -offset
				lazerInstance.rotation = rotation
				get_parent().add_child(lazerInstance)
		3:
			var offset = 0.8
			for i in range(3):
				var lazerInstance = lazer.instance()
				lazerInstance.assignColor(Color(1,1,0,1))
				offset = -offset
				if i == 2:
					offset = 0
					lazerInstance.velocity = lazerInstance.velocity * 1.1
				lazerInstance.translation = pos
				lazerInstance.translation.z = 0
				lazerInstance.translate(Vector3(offset, 0, 0))
				lazerInstance.rotation = Vector3(0, 0, -0.05 * offset)
				get_parent().add_child(lazerInstance)

	#var aliens = get_tree().get_nodes_in_group("Invaders")
	#var aliensInFormation = get_tree().get_nodes_in_group("AliensInFormation")
	#var aliensAttacking = get_tree().get_nodes_in_group("AliensAttacking")


func makeInvulnerable():
	$CollisionShape.disabled = true
	$InvulnerabiltyTimer.wait_time = Config.player.invulneralbeSeconds
	$InvulnerabiltyTimer.start()
	$InvulnerabiltyTimer/FlashTimer.start()


func removePowerUps():
	State.player.has_rescued_ship = dev_has_rescued_ship
	$FireRateTimer.wait_time = FIRE_RATE
	State.player.lazerLevel = Config.player.lazerLevel
	State.player.fireRateIncreased = Config.player.fireRateIncreased
	get_node("/root/GameWorld/PowerUpController").power_ups_this_level = 0


func _on_FlashTimer_timeout() -> void:
	visible = !visible


func _on_InvulnerabiltyTimer_timeout() -> void:
	$InvulnerabiltyTimer/FlashTimer.stop()
	visible = true
	$CollisionShape.disabled = false
	if State.player.has_rescued_ship:
		$RescuedShip/CollisionShape.disabled = false


func _on_DeathTimer_timeout() -> void:
	if State.gameState == State.STATE_GAMEOVER:
		return
	State.player.lives -= 1
	State.player.has_rescued_ship = false
	if State.player.lives < 0:
		State.gameState = State.STATE_GAMEOVER
		removePowerUps()
	else:
		playerReset()


func stopAllTimers():
	$DeathTimer.stop()
	$InvulnerabiltyTimer.stop()
	$InvulnerabiltyTimer/FlashTimer.stop()
