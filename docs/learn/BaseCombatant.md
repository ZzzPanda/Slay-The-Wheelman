# 架构图：谁负责什么

```
BaseCombatant (extends Control)
├─ UI 绑定（@onready）
│  ├─ Sprite/HealthBar/Block/StatusContainer/CustomUIContainer/FadeContainer/SelectionButton
│  └─ AnimationPlayer
│
├─ 战斗流程入口（Signals）
│  ├─ combat_started / ended
│  └─ player_turn_started / ended
│
├─ 核心状态容器（内存结构）
│  ├─ status_id_to_status_effects: { status_id -> [StatusEffect(UI节点), ...] }
│  └─ custom_ui_object_id_to_custom_ui: { ui_id -> BaseCustomUI(UI节点) }
│
└─ 外部系统依赖（关键！）
   ├─ Global: 读取数据表（StatusEffectData / CustomUIData）
   ├─ Scenes: PackedScene 预制体仓库（STATUS_EFFECT / TEXT_FADE）
   ├─ ActionGenerator: 把“数据/意图”生成 Action（衰减、重置 block 等）
   └─ ActionHandler: action 队列 + interceptor 注册/注销
```


# 这段代码是什么？

BaseCombatant 是一个战斗单位的基类（玩家/敌人都继承它），同时它也是一个 UI 控件（extends Control）：

它负责把“战斗数据状态”（血量、格挡、状态效果、自定义 UI）和“界面表现”（血条、block 显示、浮字、状态图标、选择按钮、动画）连起来。

它不是完整实现：很多函数用 # override + breakpoint 标出来，表示子类必须实现（类似抽象方法）。

1) 资源绑定：@onready var ... = $Path

这些变量都是在节点树里找子节点：

block, block_amount：格挡图标和数字

animation_player：播放攻击动画 "attack"

sprite, layered_health_bar：角色精灵和血条 UI

fade_container：用来放“伤害数字/Blocked”浮字

selection_button：点击选中这个战斗单位

status_container：放状态图标（GridContainer）

custom_ui_container：挂额外 UI（比如特殊计数器、buff 面板等）

👉 学习重点：这说明 BaseCombatant 的场景结构必须包含这些路径，否则运行会报节点找不到。

2) 信号系统：_ready() 里统一接 Signals
Signals.combat_started.connect(_on_combat_started)
...
selection_button.button_up.connect(_on_selection_button_up)

这让 BaseCombatant 能响应全局战斗流程（开始/结束/回合开始/结束），以及被点击选中。

_on_selection_button_up() 默认 pass，子类（玩家/敌人）可以重写，比如选中目标、显示意图等。

3) Block 模块：格挡逻辑 + reset action

这里设计成：block 的真实数值由子类实现，基类只提供通用逻辑。

set_block/get_block/add_block 都是抽象（breakpoint）

generate_reset_block_action()：重点！

它生成一条 action 放进 ActionHandler 的 action stack：

Scripts.ACTION_RESET_BLOCK: {
  "target_override": BaseAction.TARGET_OVERRIDES.PARENT,
  "time_delay": 0.0
}

理解这个的关键是你们项目的“动作系统”：

ActionGenerator.create_actions(...) 把“动作数据”转成可执行的 action 对象

ActionHandler.add_actions(...) 把 action 推入队列

然后 reset_block() 只是直接 set_block(0)，但战斗流程更可能用 action 方式重置（可插入动画、拦截器、顺序控制）。

4) Health 模块：血条/存活/伤害

update_health_bar(as_damage=false)：基类定义接口，子类来真正刷新 layered health bar 的表现（比如先扣红条，再缓慢扣灰条）

is_alive()：默认 true，子类改成 hp > 0

damage(...)：抽象，返回数组 [unblocked, overkill, ...]（你注释写了 2 项，但返回写了 3 个 0，说明这里可能还扩展了第三项，比如“是否致死/是否触发格挡”之类）

👉 学习重点：这是典型“数据逻辑在子类/战斗系统”，基类只管 UI 和接口约束。

5) Custom UI 模块：给单位挂“可选 UI 组件”

这段设计非常实用：

register_custom_ui(custom_ui_object_id)

先查 custom_ui_object_id_to_custom_ui，避免重复注册

Global.get_custom_ui_data(id) 拿配置（类似 ScriptableObject/数据表）

custom_ui_asset_path 指向一个 UI 场景

instantiate() 出来后加到 custom_ui_container

custom_ui.init(id, self)：把自己（combatant）传进去，让 UI 能读单位数据

unregister / unregister_all

queue_free 删除节点，并从 dictionary 移除

👉 这相当于一个“单位插件 UI”系统：buff 计数器、怒气条、护盾条都可以做成独立组件挂上去。

6) Fades：伤害/格挡浮字
var text_fade: TextFade = Scenes.TEXT_FADE.instantiate()
fade_container.add_child(text_fade)
text_fade.init("Blocked" / damage_amount)

就是统一生成一个浮字节点，塞进容器。
学习重点：Scenes 这里是一个“预制体仓库”（PackedScene 常量）。

7) Statuses：这段是最核心、也最值得学的

这里维护了一个映射：

var status_id_to_status_effects: Dictionary = {}
# status_id -> Array[StatusEffect] (UI 节点)
7.1 add_status_effect_charges：给某种状态“加/减层数”

逻辑顺序：

charge 为 0 直接 return（无意义更新）

从 Global.get_status_effect_data(id) 拿配置，没找到就 push_error

找到当前已有的 status_effect UI 列表

如果没有就 _create_status_effect(id) 创建一个

遍历这个 status 的所有实例（因为允许 multiples 时可能有多个）

status_effect_script.add_status_charges(charge_amount)

status_secondary_charges += secondary_charge_amount

charges 变 0 就 _remove_status_effect

否则更新 UI 显示 update_status_charge_display()

update_health_bar(false)

Signals.enemy_intent_changed.emit()：状态可能影响敌人意图显示

学习重点：

状态“数据”存在 status_effect.status_effect_script 里（BaseStatusEffect）

UI 节点 StatusEffect 只是显示层，脚本才是逻辑层

7.2 add_new_status_effect：强制新增一个实例

用于“允许 multiples”的状态（比如多个中毒源）

如果状态不允许 multiples 且已存在，那么 _create_status_effect 会返回 null

7.3 _create_status_effect：创建 UI + 创建脚本 + 绑定 + 注册拦截器

这是非常关键的“装配”函数：

instantiate Scenes.STATUS_EFFECT（UI 节点）

load status_effect_script_path，new 出一个 BaseStatusEffect

把 UI 节点塞进 status_id_to_status_effects[id] 数组

status_effect.status_effect_script = status_effect_script

status_container.add_child(status_effect)

status_effect_script.init(status_effect_data, self)

并且：第一次创建该 status 类型时注册 interceptors

ActionHandler.register_action_interceptor(self, interceptor_id)

当该 status 类型最后一个实例被删掉时（_remove_status_effect），会 unregister。

👉 这说明你们的 buff/debuff 不只是显示，它还能“拦截动作”（比如受到伤害时触发、出牌时触发等）。

7.4 perform_status_effect_actions：在某个回合阶段执行并衰减

流程：

_get_status_effects_with_process_time(...) 找到在这个阶段要触发的 status ids

按 priority 排序（同优先级按 object_id 稳定排序）

对每种 status：对其所有实例执行 perform_status_effect_actions()

然后 _decay_status_effect(id)（通过 ActionGenerator 生成“衰减动作”）

这保证：

状态执行顺序可预测

状态衰减也走 action 系统（可动画化、可被拦截）

你怎么学最快：按“画数据流”练一遍

我建议你做 3 个小练习（不用改系统大架构）：

加一个新状态（比如 “Regen”）

在 Global 的 status 数据里配置：priority、process_time、script_path、interceptors

写一个 BaseStatusEffect 子类实现 perform_status_effect_actions()（比如每回合加血）

在某个技能里调用 add_status_effect_charges("regen", 1)

验证 multiples 的行为

做一个允许 multiples 的状态（如 poison stacks）

用 add_new_status_effect 连续加两个实例，观察 UI 里是否出现两个图标、charges 是否独立

跟踪一次状态衰减

在 _decay_status_effect 里打 log，看看 decay_amount 从哪来（get_status_decay_amount()）

跟到 ActionGenerator.generate_decay_status_effect 看它生成了什么 action