extends Node

# Тонкая обёртка над ENetMultiplayerPeer.
# Host: create_server(port) — стартует сервер и локального игрока.
# Client: join_server(ip, port) — подключается.

const DEFAULT_PORT := 4242
const MAX_PLAYERS := 4

var is_host: bool = false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func create_server(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Не удалось поднять сервер на порту %d: %s" % [port, err])
		return err
	multiplayer.multiplayer_peer = peer
	is_host = true
	print("[net] Сервер поднят на порту %d" % port)
	# Регистрируем себя (host = peer_id 1)
	GameState.register_player(1, GameState.my_nickname, GameState.my_role)
	return OK


func join_server(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_error("Не удалось подключиться к %s:%d — %s" % [ip, port, err])
		return err
	multiplayer.multiplayer_peer = peer
	is_host = false
	print("[net] Подключаюсь к %s:%d" % [ip, port])
	return OK


func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false
	GameState.reset()


func _on_peer_connected(peer_id: int) -> void:
	print("[net] Игрок подключился: %d" % peer_id)
	# Просим нового игрока представиться (роль, ник)
	if is_host:
		_request_player_info.rpc_id(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[net] Игрок отключился: %d" % peer_id)
	GameState.unregister_player(peer_id)


func _on_connected_ok() -> void:
	print("[net] Успешно подключился к серверу.")


func _on_connection_failed() -> void:
	push_error("[net] Подключение не удалось.")
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	push_warning("[net] Сервер отключился.")
	multiplayer.multiplayer_peer = null
	GameState.reset()


# Хост просит клиента представиться
@rpc("authority", "call_remote", "reliable")
func _request_player_info() -> void:
	# У клиента: отправить свои данные хосту
	_receive_player_info.rpc_id(1, GameState.my_nickname, GameState.my_role)


# Хост получает данные клиента и раздаёт всем
@rpc("any_peer", "call_local", "reliable")
func _receive_player_info(nickname: String, role: int) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server():
		return
	GameState.register_player(sender_id, nickname, role as GameState.Role)
	# Раздаём обновлённый список всем клиентам
	_broadcast_players.rpc(GameState.players)


@rpc("authority", "call_remote", "reliable")
func _broadcast_players(players: Dictionary) -> void:
	GameState.players = players
	GameState.players_changed.emit()
