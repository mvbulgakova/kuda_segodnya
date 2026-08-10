extends "res://scripts/Interactable.gd"

# Точка входа в чат с NPC (тётя Люба, Артём, Валерия — см. GAME_DESIGN.md,
# «NPC»). character_id должен совпадать с ключом в llm_bridge/main.py
# (CHARACTERS). Открывает NpcDialog только у того, кто нажал E.

@export var character_id: String = "senior_artem"
@export var display_name: String = "Артём"

var _dialog: Control = null


func _on_interact(_peer_id: int) -> void:
	if _dialog:
		return
	_dialog = preload("res://scenes/NpcDialog.tscn").instantiate()
	_dialog.character_id = character_id
	_dialog.display_name = display_name
	get_tree().current_scene.add_child(_dialog)
	_dialog.tree_exited.connect(func() -> void: _dialog = null)
