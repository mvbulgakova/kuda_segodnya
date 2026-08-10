extends Node

# Единый источник правды по прогрессу игры.
# Живёт как autoload, доступен из любой сцены как GameState.xxx

enum Role { UNSET, ANALYST, ALGEBRAIST, GEOMETER, STAROSTA }

const ROLE_NAMES := {
	Role.UNSET: "не выбрана",
	Role.ANALYST: "Аналитик",
	Role.ALGEBRAIST: "Алгебраист",
	Role.GEOMETER: "Геометр",
	Role.STAROSTA: "Староста",
}

const ROLE_DESCRIPTIONS := {
	Role.ANALYST: "Пределы, ε-δ, производные. Умеет пересчитать сложную задачу за половину времени.",
	Role.ALGEBRAIST: "Матрицы, СЛАУ, преобразования. Разложит формулу на шаги для команды.",
	Role.GEOMETER: "Векторы, планиметрия. Покажет чертёж-подсказку всем игрокам.",
	Role.STAROSTA: "Не решает задачи. Уболтает NPC-препода отдать конспект без задания. Педагогический баф.",
}

# Прогресс актов. 0 = не начат, 1 = в процессе, 2 = завершён
enum ActState { NOT_STARTED, IN_PROGRESS, DONE }

var current_act: int = 0
var acts: Array = [
	{"name": "Пролог: День знаний", "state": ActState.NOT_STARTED},
	{"name": "Разведка: Учиться, учиться и учиться", "state": ActState.NOT_STARTED},
	{"name": "Тайники: Погружение в профессию", "state": ActState.NOT_STARTED},
	{"name": "Обмен: Гимнастика для мозгов", "state": ActState.NOT_STARTED},
	{"name": "Загадка: Корень учения горек", "state": ActState.NOT_STARTED},
	{"name": "КР: В добрый путь, первокурсник", "state": ActState.NOT_STARTED},
]

# Собранные конспекты (общий командный инвентарь). Ключ — id листка ("matan_1" и т.п.),
# значение — текст темы (subject), чтобы инвентарь мог отрисоваться без похода к тайнику.
var collected_notes: Dictionary = {}

# Педагогические очки — заработаны через мини-игру «объясни школьнику»
var pedagogy_points: int = 0

# Мой персонаж — роль, ник
var my_role: Role = Role.UNSET
var my_nickname: String = ""

# Список игроков в комнате: peer_id -> {nickname, role}
var players: Dictionary = {}

signal act_advanced(new_act: int)
signal note_collected(note_id: String, subject: String, collector_peer_id: int)
signal pedagogy_changed(new_value: int)
signal players_changed()


func reset() -> void:
	current_act = 0
	for a in acts:
		a["state"] = ActState.NOT_STARTED
	collected_notes.clear()
	pedagogy_points = 0
	players.clear()


func advance_act() -> void:
	if current_act < acts.size():
		acts[current_act]["state"] = ActState.DONE
	current_act += 1
	if current_act < acts.size():
		acts[current_act]["state"] = ActState.IN_PROGRESS
	act_advanced.emit(current_act)


func collect_note(note_id: String, subject: String, collector_peer_id: int = 0) -> void:
	if not collected_notes.has(note_id):
		collected_notes[note_id] = subject
		note_collected.emit(note_id, subject, collector_peer_id)


func add_pedagogy(delta: int) -> void:
	pedagogy_points += delta
	pedagogy_changed.emit(pedagogy_points)


func register_player(peer_id: int, nickname: String, role: Role) -> void:
	players[peer_id] = {"nickname": nickname, "role": role}
	players_changed.emit()


func unregister_player(peer_id: int) -> void:
	players.erase(peer_id)
	players_changed.emit()


func role_name(role: Role) -> String:
	return ROLE_NAMES.get(role, "?")
