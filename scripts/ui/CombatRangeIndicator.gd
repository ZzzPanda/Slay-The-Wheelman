## 战斗范围指示器 - 在战斗中显示攻击范围可视化
extends Control
class_name CombatRangeIndicator

## 范围线条颜色
var range_color: Color = Color(1.0, 0.4, 0.4, 0.6)  # 红色半透明

## 线条粗细
var line_thickness: float = 2.0

## 战斗区域边距（与 BaseCombatant 一致）
const COMBAT_MARGIN: float = 100.0
const COMBAT_WIDTH: float = 1000.0

func _ready():
	# 默认隐藏
	visible = false
	# 设置层级在最上层
	z_index = 100
	# 连接到战斗信号
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)

func _draw():
	if not visible:
		return
	
	# 从玩家节点获取位置（更可靠）
	var player: Player = Global.get_player()
	if player == null:
		return
	
	# 使用玩家的逻辑坐标
	var player_logic_x: float = player.position_x
	
	# 获取当前悬停卡牌的范围
	var range_min = _current_range_min
	var range_max = _current_range_max
	
	if range_max <= 0:
		return
	
	# 获取视口宽度
	var viewport_width = get_viewport_rect().size.x
	var combat_area_width = viewport_width - COMBAT_MARGIN * 2
	
	# 将逻辑坐标 (0-1000) 转换为屏幕坐标
	var player_screen_x = COMBAT_MARGIN + (player_logic_x / COMBAT_WIDTH) * combat_area_width
	
	# 计算范围区域的屏幕坐标
	var start_screen_x = player_screen_x
	var end_screen_x = player_screen_x + range_max
	
	# 绘制攻击范围线条（在战斗区域底部）
	var battle_bottom = get_viewport_rect().size.y - 100
	var battle_top = battle_bottom - 50
	
	# 绘制范围区域
	var rect = Rect2(start_screen_x, battle_bottom, range_max, 20)
	draw_rect(rect, range_color, true)
	
	# 绘制边线
	draw_line(Vector2(start_screen_x, battle_bottom), Vector2(start_screen_x, battle_top), range_color, line_thickness)
	draw_line(Vector2(end_screen_x, battle_bottom), Vector2(end_screen_x, battle_top), range_color, line_thickness)
	draw_line(Vector2(start_screen_x, battle_bottom), Vector2(end_screen_x, battle_bottom), range_color, line_thickness)
	
	# 绘制文字标签
	var font = ThemeDB.fallback_font
	var label_text = "范围: %d - %d" % [range_min, range_max]
	draw_string(font, Vector2(start_screen_x + 10, battle_bottom - 10), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

var _current_range_min: float = 0.0
var _current_range_max: float = 0.0

func show_range(range_min: float, range_max: float) -> void:
	_current_range_min = range_min
	_current_range_max = range_max
	visible = range_max > 0
	queue_redraw()

func hide_range() -> void:
	visible = false
	_current_range_min = 0.0
	_current_range_max = 0.0

func _on_combat_started(_event_id: String):
	visible = false

func _on_combat_ended():
	visible = false
