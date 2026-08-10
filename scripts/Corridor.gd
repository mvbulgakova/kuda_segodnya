extends Node3D

# Корневая сцена корпуса Гаврикова.
# Спавнит игроков (по peer_id из GameState.players) в стартовых точках.
# Держит интерактивные объекты (стенд, тайники), NPC.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

@onready var spawn_points: Node3D = $SpawnPoints


func _ready() -> void:
	if multiplayer.is_server():
		_spawn_all_players()
	else:
		# Клиент просто ждёт, пока сервер заспавнит через RPC (см. _spawn_player_rpc)
		pass


func _spawn_all_players() -> void:
	var spawns := spawn_points.get_children()
	var i := 0
	for peer_id in GameState.players.keys():
		var info: Dictionary = GameState.players[peer_id]
		var spawn_pos: Vector3 = spawns[i % spawns.size()].global_position if spawns.size() > 0 else Vector3.ZERO
		_spawn_player.rpc(peer_id, info.get("nickname", "?"), info.get("role", GameState.Role.UNSET), spawn_pos)
		_spawn_player(peer_id, info.get("nickname", "?"), info.get("role", GameState.Role.UNSET), spawn_pos)
		i += 1


@rpc("authority", "call_remote", "reliable")
func _spawn_player(peer_id: int, nickname: String, role: int, spawn_pos: Vector3) -> void:
	# Уже был?
	if has_node("Player_%d" % peer_id):
		return
	var p: CharacterBody3D = PLAYER_SCENE.instantiate()
	p.name = "Player_%d" % peer_id
	p.peer_id = peer_id
	p.role = role as GameState.Role
	p.nickname = nickname
	add_child(p)
	p.global_position = spawn_pos
