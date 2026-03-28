# 移动动作 - 移动战斗单位到指定位置
extends BaseAction
class_name ActionMovePosition

## 移动参数
## target_x: 目标位置 (0-1000)
## move_distance: 移动距离 (与当前位置的差值，优先级低于 target_x)
## is_relative: 是否相对移动
## duration: 移动动画持续时间（秒），默认 0.3 秒

func _init() -> void:
	action_script = self

func get_action_name() -> String:
	return "Move Position"

func _execute_action(_targets: Array[BaseCombatant], _player: Player) -> void:
	# 获取移动参数
	var target_x = get_metadata_value("target_x", -1.0)
	var move_distance = get_metadata_value("move_distance", 0.0)
	var is_relative = get_metadata_value("is_relative", false)
	var duration = get_metadata_value("duration", 0.3)
	
	# 应用移动
	var has_targets = false
	for target in _targets:
		if target is BaseCombatant:
			has_targets = true
			var new_x: float
			if target_x >= 0:
				# 绝对移动
				new_x = target_x
			else:
				# 相对移动
				new_x = target.position_x + move_distance
			
			# 使用 PositionSystem 平滑移动
			PositionSystem.move_combatant(target, new_x, duration)
			
			# 发出移动信号
			Signals.combatant_moved.emit(target)
	
	# 动画完成后 finish action
	if has_targets:
		get_tree().create_timer(duration).timeout.connect(_finish_action)
	else:
		_finish_action()

## 静态方法：创建移动动作
static func create_move_action(
	target_x: float,
	targets: Array[BaseCombatant] = [],
	duration: float = 0.3
) -> ActionMovePosition:
	var action = ActionMovePosition.new()
	action.set_metadata_value("target_x", target_x)
	action.set_metadata_value("duration", duration)
	# 设置目标
	action.set_targets(targets)
	return action

static func create_relative_move_action(
	move_distance: float,
	targets: Array[BaseCombatant] = [],
	duration: float = 0.3
) -> ActionMovePosition:
	var action = ActionMovePosition.new()
	action.set_metadata_value("move_distance", move_distance)
	action.set_metadata_value("is_relative", true)
	action.set_metadata_value("duration", duration)
	action.set_targets(targets)
	return action