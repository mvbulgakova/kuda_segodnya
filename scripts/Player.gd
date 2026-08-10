extends CharacterBody3D

# Первое лицо, WASD + мышь.
# Мультиплеер: multiplayer authority = peer_id владельца.
# Позиция синхронится через unreliable RPC от владельца всем остальным.

const SPEED := 5.0
const GRAVITY := 9.8
const MOUSE_SENS := 0.002

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var name_label: Label3D = $NameLabel

var peer_id: int = 1
var role: GameState.Role = GameState.Role.UNSET
var nickname: String = ""


func _ready() -> void:
	set_multiplayer_authority(peer_id)
	name_label.text = "%s (%s)" % [nickname, GameState.role_name(role)]
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotate_x(-event.relative.y * MOUSE_SENS)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2.0, PI / 2.0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()
	# Раз в физический тик пушим позицию остальным
	_sync_transform.rpc(global_position, rotation.y, camera.rotation.x)


@rpc("authority", "call_remote", "unreliable")
func _sync_transform(pos: Vector3, yaw: float, pitch: float) -> void:
	global_position = pos
	rotation.y = yaw
	camera.rotation.x = pitch


func _try_interact() -> void:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return
	var hit := interaction_ray.get_collider()
	if hit and hit.has_method("interact"):
		hit.interact(peer_id)
