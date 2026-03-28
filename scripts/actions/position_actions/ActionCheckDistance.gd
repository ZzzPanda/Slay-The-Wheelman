# 距离检查动作 - 检查目标是否在指定范围内
extends BaseAction
class_name ActionCheckDistance

## 距离检查参数
## source_x: 源位置 (0-1000)
## target_x: 目标位置 (0-1000)  
## max_distance: 最大距离
## min_distance: 最小距离 (可选，默认为0)
## result_key: 存储结果的键名

func _init() -> void:
	action_script = self

func get_action_name() -> String:
	return "Check Distance"

func _execute_action(_targets: Array[BaseCombatant], _player: Player) -> void:
	# 获取参数
	var source_x = get_metadata_value("source_x", 0.0)
	var target_x = get_metadata_value("target_x", 0.0)
	var max_distance = get_metadata_value("max_distance", 999.0)
	var min_distance = get_metadata_value("min_distance", 0.0)
	var result_key = get_metadata_value("result_key", "is_in_range")
	
	# 使用 PositionSystem 计算距离
	var source_combatant = _get_combatant_at_x(source_x)
	var target_combatant = _get_combatant_at_x(target_x)
	
	var distance: float
	var is_in_range: bool
	
	if source_combatant != null and target_combatant != null:
		# 如果都是作战单位，使用 PositionSystem 计算
		distance = PositionSystem.get_combatant_distance(source_combatant, target_combatant)
	else:
		# 否则使用简单的绝对差值
		distance = abs(target_x - source_x)
	
	is_in_range = distance >= min_distance and distance <= max_distance
	
	# 存储结果到元数据，供后续拦截器使用
	set_metadata_value(result_key, is_in_range)
	set_metadata_value("distance", distance)
	
	_finish_action()

## 根据 x 坐标找到对应的作战单位
func _get_combatant_at_x(x: float) -> BaseCombatant:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player_nodes = get_tree().get_nodes_in_group("player")
	
	for enemy in enemies:
		if enemy is BaseCombatant and abs(enemy.position_x - x) < 50.0:
			return enemy
	
	if player_nodes.size() > 0 and player_nodes[0] is BaseCombatant:
		if abs(player_nodes[0].position_x - x) < 50.0:
			return player_nodes[0]
	
	return null

func get_targetable_combatants(combatants: Array[BaseCombatant], _player: Player) -> Array[BaseCombatant]:
	# 获取范围参数
	var source_x = get_metadata_value("source_x", 0.0)
	var max_distance = get_metadata_value("max_distance", 999.0)
	var min_distance = get_metadata_value("min_distance", 0.0)
	
	# 获取源作战单位
	var source_combatant = _get_combatant_at_x(source_x)
	
	# 过滤出范围内的单位
	var valid_targets: Array[BaseCombatant] = []
	for combatant in combatants:
		var dist: float
		if source_combatant != null:
			# 使用 PositionSystem 计算
			dist = PositionSystem.get_combatant_distance(source_combatant, combatant)
		else:
			# 使用简单差值
			dist = abs(combatant.position_x - source_x)
		
		if dist >= min_distance and dist <= max_distance:
			valid_targets.append(combatant)
	
	return valid_targets

## 静态方法：创建距离检查动作
static func create_check_distance_action(
	source_x: float,
	target_x: float,
	max_distance: float,
	min_distance: float = 0.0,
	result_key: String = "is_in_range"
) -> ActionCheckDistance:
	var action = ActionCheckDistance.new()
	action.set_metadata_value("source_x", source_x)
	action.set_metadata_value("target_x", target_x)
	action.set_metadata_value("max_distance", max_distance)
	action.set_metadata_value("min_distance", min_distance)
	action.set_metadata_value("result_key", result_key)
	return action
