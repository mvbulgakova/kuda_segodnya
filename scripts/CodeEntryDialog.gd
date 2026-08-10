extends Control

# Переиспользуемое окно ввода кода — используется LockPanel и в акте 3,
# и в акте 4. Конфигурируется через setup() ПОСЛЕ add_child (иначе
# @onready-поля ещё не инициализированы).

signal submitted(text: String)
signal closed()

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var prompt_label: Label = $Panel/VBox/PromptLabel
@onready var code_edit: LineEdit = $Panel/VBox/CodeEdit
@onready var submit_button: Button = $Panel/VBox/SubmitButton
@onready var status_label: Label = $Panel/VBox/StatusLabel


func setup(title: String, prompt: String) -> void:
	title_label.text = title
	prompt_label.text = prompt


func show_result(correct: bool, message: String) -> void:
	submit_button.disabled = false
	status_label.text = message
	if correct:
		submit_button.disabled = true
		code_edit.editable = false
		await get_tree().create_timer(1.2).timeout
		_on_close_pressed()


func _on_submit_pressed() -> void:
	var text := code_edit.text.strip_edges()
	if text == "":
		return
	submit_button.disabled = true
	status_label.text = "Проверяю…"
	submitted.emit(text)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
