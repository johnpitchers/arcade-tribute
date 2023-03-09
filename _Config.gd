extends Node

# Set to true to enable a mode without the arcade CRT TV effect.
var enableModernGameMode: bool = true
var gameMode: int = 3

var player: Dictionary = {
	"startingLives": 3,
	"acceleration": 15,
	"maxSpeed": 20,
	"invulneralbeSeconds": 3,
	"lazerVelocity": 60,
	"lazerLevel": 1,
	"fireRateIncreased": false
}
var powerUpChance: float = 0.04
var maxPowerUpsPerLevel: int = 2
var randNum: int
var userSaveFile: String = "user://arcadetribute_saveData.res"  # Home/.local/share/godot/app_userdata/Arcade Tribute
var startingLevel: int = 1
var formation: Dictionary = {
	"columns": 8,  #8
	"rows": 5,  #5
	"maxColumns": 12,
	"maxRows": 10,
	"maxSpaceInvaderRows": 9,
	"alien1Lives": 0,
	"alien2Lives": 0,
	"alien3Lives": 0,
	"spacing": {"x": 2.5, "y": 2.25},
	"startPosition": {"x": 0, "y": 20.5},
	"minX": -4,
	"maxX": 4,
	"minY": 0,
	"movementTimerStartTime": 4,
	"movementSpeed": 2.5,
	"baseFireRate": 0.001,
	"fireRateIncreasePerLevel": 1.04,
	"inLevelFireRateIncrease": 20,
	"numberOfBosses": 4,
	"spaceInvaderMovementLerpSpeed": 0.3
}
var gameHints: Array = [
	"This game is a tribute to games like Galaxian and Galaga - classics from the golden age of video games",
	"Galaxian was released in 1979 just one year after the classic Space Invaders.",
	"Space Invaders is featured in the Museum of Modern Art in New York.",
	"This is not the greatest game in the world, no. It's just a tribute! -Tenacious D? :)",
	"The pixelated alien Space Invader has become a pop culture icon.",
	"Galaxian's sequel Galaga was released in 1981 and was a commercial success for Namco.",
	"In 1982, Space Invaders was the highest grossing entertainment product at the time.",
	"If a boss captures your ship you lose a life. Recapture it to get your life back and double your fire power.",
	'The octopus like space invader shapes were inspired by the 1953 movie "War of the Worlds"',
	"Tomohiro Nishikado developed Space Invaders in 1978. His name was never put on the game for contractual reasons."
]
var starfield: Dictionary = {
	"maxStars": 450,
	"ratioOfBlinkers": 0.20,
	"minY": -10,
	"maxY": 50,
	"minX": -55,
	"maxX": 55,
	"minSize": 0.05,
	"maxSize": 0.12,
	"colors":
	[
		[0, 1, 0, 1],
		[1, 1, 0, 1],
		[1, 0, 0, 1],
		[0, 0, 1, 1],
		[1, 0, 1, 1],
		[1, 0.5, 0, 1],
		[1, 1, 1, 1]
	],
	"speed": 2.6
}
var motherShip: Dictionary = {
	"first_interval": 40,
	"interval": 30,
	"fireRate": 12.0,
	"velocity": 1.2,
	"center": {"x": 0, "y": 43, "z": 0},
	"radius": {"x": 30, "y": 12},
	"lives": 8
}


func _ready() -> void:
	randomize()
	randNum = randi() % 100000
