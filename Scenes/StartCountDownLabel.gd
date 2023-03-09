extends Label3D

var startTimer: Timer
var timeLeft: float
var intTime: int
var size: float


func _ready() -> void:
	startTimer = get_node("/root/GameWorld/Formation/MovementStartTimer")


func _process(_delta: float) -> void:
	if startTimer.is_stopped():
		self.text = ""
		return
	animateTimerLabel()


func animateTimerLabel() -> void:
	timeLeft = startTimer.time_left
	intTime = int(timeLeft)
	if intTime > 2: return
	self.text = str(intTime + 1)
	size = timeLeft - intTime
	self.modulate.a = size
	self.outline_modulate.a = size
	self.scale = Vector3(size * 20, size * 20, 1)
