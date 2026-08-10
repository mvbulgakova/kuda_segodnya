extends CanvasLayer

# Глобальный HUD: тосты о находках + панель командного инвентаря (Tab).
# Автозагрузка — живёт поверх любой сцены, поэтому подключается к
# GameState.note_collected один раз и работает для всей партии.

@onready var toast_container: VBoxContainer = $ToastContainer
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_list: VBoxContainer = $InventoryPanel/VBox/Scroll/List
@onready var count_label: Label = $InventoryPanel/VBox/Header/CountLabel
@onready var inventory_hint: Label = $InventoryHint


func _ready() -> void:
	inventory_panel.visible = false
	GameState.note_collected.connect(_on_note_collected)
	_refresh_inventory()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible:
			_refresh_inventory()


func _on_note_collected(_note_id: String, subject: String, collector_peer_id: int) -> void:
	_refresh_inventory()
	var is_me := collector_peer_id == multiplayer.get_unique_id()
	var collector_name: String = GameState.players.get(collector_peer_id, {}).get("nickname", "?")
	var text: String
	if is_me:
		text = "Ты нашёл(а) конспект:\n%s" % subject
	else:
		text = "%s нашёл(а) конспект:\n%s" % [collector_name, subject]
	_spawn_toast(text)


func _spawn_toast(text: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	toast_container.add_child(panel)
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(panel.queue_free)


func _refresh_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	var total := GameState.collected_notes.size()
	count_label.text = str(total)
	inventory_hint.text = "Tab — конспекты (%d)" % total
	if total == 0:
		var empty := Label.new()
		empty.text = "Пока пусто. Ищи тайники в аудиториях."
		inventory_list.add_child(empty)
		return
	for note_id in GameState.collected_notes:
		var l := Label.new()
		l.text = "• %s" % GameState.collected_notes[note_id]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inventory_list.add_child(l)
