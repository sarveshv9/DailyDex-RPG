extends Sprite2D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "frame", 3, 0.3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(queue_free)
