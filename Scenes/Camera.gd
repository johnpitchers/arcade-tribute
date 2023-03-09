extends Camera


# Follow the player.
func _process(delta: float) -> void:
	if State.gameMode == 2:
		var playerX = $"%Player".translation.x
		translation.x = lerp(translation.x, playerX /2, 5 * delta)
