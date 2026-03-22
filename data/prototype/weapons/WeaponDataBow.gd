# 弓 - 远程武器
extends WeaponData
class_name WeaponDataBow

func _init():
	object_uid = "weapon_bow"
	weapon_name = "弓"
	weapon_description = "远程射击武器，攻击距离远但伤害较低"
	weapon_type = WEAPON_TYPES.RANGED
	attack_range_min = 150.0
	attack_range_max = 400.0
	knockback_force = 10.0
	recoil_force = 20.0
	piercing = true  # 箭可以穿透
	area_damage = false
