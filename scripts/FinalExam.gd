extends Control

# Акт 5. Финальная КР.
# Аналитик/Алгебраист/Геометр видят личную задачу и свой шаг командного
# доказательства. Староста не решает — видит прогресс команды и сдаёт
# итоговый ответ, когда все три шага сойдутся.
# Проверка ответов — на хосте (authority), результат рассылается всем,
# чтобы прогресс был общим для команды.

@onready var my_task_panel: PanelContainer = $Margin/VBox/MyTaskPanel
@onready var my_task_title: Label = $Margin/VBox/MyTaskPanel/VBox/TitleLabel
@onready var my_task_prompt: Label = $Margin/VBox/MyTaskPanel/VBox/PromptLabel
@onready var my_task_edit: LineEdit = $Margin/VBox/MyTaskPanel/VBox/AnswerEdit
@onready var my_task_submit: Button = $Margin/VBox/MyTaskPanel/VBox/SubmitButton
@onready var my_task_status: Label = $Margin/VBox/MyTaskPanel/VBox/StatusLabel

@onready var team_task_panel: PanelContainer = $Margin/VBox/TeamTaskPanel
@onready var team_task_title: Label = $Margin/VBox/TeamTaskPanel/VBox/TitleLabel
@onready var team_narrative: Label = $Margin/VBox/TeamTaskPanel/VBox/NarrativeLabel
@onready var team_prompt: Label = $Margin/VBox/TeamTaskPanel/VBox/PromptLabel
@onready var team_edit: LineEdit = $Margin/VBox/TeamTaskPanel/VBox/AnswerEdit
@onready var team_submit: Button = $Margin/VBox/TeamTaskPanel/VBox/SubmitButton
@onready var team_status: Label = $Margin/VBox/TeamTaskPanel/VBox/StatusLabel

@onready var starosta_panel: PanelContainer = $Margin/VBox/StarostaPanel
@onready var team_progress_list: VBoxContainer = $Margin/VBox/StarostaPanel/VBox/ProgressList
@onready var final_edit: LineEdit = $Margin/VBox/StarostaPanel/VBox/FinalEdit
@onready var final_submit: Button = $Margin/VBox/StarostaPanel/VBox/FinalSubmitButton

var solving_roles := [GameState.Role.ANALYST, GameState.Role.ALGEBRAIST, GameState.Role.GEOMETER]


func _ready() -> void:
	GameState.exam_progress_changed.connect(_refresh)
	my_task_panel.visible = false
	team_task_panel.visible = false
	starosta_panel.visible = false

	if GameState.my_role == GameState.Role.STAROSTA:
		starosta_panel.visible = true
	elif GameState.my_role in solving_roles:
		my_task_panel.visible = true
		team_task_panel.visible = true
		var individual: Dictionary = ExamTasks.individual_task(GameState.my_role)
		var team: Dictionary = ExamTasks.team_task()
		var sub: Dictionary = team["sub"][GameState.my_role]
		my_task_title.text = individual.get("title", "")
		my_task_prompt.text = individual.get("prompt", "")
		team_task_title.text = team.get("title", "")
		team_narrative.text = team.get("narrative", "")
		team_prompt.text = sub.get("prompt", "")

	_refresh()


func _on_my_task_submit_pressed() -> void:
	var text := my_task_edit.text.strip_edges()
	if text == "":
		return
	my_task_submit.disabled = true
	_submit_individual.rpc_id(1, GameState.my_role, text)


func _on_team_task_submit_pressed() -> void:
	var text := team_edit.text.strip_edges()
	if text == "":
		return
	team_submit.disabled = true
	_submit_team_sub.rpc_id(1, GameState.my_role, text)


func _on_final_submit_pressed() -> void:
	var text := final_edit.text.strip_edges()
	if text == "":
		return
	final_submit.disabled = true
	_submit_team_final.rpc_id(1, text)


func _refresh() -> void:
	if my_task_panel.visible:
		var res: Dictionary = GameState.exam_individual.get(GameState.my_role, {})
		if res.is_empty():
			my_task_status.text = ""
		elif res.get("correct", false):
			my_task_status.text = "Верно!"
			my_task_edit.editable = false
		else:
			my_task_status.text = "Неверно, попробуй ещё раз."
			my_task_submit.disabled = false

	if team_task_panel.visible:
		var tres: Dictionary = GameState.exam_team_sub.get(GameState.my_role, {})
		if tres.is_empty():
			team_status.text = ""
		elif tres.get("correct", false):
			team_status.text = "Шаг принят."
			team_edit.editable = false
		else:
			team_status.text = "Неверно, попробуй ещё раз."
			team_submit.disabled = false

	if starosta_panel.visible:
		_refresh_progress_list()


func _refresh_progress_list() -> void:
	for child in team_progress_list.get_children():
		child.queue_free()
	var all_sub_ok := true
	for role in solving_roles:
		var ind: Dictionary = GameState.exam_individual.get(role, {})
		var sub: Dictionary = GameState.exam_team_sub.get(role, {})
		if not sub.get("correct", false):
			all_sub_ok = false
		var l := Label.new()
		l.text = "%s — личная задача: %s · командный шаг: %s" % [
			GameState.role_name(role), _status_icon(ind), _status_icon(sub)
		]
		team_progress_list.add_child(l)
	final_edit.editable = all_sub_ok
	final_submit.disabled = not all_sub_ok


func _status_icon(res: Dictionary) -> String:
	if res.is_empty():
		return "…"
	return "✓" if res.get("correct", false) else "✗"


@rpc("any_peer", "call_remote", "reliable")
func _submit_individual(role: int, text: String) -> void:
	if not multiplayer.is_server():
		return
	var task := ExamTasks.individual_task(role)
	var correct := _answers_match(text, task.get("answer", ""))
	_individual_result.rpc(role, text, correct)


@rpc("authority", "call_local", "reliable")
func _individual_result(role: int, text: String, correct: bool) -> void:
	GameState.submit_individual(role, text, correct)


@rpc("any_peer", "call_remote", "reliable")
func _submit_team_sub(role: int, text: String) -> void:
	if not multiplayer.is_server():
		return
	var task: Dictionary = ExamTasks.team_task()["sub"][role]
	var correct := _answers_match(text, task.get("answer", ""))
	_team_sub_result.rpc(role, text, correct)


@rpc("authority", "call_local", "reliable")
func _team_sub_result(role: int, text: String, correct: bool) -> void:
	GameState.submit_team_sub(role, text, correct)


@rpc("any_peer", "call_remote", "reliable")
func _submit_team_final(text: String) -> void:
	if not multiplayer.is_server():
		return
	var task := ExamTasks.team_task()
	var correct := _answers_match(text, task.get("final_answer", ""))
	_team_final_result.rpc(text, correct)

	var solved := 0
	for role in solving_roles:
		if GameState.exam_individual.get(role, {}).get("correct", false):
			solved += 1
	if correct:
		solved += 1
	var grade := "Неуд."
	if solved >= 4:
		grade = "Отлично"
	elif solved == 3:
		grade = "Хорошо"
	elif solved == 2:
		grade = "Удовл."
	_grade_result.rpc(grade)
	_change_scene.rpc("res://scenes/Ending.tscn")


@rpc("authority", "call_local", "reliable")
func _team_final_result(text: String, correct: bool) -> void:
	GameState.submit_team_final(text, correct)


@rpc("authority", "call_local", "reliable")
func _grade_result(grade: String) -> void:
	GameState.finish_exam(grade)


@rpc("authority", "call_local", "reliable")
func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _answers_match(given: String, expected: String) -> bool:
	return given.strip_edges().to_lower() == String(expected).strip_edges().to_lower()
