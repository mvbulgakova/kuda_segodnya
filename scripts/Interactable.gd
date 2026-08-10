extends StaticBody3D
class_name Interactable

# Базовый интерактивный объект: стенд, тайник, дверь.
# У наследников переопределяется interact() и, при желании, hint_text.

@export var hint: String = "Нажми E"
@export var one_shot: bool = false

var used: bool = false


func interact(_peer_id: int) -> void:
	if one_shot and used:
		return
	used = true
	_on_interact(_peer_id)


func _on_interact(_peer_id: int) -> void:
	# Наследники переопределяют
	print("[interact] ", name)
