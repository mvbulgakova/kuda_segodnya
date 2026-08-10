extends Control

# Показывает подключившихся игроков. Хост запускает игру.

@onready var players_list: VBoxContainer = $Panel/VBox/PlayersList
@onready var start_button: Button = $Panel/VBox/StartButton
@onready var ip_hint: Label = $Panel/VBox/IpHint


func _ready() -> void:
	GameState.players_changed.connect(_refresh)
	start_button.visible = NetworkManager.is_host
	ip_hint.text = _ip_hint()
	_refresh()


func _refresh() -> void:
	for child in players_list.get_children():
		child.queue_free()
	for peer_id in GameState.players.keys():
		var info: Dictionary = GameState.players[peer_id]
		var label := Label.new()
		var role_name: String = GameState.role_name(info.get("role", GameState.Role.UNSET))
		label.text = "#%d  %s  —  %s" % [peer_id, info.get("nickname", "?"), role_name]
		players_list.add_child(label)


func _ip_hint() -> String:
	var ips: PackedStringArray = []
	for addr in IP.get_local_addresses():
		if addr.begins_with("127.") or addr.contains(":"):
			continue
		ips.append(addr)
	if ips.is_empty():
		return "Клиенты подключаются по 127.0.0.1 (локально)"
	return "Клиенты подключаются по: " + ", ".join(ips)


func _on_start_pressed() -> void:
	if not NetworkManager.is_host:
		return
	_change_scene.rpc("res://scenes/CorridorGavrikova.tscn")
	_change_scene("res://scenes/CorridorGavrikova.tscn")


@rpc("authority", "call_remote", "reliable")
func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _on_leave_pressed() -> void:
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
