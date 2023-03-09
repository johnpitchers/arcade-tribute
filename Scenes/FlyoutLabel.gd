extends Label3D

var firstTick = true
var tweenDuration = 1.2
var tweenScale = 3.5
var tweenDistance = 3


func _process(_delta: float) -> void:
	if firstTick:
		firstTick = false
		startTweens()


func init(txt: String = "", trans=Vector3.ZERO, thisSize: float = 1, col = Color(1, 1, 1, 1)):
	self.text = txt
	self.global_translation = trans
	self.scale = self.scale * thisSize
	self.modulate = col


func startTweens():
	$SizeTween.interpolate_property(
		self,
		"scale",
		self.scale,
		self.scale * tweenScale,
		tweenDuration,
		Tween.TRANS_QUAD,
		Tween.EASE_OUT
	)
	$SizeTween.start()

	$MovementTween.interpolate_property(
		self,
		"global_translation",
		self.global_translation,
		(
			self.global_translation
			+ Vector3(
				rand_range(-3,3),
				tweenDistance,
				0
			)
		),
		tweenDuration,
		Tween.TRANS_QUART,
		Tween.EASE_OUT
	)
	$MovementTween.start()

	var colFrom = self.modulate
	var colTo = Color(colFrom.r, colFrom.g, colFrom.b, 0)
	$FadeTween.interpolate_property(
		self, "modulate", colFrom, colTo, tweenDuration, Tween.TRANS_QUAD, Tween.EASE_OUT
	)
	$FadeTween.start()
	
	var col2From = self.outline_modulate
	var col2To = Color(colFrom.r, colFrom.g, colFrom.b, 0)
	$FadeTween2.interpolate_property(
		self, "outline_modulate", col2From, col2To, tweenDuration, Tween.TRANS_QUAD, Tween.EASE_OUT
	)
	$FadeTween2.start()


func _on_SizeTween_tween_all_completed() -> void:
	self.queue_free()
