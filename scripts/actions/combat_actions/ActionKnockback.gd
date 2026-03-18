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
	for target in _targets:
		if target is BaseCombatant:
			# 计算击退方向：如果目标在击退源右侧，向右推；否则向左推
			var direction: float = 1.0 if target.position_x > knockback_source_x else -1.0
			var new_x = target.position_x + (knockback_force * direction)
			
			# 使用平滑移动
			_move_to_position(target, new_x, duration)
			
			# 发出击退信号
			Signals.combatant_knockback_started.emit(target, knockback_force, direction)
	
	_finish_action()

## 平滑移动到目标位置
func _move_to_position(target: BaseCombatant, target_x: float, duration: float) -> void:
	var start_x = target.position_x
	target.set_position_x(target_x)
	
	# 创建补间动画实现平滑移动（可选）
	var tween = create_tween()
	tween.tween_property(target, "position_x", target_x, duration).set_trans(Tween.TRANS_SINE)

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
