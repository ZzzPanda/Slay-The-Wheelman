# 武器数据原型 - 用于定义游戏中的武器
extends PrototypeData
class_name WeaponData

@export var weapon_id: String = ""           # 武器唯一ID
@export var weapon_name: String = ""          # 武器名称
@export var weapon_description: String = ""  # 武器描述
@export var weapon_texture_path: String = "" # 武器纹理路径

### 武器类型
enum WEAPON_TYPES {
	MELEE,      # 近战武器
	RANGED,     # 远程武器
	THROW,      # 投掷武器
}
@export var weapon_type: int = WEAPON_TYPES.MELEE

### 攻击范围 (一维坐标)
@export var attack_range_min: float = 0.0   # 最小攻击距离
@export var attack_range_max: float = 1000.0 # 最大攻击距离

### 攻击属性
@export var base_damage: int = 5              # 基础伤害
@export var attack_speed: float = 1.0         # 攻击速度 (次/秒)
@export var knockback_force: float = 30.0     # 击退力度
@export var recoil_force: float = 20.0       # 后坐力

### 特殊效果
@export var piercing: bool = false           # 是否穿透
@export var splash: bool = false             # 是否范围伤害
@export var splash_radius: float = 0.0        # 范围伤害半径

### 子弹/投射物
@export var projectile_texture_path: String = ""
@export var projectile_speed: float = 500.0   # 投射物速度
@export var projectile_lifetime: float = 3.0 # 投射物存在时间(秒)

### 动画
@export var attack_animation_name: String = "attack"
@export var idle_animation_name: String = "idle"

func _to_string() -> String:
	return weapon_name

func get_weapon_name() -> String:
	return weapon_name

func get_attack_range() -> Dictionary:
	return {
		"min": attack_range_min,
		"max": attack_range_max
	}

func is_in_range(target_position_x: float, attacker_position_x: float) -> bool:
	var distance = abs(target_position_x - attacker_position_x)
	return distance >= attack_range_min and distance <= attack_range_max

func get_effective_damage(base_damage_modifier: float = 1.0) -> int:
	return int(base_damage * base_damage_modifier)
