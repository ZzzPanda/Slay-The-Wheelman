# Slay The Wheelman 汉化方案

## 一、现状分析

### 需要翻译的内容
| 类型 | 位置 | 示例 |
|------|------|------|
| 卡牌名称/描述 | `data/readonly/CardData.gd` | "Strike", "Block", "Bash" |
| 神器名称/描述 | `data/readonly/ArtifactData.gd` | "Gold Ring", "Pearl" |
| 怪物名称/描述 | `data/readonly/EnemyData.gd` | "Small Bot", "Big Bot" |
| UI 文本 | `scenes/ui/*.tscn` | 按钮、标签、提示 |
| 地图/事件文本 | `data/prototype/` | 事件描述、对话 |
| 职业/能力文本 | `scripts/` | "Attack", "Defend" |

### 当前问题
- ❌ 无国际化系统
- ❌ 大量硬编码英文字符串
- ❌ 卡牌类型/稀有度直接用英文 ("Attack", "Skill", "Rare")

---

## 二、推荐方案

### 方案 A: Godot 内置 TranslationServer (推荐)

```gdscript
# 1. 创建翻译文件
# res://translations/zh_CN.csv 或 .po

# 2. 加载翻译
func _ready():
    TranslationServer.set_locale("zh_CN")
    
# 3. 使用 tr() 包裹字符串
var text = tr("STRIKE")  # 显示 "打击"
```

**优点**: Godot 原生支持，无需插件
**缺点**: 需要逐个标记字符串

### 方案 B: 自定义 JSON 翻译系统

```gdscript
# 创建 translations.json
{
  "en": {"strike": "Strike", "block": "Block"},
  "zh": {"strike": "打击", "block": "格挡"}
}

# 加载
var translations = load_json("translations.json")
func tr(key): return translations[locale][key]
```

**优点**: 灵活可控
**缺点**: 需要自己实现

---

## 三、执行计划

### Phase 1: 基础设施 (预计 30 分钟)
- [ ] 创建 `autoload/Translation.gd` 翻译管理器
- [ ] 创建 `translations/` 文件夹
- [ ] 建立中英对照表 (CSV/JSON 格式)

### Phase 2: 核心数据翻译 (预计 1-2 小时)
- [ ] 翻译卡牌数据 (约 50+ 张卡)
- [ ] 翻译神器数据 (约 20+ 个神器)
- [ ] 翻译怪物数据
- [ ] 翻译地图/事件文本

### Phase 3: UI 文本翻译 (预计 1 小时)
- [ ] 翻译按钮文本 (Shop, Rest, etc.)
- [ ] 翻译提示文本 (Tooltip)
- [ ] 翻译胜利/失败界面

### Phase 4: 字体支持 (预计 30 分钟)
- [ ] 添加中文字体 (Noto Sans CJK / 思源黑体)
- [ ] 配置字体 fallback

### Phase 5: 测试优化 (预计 30 分钟)
- [ ] 测试中文显示
- [ ] 修复字体/布局问题

---

## 四、关键文件清单

```
Slay-The-Wheelman/
├── translations/
│   ├── en.csv
│   └── zh_CN.csv
├── autoload/
│   └── Translation.gd        # 新增
└── data/
    └── readonly/
        ├── CardData.gd        # 卡牌名称/描述
        ├── ArtifactData.gd    # 神器名称/描述
        └── EnemyData.gd       # 怪物名称/描述
```

---

## 五、立即执行

要我开始 Phase 1 吗？创建翻译管理器和基础文件结构？

或者你想先看看具体哪些字符串需要翻译？
