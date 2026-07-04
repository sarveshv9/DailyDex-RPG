extends CanvasLayer
## Message manager — displays dialogue in a styled NinePatchRect box
## with typewriter text reveal. GDScript replacement for MessageManager.cs.

signal message_finished

var _messages: Array[String] = []
var _current_index: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _displayed_text: String = ""
var _full_text: String = ""
var _char_index: int = 0
var _char_timer: float = 0.0
const CHAR_DELAY := 0.03

@onready var box: NinePatchRect = $Control/NinePatchRect
@onready var label: RichTextLabel = $Control/NinePatchRect/RichTextLabel


func _ready() -> void:
	if box:
		box.visible = false


func _process(delta: float) -> void:
	if not _is_showing:
		return

	if _is_typing:
		_char_timer += delta
		while _char_timer >= CHAR_DELAY and _char_index < _full_text.length():
			_char_timer -= CHAR_DELAY
			_char_index += 1
			_displayed_text = _full_text.substr(0, _char_index)
			if label:
				label.text = _displayed_text
		if _char_index >= _full_text.length():
			_is_typing = false

	# Advance on interact press
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
		if _is_typing:
			# Skip typewriter, show full text
			_char_index = _full_text.length()
			_displayed_text = _full_text
			if label:
				label.text = _displayed_text
			_is_typing = false
		else:
			# Next message or close
			_current_index += 1
			if _current_index < _messages.size():
				_show_message(_messages[_current_index])
			else:
				_close()


func show_messages(messages: Array) -> void:
	if messages.is_empty():
		return
	_messages.clear()
	for m in messages:
		_messages.append(str(m))
	_current_index = 0
	_is_showing = true
	if box:
		box.visible = true
	_show_message(_messages[0])


func _show_message(text: String) -> void:
	_full_text = text
	_displayed_text = ""
	_char_index = 0
	_char_timer = 0.0
	_is_typing = true
	if label:
		label.text = ""


func _close() -> void:
	_is_showing = false
	if box:
		box.visible = false
	_messages.clear()
	message_finished.emit()


func is_active() -> bool:
	return _is_showing
