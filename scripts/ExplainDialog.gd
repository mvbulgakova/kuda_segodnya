extends Control

# Педагогическая мини-игра.
# Игрок пишет объяснение темы. LLM (через LLMBridge) отвечает как школьник.
# Понял — +1 педагогики, катсцена радости. Не понял — можно переформулировать.

@export var topic: String = "монотонность функции"

@onready var topic_label: Label = $Panel/VBox/TopicLabel
@onready var explanation_edit: TextEdit = $Panel/VBox/ExplanationEdit
@onready var send_button: Button = $Panel/VBox/SendButton
@onready var reply_label: RichTextLabel = $Panel/VBox/ReplyLabel


func _ready() -> void:
	topic_label.text = "Младший брат просит объяснить: «%s»" % topic
	reply_label.text = ""
	LLMBridge.explanation_evaluated.connect(_on_evaluated)


func _on_send_pressed() -> void:
	var text := explanation_edit.text.strip_edges()
	if text == "":
		reply_label.text = "[i]Напиши хоть что-нибудь…[/i]"
		return
	send_button.disabled = true
	reply_label.text = "[i]Брат читает…[/i]"
	LLMBridge.evaluate_explanation(topic, text)


func _on_evaluated(understood: bool, comment: String) -> void:
	send_button.disabled = false
	if understood:
		GameState.add_pedagogy(1)
		reply_label.text = "[color=green][b]Понял! Спасибо![/b][/color]\n%s" % comment
	else:
		reply_label.text = "[color=orange]Пока не понял.[/color]\n%s\n\nПопробуй объяснить по-другому." % comment


func _on_close_pressed() -> void:
	queue_free()
