extends CanvasLayer

@onready var label = $Background/RichTextLabel
@onready var timer = $Timer

var is_active = false
var text_to_show = ""
var visible_chars = 0

func _ready():
	hide()
	timer.timeout.connect(_on_timer_timeout)

func show_dialogue(text: String):
	text_to_show = text
	label.text = text
	visible_chars = 0
	label.visible_characters = 0
	show()
	is_active = true
	timer.start(0.05) # Text reveal speed

func _on_timer_timeout():
	visible_chars += 1
	label.visible_characters = visible_chars
	if visible_chars >= text_to_show.length():
		timer.stop()

func _input(event):
	if is_active and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not timer.is_stopped():
			# Skip to end
			timer.stop()
			label.visible_characters = -1
		else:
			# Close
			hide()
			is_active = false
