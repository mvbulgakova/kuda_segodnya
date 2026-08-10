extends "res://scripts/Interactable.gd"

# Тайник с листком конспекта.
# Сбор идёт через хост (authority): клиент просит взять, хост проверяет и
# рассылает результат всем — так тайник исчезает и запись в инвентаре
# появляется одновременно у всей команды, а не только у того, кто нажал E.

@export var note_id: String = "matan_1"
@export var subject: String = "Математический анализ. Тема: монотонность функции."


func _on_interact(peer_id: int) -> void:
	_request_collect.rpc_id(1, peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_collect(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if GameState.collected_notes.has(note_id):
		return
	_collected.rpc(peer_id, note_id, subject)


@rpc("authority", "call_local", "reliable")
func _collected(collector_peer_id: int, id: String, note_subject: String) -> void:
	GameState.collect_note(id, note_subject, collector_peer_id)
	print("[stash] %s взял листок '%s' (%s)" % [collector_peer_id, id, note_subject])
	hide()
