# 废土防线 (Wasteland Defense)

Godot 4.4 像素风塔防+探索游戏。末日后城市背景，玩家从大本营出发探索废墟、清除怪物、恢复设施、建造塔防抵御波次进攻。

## 如何运行

1. 打开 Godot 4.4
2. 导入 `project.godot`
3. 按 F5 运行

## 游戏玩法

从大本营出发，进入废墟区域清除怪物波次。击杀敌人获得金钱，金钱可用于建造塔防、升级属性、解锁武器、恢复设施。清除全部波次（含BOSS）后可激活设施获得永久增益，全部设施激活即通关。

## 已实现功能

### 核心循环
- 大本营 ↔ 探索区域 场景切换
- 4波敌人进攻 + BOSS战
- 区域清除后恢复3种设施
- 全部设施激活 → 胜利界面

### 玩家系统
- WASD移动，鼠标瞄准射击
- 4种武器（手枪/冲锋枪/霰弹枪/步枪），数字键1-4切换
- 血量系统，医疗站激活后自动回血
- 4帧行走动画，左右翻转
- 玩家死亡 → 游戏结束面板

### 敌人系统
- 3种敌人：普通丧尸（绿）、快速丧尸（橙）、远程丧尸（紫）
- NavigationAgent2D 自动绕障寻路
- 受击击退 + 伤害飘字 + 闪白反馈
- 每种敌人独立4帧行走动画
- BOSS：高血量、冲撞攻击、AOE范围攻击、死亡慢动作

### 塔防系统
- 4种塔：机枪塔（速射）、火炮塔（范围爆炸）、激光塔（持续伤害递增+追踪）、迫击炮（远程大范围）
- 建造模式（B键），1-4切换塔类型，右侧快捷栏
- 只能在绿色建造点建造
- 塔防升级（最高3级）+ 出售（返还70%）
- 每种塔独立外观

### 经济与升级
- 杀怪得钱，初始资金99999（测试用）
- 大本营升级终端（E键）：生命/攻击/移速/射速
- 武器解锁与切换
- 设施增益：医疗站（回血）、工坊（塔伤害+20%）、发电站（塔射程+15%）

### 视觉与音效
- 32x32 像素美术（玩家/敌人/塔防/子弹/设施/障碍物）
- 屏幕震动（射击/爆炸/受击/BOSS死亡）
- 爆炸粒子 + 枪口焰 + 击杀慢动作
- 8-bit 音效（射击/命中/死亡）+ 循环BGM
- 主菜单 + 暂停菜单（ESC）+ 胜利/失败界面

## 操作说明

| 按键 | 功能 |
|------|------|
| W/A/S/D | 移动 |
| 鼠标左键 | 射击 / 建造模式下放置塔 |
| 鼠标移动 | 瞄准 |
| 1/2/3/4 | 切换武器 / 建造模式下切换塔类型 |
| B | 切换建造模式 |
| E | 交互（升级终端/设施/出口） |
| R | 探索区域中返回大本营 |
| ESC | 暂停菜单 |

## 项目结构

```
newgame/
├── project.godot          # 项目配置 (Godot 4.4)
├── scenes/
│   ├── main_menu.tscn     # 主菜单（启动场景）
│   ├── base.tscn          # 大本营
│   ├── explore_zone.tscn  # 探索区域
│   ├── player.tscn        # 玩家
│   ├── enemy.tscn         # 敌人
│   ├── boss.tscn          # BOSS
│   ├── tower.tscn         # 塔防
│   ├── bullet.tscn        # 子弹
│   ├── build_spot.tscn    # 建造点
│   ├── facility.tscn      # 设施
│   ├── explosion.tscn     # 爆炸效果
│   ├── damage_number.tscn # 伤害飘字
│   └── ui/                # UI面板
├── scripts/
│   ├── globals.gd         # GameState 全局单例
│   ├── sound_manager.gd   # 音效管理单例
│   ├── player.gd          # 玩家控制+动画
│   ├── enemy.gd           # 敌人AI+动画
│   ├── boss.gd            # BOSS逻辑
│   ├── tower.gd           # 塔防逻辑+升级出售
│   ├── bullet.gd          # 子弹逻辑
│   ├── wave_manager.gd    # 波次管理
│   ├── explore_zone.gd    # 探索区域主逻辑
│   ├── base.gd            # 大本营逻辑
│   ├── build_spot.gd      # 建造点
│   ├── facility.gd        # 设施
│   ├── explosion.gd       # 爆炸效果
│   ├── damage_number.gd   # 伤害飘字
│   ├── main_menu.gd       # 主菜单
│   ├── pause_menu.gd      # 暂停菜单
│   ├── upgrade_panel.gd   # 升级面板
│   ├── tower_upgrade_panel.gd # 塔防升级面板
│   ├── game_over_panel.gd # 游戏结束
│   └── victory_panel.gd   # 胜利界面
└── assets/
	├── sprites/           # 32x32像素精灵图
	└── audio/             # 音效+BGM
```

## 物理层定义

| 层 | 名称 |
|----|------|
| 1 | world |
| 2 | player |
| 3 | enemy |
| 4 | bullet |
| 5 | tower |
| 6 | interactable |
