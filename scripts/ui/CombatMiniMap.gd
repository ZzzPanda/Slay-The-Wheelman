# 战斗小地图 - 显示一维坐标轴和所有单位位置
extends Control
class_name CombatMiniMap

signal position_clicked(x: float)  # 点击了小地图某位置

@export var map_height: float = 60.0
@export var map_padding: float = 20.0
@export var tick_interval: float = 100.0  # 刻度间隔

var player_marker: ColorRect
var enemy_markers: Array[ColorRect] = []

@onready var background: ColorRect = $Background
@onready var track: ColorRect = $Track
@onready var player_icon: ColorRect = $PlayerIcon
@onready var enemy_container: Control = $EnemyContainer
@onready var axis_container: Control = $AxisContainer

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	Signals.combatant_moved.connect(_on_combatant_moved)
	
	# 点击小地图移动玩家位置
	gui_input.connect(_on_gui_input)
	
	_draw_axis()
	_update_map_layout()

func _draw_axis() -> void:
	# 画坐标轴刻度
	var map_width = 800.0 - map_padding * 2
	var num_ticks = int(1000.0 / tick_interval)
	
	for i in range(num_ticks + 1):
		var tick_x = (i * tick_interval / 1000.0) * map_width + map_padding
		
		# 刻度线
		var tick = ColorRect.new()
		tick.color = Color(0.5, 0.5, 0.5, 0.8)
		tick.custom_minimum_size = Vector2(1, 8)
		tick.position = Vector2(tick_x, map_height - 12)
		axis_container.add_child(tick)
		
		# 刻度数值 (每200显示)
		if i % 2 == 0:
			var label = Label.new()
			label.text = str(i * int(tick_interval))
			label.add_theme_font_size_override("font_size", 10)
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			label.position = Vector2(tick_x - 10, map_height - 26)
			axis_container.add_child(label)

func _update_map_layout() -> void:
	var viewport_size = get_viewport_rect().size
	var map_width = viewport_size.x - map_padding * 2
	
	# 底部小地图区域
	position = Vector2(map_padding, viewport_size.y - map_height - map_padding)
	custom_minimum_size = Vector2(map_width, map_height)
	
	# 更新背景
	background.size = Vector2(map_width, map_height)
	
	# 更新轨道
	track.size = Vector2(map_width - 20, 4)
	track.position = Vector2(10, map_height / 2 - 2)
	
	# 更新玩家图标
	if player_icon:
		player_icon.custom_minimum_size = Vector2(16, 16)
		player_icon.position = Vector2(0, map_height / 2 - 8)
	
	# 重绘坐标轴
	for child in axis_container.get_children():
		child.queue_free()
	_draw_axis()

func _process(_delta: float):
	# 窗口大小变化时更新
	var viewport_size = get_viewport_rect().size
	var map_width = viewport_size.x - map_padding * 2
	if abs(custom_minimum_size.x - map_width) > 10:
		_update_map_layout()

func _on_combat_started(_event_id: String):
	visible = true
	update_positions()

func _on_combat_ended():
	visible = false

func _on_combatant_moved(_combatant: BaseCombatant):
	update_positions()

func update_positions() -> void:
	var map_width = custom_minimum_size.x - 30  # 边距
	
	# 更新玩家位置
	var player = Global.get_player()
	if player:
		var player_screen_x = (player.position_x / 1000.0) * map_width + 10
		player_icon.position.x = player_screen_x - 8
	
	# 更新敌人位置
	# 清除旧的
	for marker in enemy_markers:
		marker.queue_free()
	enemy_markers.clear()
	
	# 添加新的
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is BaseCombatant:
			var marker = ColorRect.new()
			marker.color = Color.RED
			marker.custom_minimum_size = Vector2(12, 12)
			var enemy_screen_x = (enemy.position_x / 1000.0) * map_width + 10
			marker.position = Vector2(enemy_screen_x - 6, map_height / 2 - 6)
			enemy_container.add_child(marker)
			enemy_markers.append(marker)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = get_local_mouse_position()
		var map_width = custom_minimum_size.x - 30
		var clicked_x = (local_pos.x - 10) / map_width * 1000.0
		clicked_x = clamp(clicked_x, 0, 1000)
		position_clicked.emit(clicked_x)

## 计算两个位置之间的距离
static func get_distance(x1: float, x2: float) -> float:
	return abs(x1 - x2)

## 检查目标是否在指定范围内
static func is_in_range(target_x: float, source_x: float, max_distance: float) -> bool:
	return get_distance(target_x, source_x) <= max_distance

## 检查目标是否在指定范围内 (包含最小距离)
static func is_in_range_with_min(target_x: float, source_x: float, min_distance: float, max_distance: float) -> bool:
	var dist = get_distance(target_x, source_x)
	return dist >= min_distance and dist <= max_distance
