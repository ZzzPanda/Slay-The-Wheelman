# 实现计划：位置战斗系统

## 概述

本文档描述了完整的位置战斗系统实现方案，包含距离计算、攻击距离判定、击退和后坐力机制。

---

## 当前架构

- **游戏类型**: Godot 卡牌构筑游戏（类似 Slay the Spire）
- **战斗系统**: 基于 UI，敌人在 `EnemyContainer` 中定位
- **核心类**:
  - `BaseCombatant` → `Player` / `Enemy`
  - 行动（攻击、防御等）继承 `BaseAction`
  - `CardData` 包含 `card_values` 字典

**关键发现**: 当前代码库**不存在位置/距离系统** - 敌人是静态定位的，没有武器类型或距离判定。

---

## 1. 需要新建的文件

| 文件 | 用途 |
|------|------|
| `scripts/combat/PositionSystem.gd` | 核心位置与距离计算 |
| `scripts/data/WeaponData.gd` | 武器类型定义（近战/远程） |
| `scripts/actions/combat_actions/ActionKnockback.gd` | 受击击退 |
| `scripts/actions/combat_actions/ActionRecoil.gd` | 攻击后坐力 |
| `scripts/validators/combat/ValidatorAttackRange.gd` | 攻击距离校验 |
| `scripts/combatants/CombatPositionHandler.gd` | 位置移动处理 |

## 2. 需要修改的文件

| 文件 | 修改内容 |
|------|---------|
| `data/readonly/CharacterData.gd` | 添加 `character_default_weapon_id` |
| `data/prototype/CardData.gd` | 添加 `card_weapon_id`, `card_recoil_force` |
| `scripts/combatants/Player.gd` | 添加位置处理、武器装备 |
| `scripts/combatants/Enemy.gd` | 添加攻击距离到敌人数据 |
| `data/prototype/EnemyData.gd` | 添加 `enemy_attack_range` |
| `autoload/Signals.gd` | 添加 `player_moved`, `combatant_knockback_started` |
| `autoload/Scripts.gd` | 注册新行动 |

---

## 3. 数据结构设计

### WeaponData (新建)

```gdscript
class_name WeaponData
extends SerializableData

enum WEAPON_TYPES { MELEE, RANGED, THROW }

@export var weapon_name: String
@export var weapon_type: int = WEAPON_TYPES.MELEE
@export var weapon_base_range: float = 100.0  # 像素
@export var weapon_recoil_force: float = 20.0  # 后坐力像素
@export var weapon_icon_path: String
```

### CardData 扩展

```gdscript
# 添加到 card_values 或作为 export:
@export var card_weapon_id: String = ""  # 空 = 默认武器
@export var card_recoil_force: float = 0.0  # 攻击后推玩家
@export var card_knockback_received: float = 0.0  # 受击时击退
```

### EnemyData 扩展

```gdscript
@export var enemy_attack_range: float = 150.0  # 敌人攻击距离
@export var enemy_knockback_force: float = 30.0  # 攻击时推玩家
```

### PositionData (运行时)

```gdscript
class_name PositionData
var combatant: BaseCombatant
var current_position: Vector2
var base_position: Vector2
var is_moving: bool = false
```

---

## 4. 核心模块接口

### PositionSystem.gd (核心)

```gdscript
class_name PositionSystem

## 计算两个作战单位之间的距离（像素）
static func get_combatant_distance(combatant_a: BaseCombatant, combatant_b: BaseCombatant) -> float:
    return combatant_a.position.distance_to(combatant_b.position)

## 检查目标是否在攻击范围内
static func is_in_range(attacker: BaseCombatant, target: BaseCombatant, range: float) -> bool:
    return get_combatant_distance(attacker, target) <= range

## 从武器数据获取武器射程
static func get_weapon_range(weapon_id: String) -> float:
    # 从 Global.weapon_registry 查找
    pass

## 使用 Tween 平滑移动作战单位
static func move_combatant(combatant: BaseCombatant, target_pos: Vector2, duration: float = 0.3):
    pass

## 应用击退 - 将作战单位推离击退源
static func apply_knockback(combatant: BaseCombatant, knockback_source: Vector2, force: float):
    pass
```

### ActionKnockback.gd

```gdscript
extends BaseAction

func perform_action():
    var targets = get_adjusted_action_targets()
    for target in targets:
        var knockback_force = get_action_value("knockback_force", 30.0)
        var knockback_source = get_action_value("knockback_source", parent_combatant.position)
        PositionSystem.apply_knockback(target, knockback_source, knockback_force)
```

### ActionRecoil.gd

```gdscript
extends BaseAction

func perform_action():
    # 后坐力将攻击者（玩家）向后推
    var recoil_force = get_action_value("recoil_force", 20.0)
    var attack_direction = get_action_value("attack_direction", Vector2.RIGHT)
    
    # 玩家向攻击方向相反被推
    var player = Global.get_player()
    var recoil_direction = -attack_direction.normalized()
    var target_pos = player.position + (recoil_direction * recoil_force)
    
    PositionSystem.move_combatant(player, target_pos, 0.2)
```

### ValidatorAttackRange.gd

```gdscript
extends BaseValidator

func validate(validated_object, source: BaseCombatant) -> bool:
    var target = validated_object
    var weapon_id = get_validator_value("weapon_id", "")
    var range = PositionSystem.get_weapon_range(weapon_id)
    return PositionSystem.is_in_range(source, target, range)
```

---

## 5. 实现顺序

### 第一周：核心基础设施
1. **创建 PositionSystem.gd** - 基础距离计算和移动
2. **创建 WeaponData.gd** - 武器类型定义
3. **添加信号**到 Signals.gd
4. **注册新行动**到 Scripts.gd

### 第一周半：数据扩展
5. **扩展 CharacterData** - 添加默认武器
6. **扩展 CardData** - 添加 weapon_id, recoil_force
7. **扩展 EnemyData** - 添加 attack_range, knockback_force

### 第二周：行动实现
8. **实现 ActionKnockback.gd** - 受击击退
9. **实现 ActionRecoil.gd** - 武器后坐力
10. **修改 ActionAttack.gd** - 攻击后触发后坐力

### 第二周半：集成
11. **创建 CombatPositionHandler.gd** - 初始化位置
12. **修改 Combat.gd** - 敌人攻击后应用击退
13. **添加 ValidatorAttackRange.gd** - 距离校验

### 第三周：优化
14. **添加动画** - 基于 Tween 的击退/后坐力动画
15. **添加 UI 反馈** - 悬停卡牌时显示攻击范围

---

## 6. 代码风格

项目使用：
- **GDScript** 带类型变量
- **PascalCase** 用于类/函数，**snake_case** 用于变量
- **信号驱动**事件系统 (`Signals.combatant_damaged.emit()`)
- **行动系统**处理所有游戏逻辑（继承 `BaseAction`）
- **字典配置** (`card_values`, `values`)

---

## 总结

本计划添加了完整的位置战斗系统，同时保持与现有架构的兼容性。实现是模块化的 - 你可以从距离计算开始，逐步添加武器类型、击退和后坐力。
