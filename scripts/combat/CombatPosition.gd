# 位置系统 - 给战斗单位添加一维坐标
extends Resource
class_name CombatPosition

# 一维坐标 X (0 = 地图最左端)
var position_x: float = 0.0

# 战斗单位类型
enum CombatEntityType {
	PLAYER,
	ENEMY
}

var entity_type: CombatEntityType = CombatEntityType.PLAYER

func _init(x: float = 0.0, type: CombatEntityType = CombatEntityType.PLAYER):
	position_x = x
	entity_type = type
