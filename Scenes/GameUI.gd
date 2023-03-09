extends Spatial

var livesString= "^^^"


func _ready() -> void:
	pass  # Replace with function body.


func _process(_delta: float) -> void:
	$TopPanel/Score.text = "SCORE:" + str(State.score)
	$TopPanel/Lives.text = "LIVES:" + (str(State.player.lives) if State.player.lives > 0 else "0")
	$TopPanel/Level.text = "LEVEL:" + str(State.gameLevel)
	$TopPanel/High.text = "HIGH:" + str(State.highScore)
