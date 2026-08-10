extends Control

# Экран старта: ник, выбор роли, host/join.

@onready var nickname_edit: LineEdit = $Panel/VBox/NicknameEdit
@onready var role_option: OptionButton = $Panel/VBox/RoleOption
@onready var ip_edit: LineEdit = $Panel/VBox/JoinRow/IpEdit
@onready var status_label: Label = $Panel/VBox/StatusLabel


func _ready() -> void:
	role_option.clear()
	role_option.add_item("Выбери роль…", GameState.Role.UNSET)
	role_option.add_item("Аналитик", GameState.Role.ANALYST)
	role_option.add_item("Алгебраист", GameState.Role.ALGEBRAIST)
	role_option.add_item("Геометр", GameState.Role.GEOMETER)
	role_option.add_item("Староста", GameState.Role.STAROSTA)
	role_option.selected = 0
	role_option.item_selected.connect(_on_role_selected)
	nickname_edit.text = "Первокурсник"
	status_label.text = ""


func _on_role_selected(index: int) -> void:
	var role_id := role_option.get_item_id(index)
	status_label.text = GameState.ROLE_DESCRIPTIONS.get(role_id, "")


func _validate() -> bool:
	if nickname_edit.text.strip_edges() == "":
		status_label.text = "Ник не может быть пустым."
		return false
	if role_option.get_selected_id() == GameState.Role.UNSET:
		status_label.text = "Выбери роль."
		return false
	GameState.my_nickname = nickname_edit.text.strip_edges()
	GameState.my_role = role_option.get_selected_id() as GameState.Role
	return true


func _on_host_pressed() -> void:
	if not _validate():
		return
	var err := NetworkManager.create_server()
	if err == OK:
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Не удалось поднять сервер: %s" % err


func _on_join_pressed() -> void:
	if not _validate():
		return
	var ip := ip_edit.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var err := NetworkManager.join_server(ip)
	if err == OK:
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Не удалось подключиться: %s" % err


func _on_quit_pressed() -> void:
	get_tree().quit()
