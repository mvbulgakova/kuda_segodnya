extends Control

# Финал акта 5. Текст зависит от оценки команды (GameState.exam_grade),
# плюс карточка с реальным фактом про МПГУ (см. GAME_DESIGN.md, «Финалы»).
# Тексты фактов — черновые, финальная версия согласуется с деканатом.

const GRADE_TEXT := {
	"Отлично": "Лектор запомнил вашу группу. Впереди — крутые первые пары в семестре.",
	"Хорошо": "Сдали, но семинарист косится. Отмечаем в столовой ИМИ.",
	"Удовл.": "Придётся переписывать. Начинается работа над ошибками.",
	"Неуд.": "Декан уже в курсе. Пересдача.",
}

const FACTS := [
	"ИМИ ведёт историю с 1872 года — институт математики и информатики один из старейших факультетов старейшего педвуза страны.",
	"МПГУ вырос из Московских высших женских курсов, основанных в 1872 году.",
	"Исторический корпус МПГУ на Малой Пироговской, 1 — памятник архитектуры, где начиналась история вуза.",
]

@onready var grade_label: Label = $Panel/VBox/GradeLabel
@onready var text_label: Label = $Panel/VBox/TextLabel
@onready var fact_label: Label = $Panel/VBox/FactLabel


func _ready() -> void:
	var grade: String = GameState.exam_grade if GameState.exam_grade != "" else "Неуд."
	grade_label.text = "Оценка команды: %s" % grade
	text_label.text = GRADE_TEXT.get(grade, "")
	fact_label.text = "Факт про МПГУ: %s" % FACTS[randi() % FACTS.size()]


func _on_menu_button_pressed() -> void:
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
