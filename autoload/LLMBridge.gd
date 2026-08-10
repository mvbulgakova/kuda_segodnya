extends Node

# HTTP-клиент для нашего Python-сервера, который общается с Anthropic API.
# Мы НЕ ходим в claude.ai напрямую из клиента: ключ живёт на сервере.
# Endpoint настраивается через переменную окружения или в UI (пока хардкод).

const DEFAULT_ENDPOINT := "http://localhost:8000"
var endpoint: String = DEFAULT_ENDPOINT

signal explanation_evaluated(understood: bool, comment: String)
signal npc_reply_received(character: String, text: String)


func _ready() -> void:
	var env_url := OS.get_environment("LLM_BRIDGE_URL")
	if env_url != "":
		endpoint = env_url


# Игрок объясняет тему школьнику. Отправляем в /explain
func evaluate_explanation(topic: String, explanation: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_explain_response.bind(http))
	var body := JSON.stringify({"topic": topic, "explanation": explanation})
	var headers := ["Content-Type: application/json"]
	var url := endpoint + "/explain"
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("LLMBridge: не удалось отправить запрос: %s" % err)
		http.queue_free()


# Разговор с NPC-старшекурсником. Отправляем в /npc
func ask_npc(character: String, question: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_npc_response.bind(http, character))
	var body := JSON.stringify({"character": character, "question": question})
	var headers := ["Content-Type: application/json"]
	var url := endpoint + "/npc"
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("LLMBridge: не удалось отправить запрос: %s" % err)
		http.queue_free()


func _on_explain_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if code != 200:
		push_error("LLMBridge /explain вернул %d" % code)
		explanation_evaluated.emit(false, "Не удалось связаться со школьником. Попробуй позже.")
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		explanation_evaluated.emit(false, "Странный ответ от сервера.")
		return
	explanation_evaluated.emit(bool(data.get("understood", false)), String(data.get("comment", "")))


func _on_npc_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, character: String) -> void:
	http.queue_free()
	if code != 200:
		push_error("LLMBridge /npc вернул %d" % code)
		npc_reply_received.emit(character, "…")
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		npc_reply_received.emit(character, "…")
		return
	npc_reply_received.emit(character, String(data.get("text", "")))
