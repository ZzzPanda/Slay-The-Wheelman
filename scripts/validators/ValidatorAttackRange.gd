# 攻击范围验证器 - 验证目标是否在武器攻击范围内
extends BaseValidator
class_name ValidatorAttackRange

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	# 获取参数
	var min_range = _get_validator_value("min_range", values, action, 0.0)
	var max_range = _get_validator_value("max_range", values, action, 999.0)
	var use_card_weapon_range = _get_validator_value("use_card_weapon_range", values, action, false)
	
	# 获取攻击者位置（通常是玩家）
	var attacker: BaseCombatant = null
	
	# 尝试从 action 获取攻击者
	if action.has_method("get_attacker"):
		attacker = action.get_attacker()
	
	# 如果没有攻击者，尝试获取玩家
	if attacker == null:
		var player_nodes = get_tree().get_nodes_in_group("player")
		if len(player_nodes) > 0:
			attacker = player_nodes[0]
	
	if attacker == null:
		return true  # 无法确定攻击者时默认通过
	
	# 获取目标
	var targets: Array[BaseCombatant] = action.targets
	if len(targets) != 1:
		return false
	
	var target: BaseCombatant = targets[0]
	
	# 确定攻击范围
	var actual_min_range = min_range
	var actual_max_range = max_range
	
	# 如果使用卡牌关联的武器范围
	if use_card_weapon_range and _card_data != null:
		if _card_data.has_method("get_weapon_range"):
			var weapon_range = _card_data.get_weapon_range()
			if not weapon_range.is_empty():
				actual_min_range = weapon_range.get("min", min_range)
				actual_max_range = weapon_range.get("max", max_range)
	
	# 计算距离（使用 PositionSystem）
	var distance = PositionSystem.get_combatant_distance(attacker, target)
	
	# 验证距离是否在范围内
	return distance >= actual_min_range and distance <= actual_max_range
