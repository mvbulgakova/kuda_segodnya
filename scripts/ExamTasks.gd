extends RefCounted
class_name ExamTasks

# Условия задач финальной КР (акт 5).
# MVP: фиксированный набор, без генератора через LLM (см. GAME_DESIGN.md,
# «Механики Claude» п.3 — реиграбельность добавим отдельно).
# Личная задача — только у решающих специализаций (Аналитик/Алгебраист/
# Геометр). У Старосты личной задачи нет: он собирает шаги командной
# задачи и сдаёт итог — это и есть его роль в КР.


static func individual_task(role: int) -> Dictionary:
	match role:
		GameState.Role.ANALYST:
			return {
				"title": "Задача 1. Матан",
				"prompt": "Найди предел: lim(x→0) sin(3x)/x. Впиши число.",
				"answer": "3",
			}
		GameState.Role.ALGEBRAIST:
			return {
				"title": "Задача 2. Алгебра",
				"prompt": "Вычисли определитель матрицы [[2,1],[3,4]]. Впиши число.",
				"answer": "5",
			}
		GameState.Role.GEOMETER:
			return {
				"title": "Задача 3. Геометрия",
				"prompt": "Найди длину вектора a = (3, 4). Впиши число.",
				"answer": "5",
			}
		_:
			return {}


# Командная задача: у каждой решающей роли свой шаг доказательства,
# староста сверяет и сдаёт финальное значение.
static func team_task() -> Dictionary:
	return {
		"title": "Задача 4. Командное доказательство",
		"narrative": "Докажите: lim(x→2) (x² + 2x) = lim(x→2) x² + lim(x→2) 2x",
		"sub": {
			GameState.Role.ANALYST: {
				"prompt": "Твой шаг: найди lim(x→2) x². Впиши число.",
				"answer": "4",
			},
			GameState.Role.ALGEBRAIST: {
				"prompt": "Твой шаг: найди lim(x→2) 2x. Впиши число.",
				"answer": "4",
			},
			GameState.Role.GEOMETER: {
				"prompt": "Твой шаг: построй сумму двух отрезков длиной 4 и 4. Чему равна их сумма?",
				"answer": "8",
			},
		},
		"final_answer": "8",
	}
