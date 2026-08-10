extends "res://scripts/Interactable.gd"

# Табличка/доска с половиной подсказки (акт 4). Чисто локальное чтение —
# не общее состояние, RPC не нужен. requires_flag опционально запирает
# чтение, пока не решён более ранний этап (например, доска в 305 видна
# только после того, как акт 3 открыл дверь).

@export var clue_text: String = "..."
@export var requires_flag: String = ""
@export var locked_hint: String = "Тут заперто."


func _on_interact(_peer_id: int) -> void:
	if requires_flag != "" and not GameState.has_flag(requires_flag):
		Hud.show_hint(locked_hint, 4.0)
		return
	Hud.show_hint(clue_text, 6.0)
