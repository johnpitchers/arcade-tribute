extends Node

enum {
	STATE_TITLESCREEN,
	STATE_PLAYING,
	STATE_LEVELCOMPLETE,
	STATE_GAMEOVER,
	STATE_PAUSED
}

#var gameState = STATE_PLAYING
var gameMode = Config.gameMode
var gameState = STATE_TITLESCREEN
var gameLevel: int = 1
var is_bonus_level:bool = false
var score: int = 0
var highScore: int = 0
var alienFireRate:float = 1.0
var invaderCount:int = 0
var totalAliensThisLevel:int = 1
var _previousState
var captured_player_in_formation = false

var player:Dictionary = {
	"lives": Config.player.startingLives,
	"lazerLevel": Config.player.lazerLevel,
	"fireRateIncreased": Config.player.fireRateIncreased,
	"has_rescued_ship": false
}

func _ready() -> void:
	pass  # Replace with function body.
