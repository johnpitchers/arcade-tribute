extends Spatial

var lives: int = 0
var scoreValue: int = 30
var explosion_color: Color
var explosion_color1: Color = Color(0.4, 0.5, 1, 1)
var explosion_color2: Color = Color(1, 0, 0, 1)
var explosion_color3: Color = Color(0, 0.7, 0.2, 1)
var explosion_color4: Color = Color(0.6, 0, 0.9, 1)

var attack_speed: float = 0.0

var invade_path: Node
var invade_path_follow
var invade_path_spatial
var attack_path: Node
var attack_path_follow
var attack_path_spatial
var state: int
var params
var formation
var animation_position: Vector3
var animation_rotation: Vector3
var lazer = preload("res://Scenes/InvaderLazer.tscn")
var tractorBeam = preload("res://Scenes/TractorBeam.tscn")
var hasTractorBeam: bool = false
var canEmitTractorBeam: bool = false
var has_captured_player: bool = false

const SPEED: float = 30.0
const RECOVERY_SPEED: float = 0.5
const FORMING_UP_TRANSLATION_DAMP: float = 12.0
const FORMING_UP_ROTATION_DAMP: float = 20.0
const ATTACK_STATE_FIRERATE_MULTIPLIER: float = 5.0
const BIG_INVADER: int = 7
const MEDIUM_INVADER: int = 6
const SMALL_INVADER: int = 5
const BOSS_ALIEN: int = 4
const BIG_ALIEN: int = 3
const MEDIUM_ALIEN: int = 2
const SMALL_ALIEN: int = 1
enum { INVADING, FORMING_UP, IN_FORMATION, ATTACKING, CAPTURING }

var space_invader_mesh_frame:int = 0

signal trackBonusScores

func _ready() -> void:
	connect("trackBonusScores",get_node("/root/GameWorld"),"trackBonusScores")
	pass


func init(p):
	randomize()
	params = p
	var pathNum: int = params.pattern
	formation = get_node("/root/GameWorld/Formation")
	invade_path = load("res://Scenes/Path" + str(pathNum) + ".tscn").instance()
	get_node("/root/GameWorld").add_child(invade_path)
	invade_path_follow = invade_path.get_node("PathFollow")
	invade_path_spatial = invade_path.get_node("PathFollow/Spatial")
	translation = invade_path_spatial.translation
	
	var pathIndex: int = (randi() % 4) + 1
	if params.type == BOSS_ALIEN:
		pathIndex = (randi() % 2) + 1
	attack_path = load("res://Scenes/AttackPath" + str(pathIndex) + ".tscn").instance()
	attack_path_follow = attack_path.get_node("PathFollow")
	attack_path_spatial = attack_path.get_node("PathFollow/Spatial")
	get_node("/root/GameWorld").add_child(attack_path)

	lives = params.lives
	
	setAdditionProps()
	$Area/Mesh.scale = Vector3(params.scale, params.scale, params.scale * 3)
	$Area/CollisionShape.shape.extents = Vector3(
		params.scale * 1.5, params.scale * 1.5, params.scale * 1.5
	)
	translation = translation + Vector3(0, 0, 0)

	params.fireRate = State.alienFireRate
		
	state = INVADING


func _process(delta: float) -> void:
	match state:
		INVADING:
			invade(delta)
		FORMING_UP:
			formUp(delta)
		IN_FORMATION:
			inFormation(delta)
		ATTACKING:
			attacking(delta)
		CAPTURING:
			capturing(delta)
	collisionRecover(delta)
	fireLazers(delta)
	if has_captured_player:
		orientCapturedPlayer(delta)
	
	$DevLivesLabel.text = str(lives)


func orientCapturedPlayer(delta):
	var capturedPlayer = get_node("StandInPlayerMesh")
	if !capturedPlayer:
		return
	if state == FORMING_UP || state == IN_FORMATION:
		capturedPlayer.rotation.y = 0
		capturedPlayer.translation = lerp(capturedPlayer.translation, Vector3(0, 1.5, 0), 2 * delta)
	if state == ATTACKING:
		capturedPlayer.rotation.y = attack_path.rotation.y
		capturedPlayer.translation = lerp(
			capturedPlayer.translation, Vector3(0, -2, 0), 0.6 * delta
		)


func setAdditionProps():
	match params.type:
		SMALL_ALIEN:
			$Area/Mesh/Alien1.visible = true
			explosion_color = explosion_color1
			scoreValue = 10
		MEDIUM_ALIEN:
			$Area/Mesh/Alien2.visible = true
			explosion_color = explosion_color2
			scoreValue = 20
		BIG_ALIEN:
			$Area/Mesh/Alien3.visible = true
			explosion_color = explosion_color3
			scoreValue = 30
		BOSS_ALIEN:
			$Area/Mesh/Alien4.visible = true
			explosion_color = explosion_color4
			scoreValue = 50
		SMALL_INVADER:
			$Area/Mesh/SpaceInvader3.visible = true
			explosion_color = explosion_color2
			scoreValue = 50
		MEDIUM_INVADER:
			$Area/Mesh/SpaceInvader2.visible = true
			explosion_color = Color(1,0.9,0.1)
			scoreValue = 50
		BIG_INVADER:
			$Area/Mesh/SpaceInvader1.visible = true
			explosion_color = Color(1,0.25,1)
			scoreValue = 50
			
	if State.is_bonus_level:
		scoreValue = 100
		lives = 0


func fireLazers(delta):
	if State.is_bonus_level:
		return
	var fireRate = State.alienFireRate * pow(2,State.player.lazerLevel)
	if State.player.fireRateIncreased:
		fireRate *= 1.5
	if State.player.has_rescued_ship:
		fireRate *= 1.5
	#if state == INVADING:
	#	fireRate = fireRate * ATTACK_STATE_FIRERATE_MULTIPLIER
	if state == ATTACKING:
		fireRate = fireRate * ATTACK_STATE_FIRERATE_MULTIPLIER
	
	if formation.is_space_invader_level:
		fireRate = fireRate * 2
		
	var rv = randf()
	var firenow = rv / fireRate < delta

	if firenow:
		var lazerInstance = lazer.instance()
		lazerInstance.translation = self.global_translation
		#lazerInstance.rotation_degrees = Vector3(0, 0, 180 + (rand_range(-50, 50)))
		lazerInstance.rotation_degrees = rotation_degrees + Vector3(0, 0, 180)
		get_node("/root/GameWorld").add_child(lazerInstance)


# If hit by the players lazer but not killed, the area is moved.
# See playerLazer.gd.
func collisionRecover(delta):
	$Area.translation = lerp($Area.translation, Vector3.ZERO, RECOVERY_SPEED * delta)
	$Area.rotation = lerp($Area.rotation, Vector3.ZERO, RECOVERY_SPEED * delta)


func invade(delta):
	var invadeSpeedMultiplier = 1
	if State.is_bonus_level:
		invadeSpeedMultiplier = 0.6
	invade_path_follow.set_offset(invade_path_follow.get_offset() + SPEED * invadeSpeedMultiplier * delta)
	translation = invade_path_spatial.global_translation
	rotation = invade_path_spatial.global_rotation
	if invade_path_follow.get_unit_offset() == 1:
		invade_path.queue_free()
		
		# In bonus level we destroy alien at end of invade path
		if State.is_bonus_level: self.queue_free()
		
		# Randomly distribute space invaders so they don't all get shot at once.
		if formation.is_space_invader_level:
			translation.x = rand_range(Config.formation.minX*15, Config.formation.maxX*15)
		state = FORMING_UP


func formUp(delta):
	var destination = formation.translation + animation_position + Vector3(params.x, params.y, 0)
	translation = lerp(translation, destination, SPEED / FORMING_UP_TRANSLATION_DAMP * delta)
	rotation = lerp(rotation, Vector3(0, 0, 0), SPEED / FORMING_UP_ROTATION_DAMP * delta)
	idleAnimation()
	if translation.distance_to(destination) < 1:
		$Area.add_to_group("AliensInFormation")
		state = IN_FORMATION
		$Area.monitorable = true


func inFormation(delta):
	var destination = formation.translation + animation_position + Vector3(params.x, params.y, 0)
	translation = lerp(translation, destination, SPEED / 7 * delta)
	rotation = lerp(rotation, animation_rotation, SPEED / 15 * delta)
	idleAnimation()
	
	if !formation.is_space_invader_level:
		if randf() < delta / (State.invaderCount * (5-params.type)): # Bigger aliens more likely to attack
			$Area/Mesh/ExhaustParticles.process_material.initial_velocity = 4
			enterAttackState()


func idleAnimation():
	if formation.is_space_invader_level:
		if formation.oddEven != space_invader_mesh_frame:
			space_invader_mesh_frame = formation.oddEven
			var invaderNode:Node
			if params.type == SMALL_INVADER: invaderNode = $Area/Mesh/SpaceInvader3
			if params.type == MEDIUM_INVADER: invaderNode = $Area/Mesh/SpaceInvader2
			if params.type == BIG_INVADER: invaderNode = $Area/Mesh/SpaceInvader1
			var frames = invaderNode.get_child(0).get_children()
			frames[1-space_invader_mesh_frame].visible = false
			frames[space_invader_mesh_frame].visible = true
		return
			
	# params.rand will be between 0.3 and 0.8
	var msec = float(OS.get_ticks_msec() * (params.rand / 2 + 0.3)) / 1500
	var x = sin(msec * (10 + params.rand)) * 0.7
	var y = cos(msec * (8 + params.rand)) * 0.5
	animation_position = Vector3(x, y, 0)
	animation_rotation = Vector3(0, y, x)


func enterAttackState():
	$Area.remove_from_group("AliensInFormation")
	$Area.add_to_group("AliensAttacking")
	attack_speed = 0
	attack_path.translation = self.global_translation
	state = ATTACKING
	$Area/Mesh/ExhaustParticles.emitting = true
	hasTractorBeam = false
	
	# Bosses will always deploy a tractor beem if the player hasn't got a double and has a spare life. 
	if !has_captured_player && params.type == BOSS_ALIEN && State.player.lives > 0:
		hasTractorBeam = true
	
	# Half the attack paths are rotated 180 degrees. Prevent the node from spinning.
	global_rotation.y = global_rotation.y+attack_path.rotation.y


func exitAttackState():
	$Area/Mesh/ExhaustParticles.process_material.initial_velocity = 8
	$Area.remove_from_group("AliensAttacking")
	attack_path_follow.set_offset(0)
	state = FORMING_UP
	$Area/Mesh/ExhaustParticles.emitting = false


func attacking(delta):
	var attack_speed_multiplier = 0.66
	attack_speed = lerp(attack_speed, SPEED * attack_speed_multiplier, 0.4 * delta)
	$Area/Mesh/ExhaustParticles.process_material.initial_velocity = 4 + attack_speed * 0.3
	attack_path_follow.set_offset(attack_path_follow.get_offset() + attack_speed * delta)
	translation = lerp(translation, attack_path_spatial.global_translation, SPEED / 3 * delta)
	#rotation = attack_path_spatial.global_rotation
	rotation.x = lerp_angle(global_rotation.x, attack_path.rotation.x,SPEED / 15 * delta)
	rotation.y = lerp_angle(global_rotation.y, attack_path.rotation.y,SPEED / 15 * delta)
	rotation.z = lerp_angle(global_rotation.z, attack_path_spatial.global_rotation.z,SPEED / 5 * delta)
	if attack_path_follow.get_unit_offset() == 1:
		exitAttackState()
	if hasTractorBeam && global_translation.y < 11.6 && global_translation.y > 11.1:
		if canEmitTractorBeam():
			exitAttackState()
			enterCapturingState()


func canEmitTractorBeam():
	if get_tree().get_nodes_in_group("TractorBeam").size():
		return false
	var player = get_node("/root/GameWorld/Player")
	if player.find_node("StandInPlayerMesh"):
		return false
	if State.player.has_rescued_ship:
		return false
	if State.captured_player_in_formation:
		return false
	return true


func capturing(delta):
	rotation = lerp(rotation, Vector3(0, PI, PI), SPEED / FORMING_UP_ROTATION_DAMP * 3 * delta)


func enterCapturingState():
	state = CAPTURING
	var tractorBeamInstance = tractorBeam.instance()
	self.add_child(tractorBeamInstance)
	$Area.monitorable = false


func exitCapturingState():
	state = FORMING_UP


func animate(direction = "left") -> void:
	pass


func _on_Invader3_tree_exiting() -> void:
	if find_node("StandInPlayerMesh"):
		State.captured_player_in_formation = false
	if !State.gameState == State.STATE_TITLESCREEN && !State.is_bonus_level:
		genPowerUP()
	if State.is_bonus_level && State.gameState == State.STATE_PLAYING && lives < 0:
		emit_signal("trackBonusScores",1,self.scoreValue)
	if is_instance_valid(invade_path):
		invade_path.queue_free()
	if is_instance_valid(attack_path):
		attack_path.queue_free()


func genPowerUP():
	#if params.type != BIG_ALIEN && params.type != MEDIUM_ALIEN: return
	get_node("/root/GameWorld/PowerUpController").spawnByChance(self.global_translation)
