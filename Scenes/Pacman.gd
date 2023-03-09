extends Spatial

var frames:Array
var num_frames: int

func _ready() -> void:
	frames = get_children()
	num_frames = frames.size()


func _process(delta: float) -> void:
	var msecs = OS.get_system_time_msecs()
	var visible_frame = ((msecs / 100) % 4) + 1
	for frame in num_frames:
		frames[frame].visible = bool(visible_frame == frame+1)
