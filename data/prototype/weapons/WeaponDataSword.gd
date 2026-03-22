# 剑 - 近战武器
extends WeaponData
class_name WeaponDataSword

func _init():
	object_uid = "weapon_sword"
	weapon_name = "剑"
	weapon_description = "标准的近战武器"
	weapon_type = WEAPON_TYPES.MELEE
	attack_range_min = 0.0
	attack_range_max = 100.0
	knockback_force = 30.0
	recoil_force = 10.0
	piercing = false
	area_damage = false
