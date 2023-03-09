extends Timer

# Calculates the formation's fire rate every second.
# Doing this calculation once and adding it to the global State is
# more performant than each invader calculating if for themselves.


func _ready() -> void:
	State.alienFireRate = Config.formation.baseFireRate


func _on_CalculateFirerateTimer_timeout() -> void:
	State.invaderCount = float(get_tree().get_nodes_in_group("Invaders").size())
	if State.gameState != State.STATE_PLAYING || State.invaderCount == 0:
		return

	var y1: float = 1.0  # Lowest/starting multiplier at beginning of invader wave
	var y2: float = Config.formation.inLevelFireRateIncrease  # Highest multiplier at end of invader wave
	var x1: float = State.totalAliensThisLevel
	var x2: float = 1  # Highest fire rate reached when only this number of invaders are left

	var lerped_multiplier = ((State.invaderCount - x1) * (y2 - y1) / (x2 - x1)) + y1
	State.alienFireRate = (
		Config.formation.baseFireRate
		* pow(Config.formation.fireRateIncreasePerLevel, State.gameLevel)
		* lerped_multiplier
	)
