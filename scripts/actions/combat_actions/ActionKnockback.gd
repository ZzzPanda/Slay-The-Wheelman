# 击退动作 - 将目标推离击退源
extends BaseAction
class_name ActionKnockback

## 击退参数
## knockback_force: 击退力度（像素）
## knockback_source_x: 击退源的位置 X
## duration: 击退动画持续时间（秒）

func _init() -> void:
	action_script = self

func get_action_name() -> String:
	return "Knockback"

func _execute_action(_targets: Array[BaseCombatant], _player: Player) -> void:
	# 获取击退参数
	var knockback_force = get_metadata_value("knockback_force", 30.0)
	var knockback_source_x = get_metadata_value("knockback_source_x", 500.0)
	var duration = get_metadata_value("duration", 0.2)
	
	# 应用击退
	var has_targets = false
	for target in _targets:
		if target is BaseCombatant:
			has_targets = true
			# 使用 PositionSystem 计算击退目标位置（自动处理边界）
			var new_x = PositionSystem.calculate_knockback_target(target, knockback_source_x, knockback_force)
			
			# 使用 PositionSystem 平滑移动
			PositionSystem.move_combatant(target, new_x, duration)
			
			# 发出击退信号
			var direction = sign(new_x - target.position_x)
			Signals.combatant_knockback_started.emit(target, knockback_force, direction)
	
	# 动画完成后 finish action
	if has_targets:
		get_tree().create_timer(duration).timeout.connect(_finish_action)
	else:
		_finish_action()

## 静态方法：创建击退动作
static func create_knockback_action(
	knockback_force: float,
	knockback_source_x: float,
	targets: Array[BaseCombatant] = [],
	duration: float = 0.2
) -> ActionKnockback:
	var action = ActionKnockback.new()
	action.set_metadata_value("knockback_force", knockback_force)
	action.set_metadata_value("knockback_source_x", knockback_source_x)
	action.set_metadata_value("duration", duration)
	action.set_targets(targets)
	return action