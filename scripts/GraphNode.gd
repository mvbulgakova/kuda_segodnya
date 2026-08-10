extends "res://scripts/Interactable.gd"

# Вершина «сети замков» (акт 3). Каждая роль видит только свой узел —
# чтобы собрать код, команда обязана проговорить находки вслух.
# Чисто локальная проверка: сети/RPC не нужно, это приватное чтение,
# а не общее состояние.

@export var owner_role: GameState.Role = GameState.Role.ANALYST
@export var digit: String = "0"


func _on_interact(_peer_id: int) -> void:
	if GameState.my_role == owner_role:
		Hud.show_hint("Твой узел сети: %s\nСкажи команде вслух." % digit, 6.0)
	else:
		Hud.show_hint("Это не твой узел. Тут нужен: %s." % GameState.role_name(owner_role), 3.0)
