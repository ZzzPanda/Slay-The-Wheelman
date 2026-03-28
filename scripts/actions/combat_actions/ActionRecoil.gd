# 后坐力动作 - 攻击者被向后推
extends BaseAction
class_name ActionRecoil

## 后坐力参数
## recoil_force: 后坐力力度（像素）
## attack_direction: 攻击方向（1.0 = 向右，-1.0 = 向左）
## duration: 后坐力动画持续时间（秒）

func _init() -> void:
	action_script = self

func get_action_name() -> String:
	return "Recoil"

func _execute_action(_targets: Array[BaseCombatant], _player: Player) -> void:
	# 获取后坐力参数
	var recoil_force = get_metadata_value("recoil_force", 20.0)
	var attack_direction = get_metadata_value("attack_direction", 1.0)
	var duration = get_metadata_value("duration", 0.2)
	
	# 后坐力方向与攻击方向相反
	var recoil_direction = -sign(attack_direction)
	
	# 应用后坐力到玩家
	if _player != null:
		# 使用 PositionSystem 计算后坐力目标位置
		var new_x = PositionSystem.calculate_recoil_target(_player, attack_direction, recoil_force)
		
		# 使用 PositionSystem 平滑移动
		PositionSystem.move_combatant(_player, new_x, duration)
		
		# 发出后坐力信号
		Signals.player_recoil_started.emit(_player, recoil_force, recoil_direction)
		
		# 动画完成后 finish action（tween 会在 duration 后完成）
		get_tree().create_timer(duration).timeout.connect(_finish_action)
	else:
		# 如果没有玩家，直接 finish
		_finish_action()

## 静态方法：创建后坐力动作
static func create_recoil_action(
	recoil_force: float,
	attack_direction: float = 1.0,
	player: Player = null,
	duration: float = 0.2
) -> ActionRecoil:
	var action = ActionRecoil.new()
	action.set_metadata_value("recoil_force", recoil_force)
	action.set_metadata_value("attack_direction", attack_direction)
	action.set_metadata_value("duration", duration)
	if player != null:
		action.set_targets([player])
	return action