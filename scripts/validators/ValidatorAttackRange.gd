## 验证器：检查目标是否在攻击范围内
## 用于位置战斗系统，判断卡牌或敌人是否可以攻击到目标
extends BaseValidator

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	# 获取参数
	var range_min: float = values.get("range_min", 0.0)
	var range_max: float = values.get("range_max", 1000.0)
	var use_card_weapon_range: bool = values.get("use_card_weapon_range", false)
	var attacker_position_override: float = values.get("attacker_position", -1.0)
	
	# 获取攻击者位置
	var attacker_x: float
	if attacker_position_override >= 0:
		attacker_x = attacker_position_override
	elif _card_data != null and _card_data.has_weapon():
		# 如果是卡牌，使用玩家位置
		attacker_x = Global.player_data.player_position_x
	else:
		# 默认攻击者位置
		attacker_x = 500.0  # 屏幕中间
	
	# 尝试获取目标位置
	var target_x: float = _get_target_position(values)
	
	# 如果无法获取目标位置，返回 true（不阻止）
	if target_x < 0:
		return true
	
	# 计算距离
	var distance = abs(target_x - attacker_x)
	
	# 检查是否在范围内
	var in_range = distance >= range_min and distance <= range_max
	
	# 如果使用卡牌武器范围，覆盖默认值
	if use_card_weapon_range and _card_data != null and _card_data.has_weapon():
		var weapon_range = _card_data.get_weapon_range()
		range_min = weapon_range["min"]
		range_max = weapon_range["max"]
		in_range = distance >= range_min and distance <= range_max
	
	return in_range

func _get_target_position(values: Dictionary) -> float:
	# 优先使用明确指定的目标位置
	if values.has("target_position"):
		return values["target_position"]
	
	# 尝试从 action 获取目标
	# 这里可以扩展以支持从不同来源获取目标位置
	
	return -1.0  # 无法获取，返回无效值
