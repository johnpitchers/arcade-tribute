##################################################
#
# This scrips takes an array of emitters, plays
# them and disposes of them at the end of the
# longest emitter lifetime.
#
# Ensure each emitter is set to "One shot"
#
##################################################
extends Spatial
onready var emitters: Array = [$PowerUpParticles]
var lifeTime: float = 0.0
var text = ""

var flyOutlabel = preload("res://Scenes/FlyoutLabel.tscn")

func _ready() -> void:
	var flyOutInstance = flyOutlabel.instance()
	flyOutInstance.init(text, global_translation)
	get_node("/root/GameWorld").add_child(flyOutInstance)
	startEmitters()
	getLifetime()
	$DisposeTimer.wait_time = lifeTime+0.2
	$DisposeTimer.one_shot = true
	$DisposeTimer.start()


func _process(_delta: float) -> void:
	global_rotation = Vector3(0,0,0)
	pass


func getLifetime():
	for emitter in emitters:
		var emitterLifetime:float = emitter.lifetime - emitter.preprocess
		if emitterLifetime > lifeTime:
			lifeTime = emitterLifetime


func _on_DisposeTimer_timeout():
	disposeOfEmitters()


func startEmitters():
	for emitter in emitters:
		emitter.emitting = true


func disposeOfEmitters():
	for emitter in emitters:
		emitter.queue_free()
	self.queue_free()
