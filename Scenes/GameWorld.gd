extends Spatial

var _fromState
var userData

var bonus_hits: int = 0
var bonus_score: int = 0

# These scenes aren't used in this script but it is preloaded to 
# avoid stutter during explosions
onready var particleMesh = preload("res://Scenes/ExplosionParticle.tscn")
onready var explosionMesh = preload("res://Scenes/Explosion.tscn")
onready var lazerMesh = preload("res://Scenes/InvaderLazer.tscn")
onready var flyOutlabel = preload("res://Scenes/FlyoutLabel.tscn")
onready var tractorBeam = preload("res://Scenes/TractorBeam.tscn")


func _ready() -> void:
	loadData()
	setGameMode()


func _process(_delta: float) -> void:
	detectChangeOfState()
	if State.gameState == State.STATE_LEVELCOMPLETE:
		if $LevelCompleteTimer.is_stopped():
			destroyBarriers()
		if $LevelCompleteTimer.is_stopped():
			if $NextLevelTimer.is_stopped():
				$NextLevelTimer.start()
	if State.gameState == State.STATE_PLAYING:
		var invaders = get_tree().get_nodes_in_group("Invaders")
		if invaders.size() == 0 && $Formation.spawnComplete:
			State.gameState = State.STATE_LEVELCOMPLETE

	if (
		State.gameState == State.STATE_GAMEOVER
		&& $MainViewportContainer/Viewport/Camera/GameUI/PressShootToReplay.visible == true
	):
		if Input.is_action_just_pressed("ui_shoot"):
			$MainViewportContainer/Viewport/Camera/GameUI/GameOver/AnimationPlayer.play("RESET")
			$MainViewportContainer/Viewport/Camera/TitleScreen/SmallPauseTimer.start()
			State.gameState = State.STATE_TITLESCREEN


func setGameMode() -> void:
	match State.gameMode:
		1:  # Clean 3D in 2D mode. Set Config.enableModernGameMode = true			
			$CRTViewportContainer.visible = false
			$MainViewportContainer/Viewport/Camera.translation = Vector3(0, 17, 40)
			$MainViewportContainer/Viewport/Camera.rotation_degrees = Vector3.ZERO
			$MainViewportContainer/Viewport.keep_3d_linear = false
			$WorldEnvironment.environment.fog_enabled = false
			$MainViewportContainer/Viewport/Camera/ScanLines.visible = false
			$MainViewportContainer/Viewport/Camera/TitleScreen/Instructions.translation.y = 13.2
			$MainViewportContainer/Viewport/Camera/TitleScreen/Instructions.rotation_degrees = Vector3.ZERO
			$MainViewportContainer/Viewport/Camera/TitleScreen/SpaceInvadersTitle.rotation_degrees.x = 65
			$WorldEnvironment.environment.glow_enabled = false
			$WorldEnvironment.environment.glow_strength = 0.6
			$WorldEnvironment.environment.glow_bloom = 0.8
			$WorldEnvironment.environment.background_color = Color(0, 0, 0.08)
			$Starfield.translation = Vector3.ZERO
			$Starfield.rotation_degrees = Vector3.ZERO
		2:  # Action cam
			$CRTViewportContainer.visible = false
			$MainViewportContainer/Viewport.keep_3d_linear = false
			$MainViewportContainer/Viewport/Camera/ScanLines.visible = false
			$WorldEnvironment.environment.fog_enabled = true
			$WorldEnvironment.environment.glow_enabled = false
			$WorldEnvironment.environment.glow_intensity = 0.15
			$WorldEnvironment.environment.glow_strength = 0.4
			$WorldEnvironment.environment.glow_bloom = 1
			$WorldEnvironment.environment.background_color = Color(0, 0.05, 0.07)
			$MainViewportContainer/Viewport/Camera.translation = Vector3(0, -10, 14)
			$MainViewportContainer/Viewport/Camera.rotation_degrees = Vector3(57, 0, 0)
			$MainViewportContainer/Viewport/Camera/TitleScreen/Instructions.translation.y = 12.2
			$MainViewportContainer/Viewport/Camera/TitleScreen/Instructions.rotation_degrees.x = -60
			$MainViewportContainer/Viewport/Camera/TitleScreen/SpaceInvadersTitle.rotation_degrees.x = 65
			$Player.global_translation.x = 10
			#$Starfield.translation = Vector3(0, 11, -32)
			#$Starfield.rotation_degrees = Vector3(57, 0, 0)
			$Starfield.translation = Vector3(0, 10, 1)
			$Starfield.rotation_degrees = Vector3(11, 0, 0)
		3:  #CRT
			$CRTViewportContainer.visible = true
			$MainViewportContainer/Viewport.keep_3d_linear = true
			$MainViewportContainer/Viewport/Camera/ScanLines.visible = true
			$WorldEnvironment.environment.fog_enabled = false
			$WorldEnvironment.environment.glow_enabled = true
			$WorldEnvironment.environment.glow_intensity = 0.4
			$WorldEnvironment.environment.glow_strength = 0.4
			$WorldEnvironment.environment.glow_bloom = 1
			$WorldEnvironment.environment.background_color = Color(0, 0.05, 0.07)
			$MainViewportContainer/Viewport/Camera/TitleScreen/Instructions.translation.y = 13.4
			$MainViewportContainer/Viewport/Camera/TitleScreen/Instructions.rotation_degrees = Vector3.ZERO
			$MainViewportContainer/Viewport/Camera/TitleScreen/SpaceInvadersTitle.rotation_degrees.x = 60
			$MainViewportContainer/Viewport/Camera.translation = Vector3(0, 17, 40)
			$MainViewportContainer/Viewport/Camera.rotation_degrees = Vector3.ZERO
			$Starfield.translation = Vector3.ZERO
			$Starfield.rotation_degrees = Vector3.ZERO


func loadData() -> void:
	var userFile = Config.userSaveFile
	if ResourceLoader.exists(userFile):
		userData = ResourceLoader.load(userFile)
	else:
		# The first time the game is run.
		userData = ResourceLoader.load("res://_saveData.res")
		userData.highScore = 0
		userData.gameMode = 3
		State.highScore = userData.highScore
		State.gameMode = userData.gameMode
		Config.randNum = 0  # The player will get game facts in a logical order.
		saveData()
	State.highScore = userData.highScore
	if !Config.enableModernGameMode && userData.gameMode == 1:
		userData.gameMode = 3
	State.gameMode = userData.gameMode


# warning-ignore:return_value_discarded
func saveData():
	userData.highScore = State.highScore
	userData.gameMode = State.gameMode
	ResourceSaver.save(Config.userSaveFile, userData)


func checkForNewHighScore():
	if State.score > State.highScore:
		State.highScore = State.score
		saveData()


func detectChangeOfState():
	if State.gameState != _fromState:
		_fromState = State.gameState
		initialiseNewState()


func initialiseNewState():
	match State.gameState:
		State.STATE_LEVELCOMPLETE:
			levelComplete()
		State.STATE_TITLESCREEN:
			hideAll()
			showTitleScreen()
			resetPlayState()
		State.STATE_PLAYING:
			hideAll()
			State.is_bonus_level = isBonusLevel()
			$Player.init()
			$Formation.init()
			$MainViewportContainer/Viewport/Camera/GameUI/TopPanel.visible = true
			$PowerUpController.power_ups_this_level = 0
			$MainViewportContainer/Viewport/Camera/GameUI/WaveTitleLabel.setText()
			preInstanceNodes()
			
			
		State.STATE_GAMEOVER:
			$MainViewportContainer/Viewport/Camera/GameUI/GameOver.visible = true
			$MainViewportContainer/Viewport/Camera/GameUI/GameOver/AnimationPlayer.play("ScaleIn")
			$MainViewportContainer/Viewport/Camera/GameUI/GameOver/GameOverTimer.start()
			checkForNewHighScore()

# This function is required to stop jitter the first time nodes are loaded into the scene.
# Preloading has absoltely no effect what so ever. I don't know why this occurs. 
# Google tells me it's a shader compilation bug that should be fixed. Only thing 
# that has worked is loading each node into the scene and making it oscure by moving it
# to the edge and turning the alpha opacity down. Hopefully Godot 4.0 will have this fixed.
func preInstanceNodes():
	var preloadTranslation = Vector3(25,-1.5,0)
	if State.gameMode == 2:
		preloadTranslation = Vector3(9,0,0)
	
	# Explosions
	var tempExplosion = explosionMesh.instance()
	add_child(tempExplosion)
	tempExplosion.init(preloadTranslation, 1, 0.3, 0.1, "None")
	
	# Invader Lazer. Looks like one of the stars
	var lazerInstance = lazerMesh.instance()
	lazerInstance.velocity = 1
	lazerInstance.muted = true
	lazerInstance.life = 1
	lazerInstance.color = Color(1,1,1,0.01)
	lazerInstance.translation = preloadTranslation
	lazerInstance.rotation_degrees = rotation_degrees + Vector3(0, 0, 180)
	add_child(lazerInstance)
	
	# Text flyout
	var flyOutInstance = flyOutlabel.instance()
	flyOutInstance.init("GET READY", preloadTranslation)
	flyOutInstance.modulate.a = 0.01
	flyOutInstance.outline_modulate.a = 0.005
	add_child(flyOutInstance)
	
	# Tractor beam
	var tractorbeamtimer = Timer.new()
	tractorbeamtimer.wait_time = 5.0
	tractorbeamtimer.one_shot = true
	tractorbeamtimer.connect("timeout", self, "genPreInstancedTractorBeam",[preloadTranslation])
	self.add_child(tractorbeamtimer)
	tractorbeamtimer.start()


func genPreInstancedTractorBeam(trans):
	var tractorBeamInstance = tractorBeam.instance()
	tractorBeamInstance.translation = trans
	tractorBeamInstance.muted = true
	self.add_child(tractorBeamInstance)
	

func resetPlayState():
	State.player.has_rescued_ship = $Player.dev_has_rescued_ship
	$Player.is_first_lazer_muted = true
	State.gameLevel = Config.startingLevel
	State.player.lives = Config.player.startingLives
	State.player.lazerLevel = Config.player.lazerLevel
	State.player.fireRateIncreased = Config.player.fireRateIncreased
	State.score = 0
	bonus_hits = 0
	bonus_score = 0


func hideAll():
	$Player.visible = false
	$Formation.visible = false
	$MainViewportContainer/Viewport/Camera/TitleScreen.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/BonusScore.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/GameHints.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/TopPanel.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/GameOver.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/PressShootToReplay.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/NewHighScore.visible = false
	$MainViewportContainer/Viewport/Camera/GameUI/NewHighScore/Score/AnimationPlayer.stop(true)
	$MainViewportContainer/Viewport/Camera/GameUI/WaveTitleLabel.visible = false
	removeGameNodes()


func removeGameNodes():
	$Player.visible = false
	removeNodesofType("Invaders")
	removeNodesofType("Lazers")
	removeNodesofType("MotherShip")
	removeNodesofType("Bricks")
	# Keep power ups active when transitioning between game levels
	if State.gameLevel == 1 || State.gameState == State.STATE_TITLESCREEN:
		removeNodesofType("PowerUps")
	$Formation/MovementStartTimer.stop()
	$Formation/MotherShipSpawnTimer.stop()
	var formationTimers = get_tree().get_nodes_in_group("AlienSpawnTimers")
	for timer in formationTimers:
		timer.stop()
	removeNodesofType("AlienSpawnTimers")


func removeNodesofType(group):
	var nodes = get_tree().get_nodes_in_group(group)
	for node in nodes:
		if group == "Invaders":
			node.get_parent().queue_free()
		else:
			node.queue_free()


func showTitleScreen():
	$MainViewportContainer/Viewport/Camera/TitleScreen.visible = true


func levelComplete():
	$Player.can_shoot = false
	$Player/CollisionShape.disabled = true
	$Player/RescuedShip/CollisionShape.disabled = true
	$LevelCompleteTimer.start()
	$Formation/MotherShipSpawnTimer.stop()


func destroyBarriers():
	var bricks = get_tree().get_nodes_in_group("Bricks")
	for i in int(bricks.size() / 20 + 1):
		if !bricks.size():
			return false
		var index = int(rand_range(0, bricks.size()))
		$Formation/Barriers.barrierDestroy(bricks[index])
		State.score += 10

func nextLevel():
	State.gameLevel += 1
	State.gameState = State.STATE_PLAYING


func isBonusLevel():
	var is_bonus: bool = false
	# Every 4th stage is a bonus stage.
	if State.gameLevel % 4 == 0:
		is_bonus = true
	if !State.is_bonus_level && is_bonus:
		bonus_hits = 0
		bonus_score = 0
	return is_bonus


func trackBonusScores(hit: int = 0, score: int = 0):
	bonus_hits += hit
	bonus_score += score


func _on_NextLevelTimer_timeout() -> void:
	nextLevel()


func _on_LevelCompleteTimer_timeout() -> void:
	$Player.slideOut()
	if State.is_bonus_level && State.STATE_PLAYING:
		showBonusScore()
	else:
		showGameHints()
	$LevelCompleteAudio.play()


func showBonusScore():
	$MainViewportContainer/Viewport/Camera/GameUI/BonusScore/Hits.text = str(bonus_hits)
	$MainViewportContainer/Viewport/Camera/GameUI/BonusScore/Score.text = str(bonus_score)
	$MainViewportContainer/Viewport/Camera/GameUI/BonusScore.visible = true
	pass


func showGameHints():
	$MainViewportContainer/Viewport/Camera/GameUI/GameHints/Text.text = Config.gameHints[(
		(State.gameLevel + Config.randNum) % Config.gameHints.size()
		- 1
	)]
	$MainViewportContainer/Viewport/Camera/GameUI/GameHints.visible = true


func _on_GameOverTimer_timeout() -> void:
	$MainViewportContainer/Viewport/Camera/GameUI/PressShootToReplay.visible = true
	if State.score == State.highScore:
		$MainViewportContainer/Viewport/Camera/GameUI/NewHighScore/Score.text = str(State.highScore)
		$MainViewportContainer/Viewport/Camera/GameUI/NewHighScore.visible = true
		$MainViewportContainer/Viewport/Camera/GameUI/NewHighScore/Score/AnimationPlayer.play("Hue")
