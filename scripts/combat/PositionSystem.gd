# 位置战斗系统 - 核心距离计算和移动
extends Node
class_name PositionSystem

## 战斗宽度常量（与 BaseCombatant 保持一致）
const COMBAT_WIDTH: float = 1000.0
const COMBAT_MARGIN: float = 50.0

## 计算两个作战单位之间的水平距离（像素）
static func get_combatant_distance(combatant_a: BaseCombatant, combatant_b: BaseCombatant) -> float:
	return abs(combatant_a.position_x - combatant_b.position_x)

## 检查目标是否在攻击范围内
static func is_in_range(attacker: BaseCombatant, target: BaseCombatant, min_range: float = 0.0, max_range: float = 999.0) -> bool:
	var distance = get_combatant_distance(attacker, target)
	return distance >= min_range and distance <= max_range

## 从武器数据获取武器射程
static func get_weapon_range(weapon_id: String) -> Dictionary:
	if weapon_id.is_empty():
		# 默认近战武器范围
		return {"min": 0.0, "max": 150.0}
	
	var weapon_data = Global.get_weapon_data(weapon_id)
	if weapon_data == null:
		return {"min": 0.0, "max": 150.0}
	
	return {
		"min": weapon_data.weapon_min_range if weapon_data.has("weapon_min_range") else 0.0,
		"max": weapon_data.weapon_max_range if weapon_data.has("weapon_max_range") else 150.0
	}

## 使用 Tween 平滑移动作战单位
## duration=0 时直接瞬移
static func move_combatant(combatant: BaseCombatant, target_x: float, duration: float = 0.3, callback: Callable = Callable()) -> void:
	var clamped_x = clamp(target_x, 0.0, COMBAT_WIDTH)
	
	if duration <= 0:
		# 瞬移：直接设置并同步镜头基准
		combatant.position_x = clamped_x
		combatant.sync_camera_base()
		if callback.is_valid():
			callback.call()
		return
	
	var tween = combatant.create_tween()
	tween.tween_property(combatant, "position_x", clamped_x, duration).set_trans(Tween.TRANS_SINE)
	
	if callback.is_valid():
		tween.finished.connect(callback)
	
	# tween 完成后同步镜头基准位置
	tween.finished.connect(combatant.sync_camera_base)

## 应用击退 - 将作战单位推离击退源
static func apply_knockback(combatant: BaseCombatant, knockback_source_x: float, force: float, duration: float = 0.2) -> void:
	var current_x = combatant.position_x
	var direction = sign(current_x - knockback_source_x)
	# 如果在同一位置，默认向右
	if direction == 0:
		direction = 1
	
	var target_x = clamp(current_x + (direction * force), 0.0, COMBAT_WIDTH)
	move_combatant(combatant, target_x, duration)

## 获取移动方向（相对于目标）
static func get_direction_to_target(attacker: BaseCombatant, target: BaseCombatant) -> float:
	if target.position_x > attacker.position_x:
		return 1.0  # 向右
	else:
		return -1.0  # 向左

## 计算目标位置（用于击退/后坐力）
static func calculate_knockback_target(combatant: BaseCombatant, source_x: float, force: float) -> float:
	var direction = sign(combatant.position_x - source_x)
	if direction == 0:
		direction = 1
	return clamp(combatant.position_x + (direction * force), 0.0, COMBAT_WIDTH)

## 计算后坐力目标位置（与攻击方向相反）
static func calculate_recoil_target(attacker: BaseCombatant, attack_direction: float, recoil_force: float) -> float:
	var direction = -sign(attack_direction)
	if direction == 0:
		direction = -1
	return clamp(attacker.position_x + (direction * recoil_force), 0.0, COMBAT_WIDTH)