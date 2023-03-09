extends Node

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		match State.gameState:
			State.STATE_PLAYING:
				togglePausedState()
			State.	STATE_LEVELCOMPLETE:
				togglePausedState()
			State.STATE_TITLESCREEN:
				#get_tree().quit()
				pass
	if Input.is_action_just_pressed("ui_accept") && get_tree().paused:
		returnToTitleScreen()
		togglePausedState()
		
func togglePausedState() -> void:
	get_tree().paused = !get_tree().paused
	get_node("/root/GameWorld/MainViewportContainer/Viewport/Camera/GameUI/QuitGame").visible = get_tree().paused

func returnToTitleScreen():
		State.gameState = State.STATE_TITLESCREEN
		get_node("/root/GameWorld/Player").stopAllTimers()
