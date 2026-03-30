# 后坐力动作 - 攻击者被向后推
extends BaseAction
class_name ActionRecoil

## 后坐力参数
## recoil_force: 后坐力力度（像素）
## attack_direction: 攻击方向（正值 = 向右，负值 = 向左，0 = 默认向右）
## duration: 后坐力动画持续时间（秒）

func _init() -> void:
	action_script = self

func get_action_name() -> String:
	return "Recoil"

func _execute_action(_targets: Array[BaseCombatant], _player: Player) -> void:
	# 获取后坐力参数
	var recoil_force = get_metadata_value("recoil_force", 20.0)
	var attack_direction = get_metadata_value("attack_direction", 0.0)
	var duration = get_metadata_value("duration", 0.2)
	
	# 计算后坐力方向：如果攻击方向为 0，使用默认值 1.0（右）
	var recoil_direction: float
	if attack_direction == 0.0:
		recoil_direction = -1.0  # 默认向左后坐力（玩家向右攻击）
	else:
		recoil_direction = -sign(attack_direction)  # 与攻击方向相反
	
	# 应用后坐力到玩家
	if _player != null:
		var current_x = _player.position_x
		var new_x = current_x + (recoil_force * recoil_direction)
		
		# 限制在战斗区域内
		new_x = clamp(new_x, 50.0, 950.0)
		
		# 使用平滑移动动画
		_move_to_position(_player, new_x, duration)
		
		# 发出后坐力信号
		Signals.player_recoil_started.emit(_player, recoil_force, recoil_direction)

## 平滑移动到目标位置
func _move_to_position(target: BaseCombatant, target_x: float, duration: float) -> void:
	# 创建补间动画实现平滑移动
	var tween = create_tween()
	tween.tween_property(target, "position_x", target_x, duration).set_trans(Tween.TRANS_SINE)
	
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
