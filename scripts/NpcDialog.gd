extends Control

# Свободный чат с NPC через LLMBridge → /npc (см. GAME_DESIGN.md, «Механики
# Claude», п.2). character_id/display_name выставляются вызывающим ДО
# add_child, чтобы _ready() успел подставить их в заголовок.

@export var character_id: String = "senior_artem"
@export var display_name: String = "Артём"

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var history_label: RichTextLabel = $Panel/VBox/HistoryLabel
@onready var input_edit: LineEdit = $Panel/VBox/InputRow/InputEdit
@onready var send_button: Button = $Panel/VBox/InputRow/SendButton

var _waiting: bool = false


func _ready() -> void:
	title_label.text = display_name
	history_label.text = ""
	LLMBridge.npc_reply_received.connect(_on_reply)


func _on_send_pressed() -> void:
	_send(input_edit.text)


func _on_input_edit_text_submitted(_new_text: String) -> void:
	_send(input_edit.text)


func _send(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	if text == "" or _waiting:
		return
	_append("[b]Ты:[/b] %s" % text)
	input_edit.text = ""
	_waiting = true
	send_button.disabled = true
	LLMBridge.ask_npc(character_id, text)


func _on_reply(character: String, text: String) -> void:
	if character != character_id:
		return
	_waiting = false
	send_button.disabled = false
	_append("[b]%s:[/b] %s" % [display_name, text])


func _append(line: String) -> void:
	history_label.append_text(line + "\n\n")


func _on_close_pressed() -> void:
	queue_free()
