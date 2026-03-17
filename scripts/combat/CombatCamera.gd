# 战斗镜头控制器 - 可拖动、可缩放、自动适应所有单位
extends Control
class_name CombatCamera

signal camera_moved(position: Vector2)
signal camera_zoomed(zoom_level: float)

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var camera_offset: Vector2 = Vector2.ZERO
var current_zoom: float = 1.0

# 战斗区域范围
var combat_bounds: Rect2 = Rect2(0, 0, 1200, 700)

func _ready():
	# 监听战斗开始/结束
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	
	# 监听战斗单位位置变化
	Signals.combatant_moved.connect(_on_combatant_moved)

func _input(event: InputEvent):
	# 鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.position)
			else:
				end_drag()
	
	# 拖动移动
	if event is InputEventMouseMotion and is_dragging:
		pan_camera(event.relative)

func start_drag(mouse_pos: Vector2) -> void:
	is_dragging = true
	drag_start = mouse_pos + camera_offset

func end_drag() -> void:
	is_dragging = false

func pan_camera(delta: Vector2) -> void:
	camera_offset = drag_start - delta
	camera_offset = clamp_camera_offset()
	camera_moved.emit(camera_offset)

func zoom_camera(delta: float) -> void:
	current_zoom = clampf(current_zoom + delta, min_zoom, max_zoom)
	camera_zoomed.emit(current_zoom)

func clamp_camera_offset() -> Vector2:
	var viewport_size = get_viewport_rect().size * current_zoom
	var max_offset = viewport_size / 2
	return camera_offset.clamp(-max_offset, max_offset)

func _on_combat_started(_event_id: String):
	# 战斗开始时自动调整视角让所有单位可见
	await get_tree().process_frame
	fit_all_combatants()

func _on_combat_ended():
	# 重置镜头
	current_zoom = 1.0
	camera_offset = Vector2.ZERO
	camera_zoomed.emit(current_zoom)

func _on_combatant_moved(_combatant: BaseCombatant):
	# 战斗单位移动后可选择是否自动调整
	pass

## 自动缩放让所有战斗单位可见
func fit_all_combatants() -> void:
	var player = Global.get_player()
	if player == null:
		return
	
	var min_x: float = player.position_x
	var max_x: float = player.position_x
	
	# 获取所有敌人位置
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is BaseCombatant:
			min_x = minf(min_x, enemy.position_x)
			max_x = maxf(max_x, enemy.position_x)
	
	# 计算需要的视野范围
	var combat_range: float = max_x - min_x
	if combat_range <= 0:
		combat_range = 200  # 默认范围
	
	# 根据战斗范围计算缩放
	var viewport_width = get_viewport_rect().size.x
	var target_zoom = viewport_width / (combat_range + 300)  # 加边距
	target_zoom = clampf(target_zoom, min_zoom, max_zoom)
	
	# 平滑过渡到目标缩放
	current_zoom = target_zoom
	
	# 计算中心点
	var center_x = (min_x + max_x) / 2
	camera_offset = Vector2(viewport_width / 2 - center_x * current_zoom, 0)
	
	camera_zoomed.emit(current_zoom)
	camera_moved.emit(camera_offset)

## 应用镜头变换到节点
func apply_to_node(node: Control) -> void:
	node.position += camera_offset
	node.scale = Vector2(current_zoom, current_zoom)
