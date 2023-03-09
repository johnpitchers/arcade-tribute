extends Spatial


func _ready() -> void:
	$Instructions/Text/AnimationPlayer.play("Hue")


func _process(_delta: float) -> void:
	if State.gameState != State.STATE_TITLESCREEN:
		return
	animateTitle()
	if Input.is_action_just_pressed("ui_shoot") && $SmallPauseTimer.is_stopped():
		State.gameState = State.STATE_PLAYING
	if (Input.is_action_just_pressed("ui_right")) && $SmallPauseTimer.is_stopped():
		State.gameMode += 1
		if State.gameMode > 3:
			if Config.enableModernGameMode:
				State.gameMode = 1
			else:
				State.gameMode = 2
		changeGameMode()
	if (Input.is_action_just_pressed("ui_left")) && $SmallPauseTimer.is_stopped():
		State.gameMode -= 1
		if !Config.enableModernGameMode && State.gameMode==1:
			State.gameMode = 3 
		if State.gameMode < 1:
			State.gameMode = 3
			
		changeGameMode()


func changeGameMode() -> void:
	get_node("/root/GameWorld").setGameMode()
	get_node("/root/GameWorld").saveData()


func animateTitle() -> void:
	$SpaceInvadersTitle.scale.y = 60 + 3.5 * sin(OS.get_ticks_msec() / PI / 500)


func smallPause() -> void:
	$SmallPauseTimer.start()
