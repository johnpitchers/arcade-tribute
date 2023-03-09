extends Area

var lives = Config.motherShip.lives
var scoreValue = 1000
var direction = 1
var center = Vector3(Config.motherShip.center.x, Config.motherShip.center.y, Config.motherShip.center.z)
var radius = {"x": Config.motherShip.radius.x, "y": Config.motherShip.radius.y}
var rad: float
var fireRate: float = Config.motherShip.fireRate*100
onready var lazer = preload("res://Scenes/InvaderLazer.tscn")
onready var explosion = preload("res://Scenes/Explosion.tscn")
signal motherShipTimerRestart


func _ready() -> void:
# warning-ignore:return_value_discarded
	connect(
		"motherShipTimerRestart", get_node("/root/GameWorld/Formation"), "motherShipTimerRestart"
	)
	randomize()
	direction = 1
	rad = 0
	if randf() < 0.5:
		direction = -1
		rad = PI
	rotation.y = PI/2 + PI/2 * direction
	playFlyingSound()

func playFlyingSound():
	$AudioStreamPlayer.play()

func _process(delta: float) -> void:
	loopArc(delta)
	fireLazers(delta)
	recoverRotations()
	if State.gameState != State.STATE_PLAYING:
		slideOut(delta)


func recoverRotations():
	radius.y = lerp(radius.y, Config.motherShip.radius.y, 0.1)
	$Pacman.rotation.x = lerp_angle($Pacman.rotation.x, -PI/2, 0.1)


func fireLazers(delta):
	if !State.gameState == State.STATE_PLAYING: return
	var firenow = randf() / Config.motherShip.fireRate < delta
	if firenow:
		var lazerInstance = lazer.instance()
		lazerInstance.translation = self.global_translation
		lazerInstance.velocity *= 1.5
		lazerInstance.rotation_degrees = Vector3(0, 0, 180 + (rand_range(-10, 10)) + 45 * direction)
		lazerInstance.color = Color(randf(),0,1,1)
		get_node("/root/GameWorld").add_child(lazerInstance)


func loopArc(delta):
	rad += float(Config.motherShip.velocity) / 6 * delta * direction
	var x = center.x + cos(rad) * radius.x
	var y = center.y - sin(rad) * radius.y
	self.global_translation = Vector3(x, y, 0)

	print($Pacman.rotation)

	if rad < 0 || rad > PI:
		self.queue_free()
		emit_signal("motherShipTimerRestart")


func hitByPlayer(trans):
	var explosionNum:int = 150
	var explosionforce:float = 8
	var explosionScale:float = 0.85
	var explosionType:String = "MotherShip"
	self.lives -= 1
	if self.lives < 0:
		State.score += self.scoreValue
		get_node("/root/GameWorld/Formation").motherShipTimerRestart()
		trans = self.global_translation
		self.queue_free()
	else:
		explosionNum = 15
		explosionforce = 1.5
		explosionScale = 0.5
		explosionType = "null"
		self.radius.y *= 0.9
		$Pacman.rotate_x(rand_range(-0.5, 0.5))
	var explosionInstance = explosion.instance()
	get_node("/root/GameWorld").add_child(explosionInstance)
	explosionInstance.init(
		trans, explosionNum, explosionforce, explosionScale, explosionType
	)

func slideOut(delta):
	center.y = center.y+(delta*2)
	if center.y > 40:
		queue_free()
