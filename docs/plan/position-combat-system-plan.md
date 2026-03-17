# Implementation Plan: Position-Based Combat System

## Overview

This plan adds a complete position-based combat system with distance calculation, attack ranges, knockback, and recoil mechanics.

---

## Current Architecture

- **Game Type**: Godot-based deck-builder (Slay the Spire-like)
- **Combat System**: UI-based with positioned enemies in `EnemyContainer`
- **Core Classes**:
  - `BaseCombatant` → `Player` / `Enemy`
  - Actions (attack, block, etc.) extend `BaseAction`
  - `CardData` contains `card_values` dictionary

**Key Finding**: Currently **no position/distance system exists** - enemies are positioned statically and there's no weapon type or range system.

---

## 1. Files to Create

| File | Purpose |
|------|---------|
| `scripts/combat/PositionSystem.gd` | Core position & distance calculation |
| `scripts/data/WeaponData.gd` | Weapon type definitions (melee/ranged) |
| `scripts/actions/combat_actions/ActionKnockback.gd` | Player knockback on damage |
| `scripts/actions/combat_actions/ActionRecoil.gd` | Card attack recoil |
| `scripts/validators/combat/ValidatorAttackRange.gd` | Range validation for targeting |
| `scripts/combatants/CombatPositionHandler.gd` | Position tweening/movement |

## 2. Files to Modify

| File | Changes |
|------|---------|
| `data/readonly/CharacterData.gd` | Add `character_default_weapon_id` |
| `data/prototype/CardData.gd` | Add `card_weapon_id`, `card_recoil_force` |
| `scripts/combatants/Player.gd` | Add position handling, weapon equip |
| `scripts/combatants/Enemy.gd` | Add attack range to enemy data |
| `data/prototype/EnemyData.gd` | Add `enemy_attack_range` |
| `autoload/Signals.gd` | Add `player_moved`, `combatant_knockback_started` |
| `autoload/Scripts.gd` | Register new actions |

---

## 3. Data Structures

### WeaponData (new)

```gdscript
class_name WeaponData
extends SerializableData

enum WEAPON_TYPES { MELEE, RANGED, THROW }

@export var weapon_name: String
@export var weapon_type: int = WEAPON_TYPES.MELEE
@export var weapon_base_range: float = 100.0  # pixels
@export var weapon_recoil_force: float = 20.0  # pixels pushed back
@export var weapon_icon_path: String
```

### CardData Extensions

```gdscript
# Add to card_values or as export:
@export var card_weapon_id: String = ""  # empty = default weapon
@export var card_recoil_force: float = 0.0  # push player back on attack
@export var card_knockback_received: float = 0.0  # when player takes damage
```

### EnemyData Extensions

```gdscript
@export var enemy_attack_range: float = 150.0  # how far enemy can attack from
@export var enemy_knockback_force: float = 30.0  # push player on attack
```

### PositionData (runtime)

```gdscript
class_name PositionData
var combatant: BaseCombatant
var current_position: Vector2
var base_position: Vector2
var is_moving: bool = false
```

---

## 4. Key Module Interfaces

### PositionSystem.gd (Core)

```gdscript
class_name PositionSystem

## Calculate distance between two combatants (pixel-based)
static func get_combatant_distance(combatant_a: BaseCombatant, combatant_b: BaseCombatant) -> float:
    return combatant_a.position.distance_to(combatant_b.position)

## Check if target is within attack range
static func is_in_range(attacker: BaseCombatant, target: BaseCombatant, range: float) -> bool:
    return get_combatant_distance(attacker, target) <= range

## Get weapon range from weapon data or default
static func get_weapon_range(weapon_id: String) -> float:
    # lookup from Global.weapon_registry
    pass

## Tween combatant to new position with optional callback
static func move_combatant(combatant: BaseCombatant, target_pos: Vector2, duration: float = 0.3):
    # use Tween for smooth movement
    pass

## Apply knockback - push combatant away from source
static func apply_knockback(combatant: BaseCombatant, knockback_source: Vector2, force: float):
    # calculate direction and apply movement
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
    # Recoil pushes the ATTACKER (player) backward after attacking
    var recoil_force = get_action_value("recoil_force", 20.0)
    var attack_direction = get_action_value("attack_direction", Vector2.RIGHT)
    
    # Player gets pushed opposite to attack direction
    var player = Global.get_player()
    var recoil_direction = -attack_direction.normalized()
    var target_pos = player.position + (recoil_direction * recoil_force)
    
    PositionSystem.move_combatant(player, target_pos, 0.2)
```

### ValidatorAttackRange.gd

```gdscript
extends BaseValidator

func validate(validated_object, source: BaseCombatant) -> bool:
    var target = validated_object  # enemy being targeted
    var weapon_id = get_validator_value("weapon_id", "")
    var range = PositionSystem.get_weapon_range(weapon_id)
    return PositionSystem.is_in_range(source, target, range)
```

---

## 5. Implementation Order

### Phase 1: Core Infrastructure (Week 1)
1. **Create PositionSystem.gd** - Basic distance calculation and movement
2. **Create WeaponData.gd** - Weapon type definitions
3. **Add signals** to Signals.gd for movement events
4. **Register new actions** in Scripts.gd

### Phase 2: Data Extensions (Week 1-2)
5. **Extend CharacterData** - Add default weapon
6. **Extend CardData** - Add weapon_id, recoil_force, knockback_received
7. **Extend EnemyData** - Add attack_range, knockback_force

### Phase 3: Action Implementation (Week 2)
8. **Implement ActionKnockback.gd** - Player knockback when attacked
9. **Implement ActionRecoil.gd** - Weapon recoil on attack
10. **Modify ActionAttack.gd** - Trigger recoil after damage

### Phase 4: Integration (Week 2-3)
11. **Create CombatPositionHandler.gd** - Initialize positions, bounds
12. **Modify Combat.gd** - Apply knockback after enemy attacks
13. **Add ValidatorAttackRange.gd** - Validate targeting by range

### Phase 5: Polish (Week 3)
14. **Add animations** - Tween-based knockback/recoil visuals
15. **Add UI feedback** - Show attack range when hovering cards

---

## 6. Code Style Notes

The codebase uses:
- **GDScript** with typed variables
- **PascalCase** for classes/functions, **snake_case** for variables
- **Signal-based** event system (`Signals.combatant_damaged.emit()`)
- **Action system** for all game logic (extend `BaseAction`)
- **Dictionary-based** configuration (`card_values`, `values`)

---

## Summary

This plan adds a complete position-based combat system while maintaining compatibility with existing architecture. The implementation is modular - you can start with just distance calculation and progressively add weapon types, knockback, and recoil.
