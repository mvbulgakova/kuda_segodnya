extends "res://scripts/Interactable.gd"

# Дверь ауд. 401 — переход к финальной КР (акт 5).
# Заперта, пока не собран итоговый код акта 4 (флаг act4_unlocked).

func _on_interact(peer_id: int) -> void:
	if not GameState.has_flag("act4_unlocked"):
		Hud.show_hint("Дверь заперта. Собери код из ауд. 305 и стенда в вестибюле (акт 4).", 4.0)
		return
	_request_start_exam.rpc_id(1, peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_start_exam(_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_change_scene.rpc("res://scenes/FinalExam.tscn")


@rpc("authority", "call_local", "reliable")
func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
