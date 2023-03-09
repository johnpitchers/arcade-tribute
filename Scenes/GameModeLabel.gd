
extends Label3D
var modes: Array = ["3D in 2D", "3D FOLLOW CAM", "CLASSIC ARCADE"]

func _process(_delta: float) -> void:
	self.text = "GAME MODE: " + modes[State.gameMode - 1]
