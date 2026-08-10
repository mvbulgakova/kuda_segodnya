extends "res://scripts/Interactable.gd"

# Общая панель ввода кода (акты 3 и 4). Открывает CodeEntryDialog,
# проверка — на хосте, результат: лично тебе (верно/неверно) + всей
# команде (если верно — снимается общий флаг в GameState.story_flags).

@export var correct_code: String = "1234"
@export var unlock_flag: String = ""
@export var panel_title: String = "Замок"
@export var panel_prompt: String = "Введи код."

var _dialog: Control = null


func _on_interact(_peer_id: int) -> void:
	if _dialog:
		return
	_dialog = preload("res://scenes/CodeEntryDialog.tscn").instantiate()
	get_tree().current_scene.add_child(_dialog)
	_dialog.setup(panel_title, panel_prompt)
	_dialog.submitted.connect(_on_code_submitted)
	_dialog.closed.connect(func() -> void: _dialog = null)


func _on_code_submitted(text: String) -> void:
	_request_unlock.rpc_id(1, multiplayer.get_unique_id(), text)


@rpc("any_peer", "call_remote", "reliable")
func _request_unlock(requester_id: int, text: String) -> void:
	if not multiplayer.is_server():
		return
	var correct: bool = text.strip_edges().to_upper() == correct_code.strip_edges().to_upper()
	_unlock_feedback.rpc_id(requester_id, correct)
	if correct and unlock_flag != "":
		_flag_update.rpc(unlock_flag, true)


@rpc("authority", "call_remote", "reliable")
func _unlock_feedback(correct: bool) -> void:
	if _dialog:
		_dialog.show_result(correct, "Верно! Замок открыт." if correct else "Неверно. Попробуй ещё раз.")


@rpc("authority", "call_local", "reliable")
func _flag_update(flag: String, value: bool) -> void:
	GameState.set_flag(flag, value)
