extends "res://scripts/Interactable.gd"

# Тайник с листком конспекта. При взятии — событие в GameState.

@export var note_id: String = "matan_1"
@export var subject: String = "Математический анализ. Тема: монотонность функции."


func _on_interact(peer_id: int) -> void:
	if GameState.collected_notes.get(note_id, false):
		return
	GameState.collect_note(note_id)
	print("[stash] %s взял листок '%s' (%s)" % [peer_id, note_id, subject])
	# TODO: показать UI-уведомление на экране игрока-собирателя
	# TODO: скрыть модель тайника
	hide()
