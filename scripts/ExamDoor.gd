extends "res://scripts/Interactable.gd"

# Дверь ауд. 401 — переход к финальной КР (акт 5).
# MVP: без предусловий (акты 3-4 ещё не реализованы), любой игрок может
# открыть дверь для всей команды — чтобы уже сейчас можно было пройти
# полный круг Lobby → Коридор → КР → Концовка.

func _on_interact(peer_id: int) -> void:
	_request_start_exam.rpc_id(1, peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_start_exam(_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_change_scene.rpc("res://scenes/FinalExam.tscn")


@rpc("authority", "call_local", "reliable")
func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
