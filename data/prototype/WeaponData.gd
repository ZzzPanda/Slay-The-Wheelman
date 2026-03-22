# 武器数据原型 - 定义武器的属性和行为
extends PrototypeData
class_name WeaponData

## 武器类型
enum WEAPON_TYPES { MELEE, RANGED, THROW }
@export var weapon_type: int = WEAPON_TYPES.MELEE

## 武器名称和描述
@export var weapon_name: String = ""
@export var weapon_description: String = ""

## 攻击范围 (基于位置系统的距离单位 0-1000)
@export var attack_range_min: float = 0.0    # 最小攻击距离
@export var attack_range_max: float = 150.0  # 最大攻击距离

## 战斗属性
@export var knockback_force: float = 50.0    # 击退力度
@export var recoil_force: float = 30.0       # 后坐力

## 特殊效果
@export var piercing: bool = false            # 穿透（可攻击多个敌人）
@export var area_damage: bool = false         # 范围伤害
@export var area_damage_radius: float = 100.0 # 范围伤害半径

## 视觉效果
@export var weapon_texture_path: String = ""
@export var attack_animation_name: String = "attack"

func _to_string() -> String:
	return get_weapon_name()

func get_weapon_name() -> String:
	return weapon_name

## 检查目标是否在攻击范围内
func is_target_in_range(source_x: float, target_x: float) -> bool:
	var distance = abs(target_x - source_x)
	return distance >= attack_range_min and distance <= attack_range_max

## 获取攻击范围描述
func get_range_description() -> String:
	if attack_range_min > 0:
		return "范围: %.0f-%.0f" % [attack_range_min, attack_range_max]
	else:
		return "范围: %.0f" % attack_range_max
