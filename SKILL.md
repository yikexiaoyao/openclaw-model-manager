---
name: openclaw-model-manager
description: OpenClaw 模型配置管理技能。用于添加、删除、更新、查看、切换、检测模型配置。触发指令：openclaw models list、openclaw models set、openclaw models status、openclaw models help。
metadata:
  openclaw:
    emoji: "🔧"
    always: false
    requires:
      bins: []
      env: []
triggers:
  - skill models list
  - skill models set
  - skill models status
  - skill models check
  - skill models add
  - skill models delete
  - skill models update
  - skill models test
  - skill models help
  - 切换模型
  - 模型列表
  - 模型配置
  - model manager
---

# Model Manager

OpenClaw 模型配置管理技能，用于统一维护模型与 provider 配置。

---

## 前置条件

| 项目 | 要求 | 检查方式 |
|------|------|----------|
| OpenClaw | >= v2026.6.0 | `openclaw --version` |
| 配置文件 | `~/.openclaw/openclaw.json` 存在 | `ls ~/.openclaw/openclaw.json` |
| 至少 1 个模型 | providers 下配置了至少一个模型 | `skill models list` |

---

## 命令列表

| 序号 | 命令 | 用途 | 输出格式 |
|------|------|------|----------|
| 1 | `skill models list` | 查看已配置模型列表 | 编号 + 模型名 + 状态标记 |
| 2 | `skill models set <序号/模型名>` | 切换主模型 | 确认 + 生效状态 |
| 3 | `skill models set <主模型> fallback <兜底>` | 切换主模型并指定兜底 | 确认 + 兜底链 |
| 4 | `skill models status` | 查看主模型/备用模型/配置摘要 | 结构化状态卡 |
| 5 | `skill models check` | 检查模型连通性 | ✅/❌ + 延迟 |
| 6 | `skill models test` | 发送测试请求验证响应 | ✅/❌ + 响应摘要 |
| 7 | `skill models add <模型名>` | 添加新模型配置 | 确认 + 新配置摘要 |
| 8 | `skill models delete <序号/模型名>` | 删除模型配置 | 确认 + 剩余模型数 |
| 9 | `skill models update <序号> <参数> <值>` | 更新模型参数 | 确认 + 变更内容 |
| 10 | `skill models fix` | 自动检测并修复配置错误 | 修复报告 |
| 11 | `skill models help` | 显示帮助信息 | 命令列表 |

---

## 输出格式规范

### `skill models list` 输出

```
当前模型列表（共 N 个）

 # │ 模型 ID                              │ 状态
───┼──────────────────────────────────────┼────────
 1 │ bailian/qwen3.7-plus                │ ✅ 当前
 2 │ custom-127-0-0-1-8888/Qwen3.5-9B   │ ⏸ 备用
 3 │ bailian/qwen-max                    │ ○ 待用
```

状态标记说明：
- ✅ 当前 — 主模型（primary）
- ⏸ 备用 — 兜底链中的模型（fallbacks）
- ○ 待用 — 已配置但未激活

### `skill models status` 输出

```
模型状态

  主模型:   ✅ bailian/qwen3.7-plus
  兜底链:   ⏸ custom-127-0-0-1-8888/Qwen3.5-9B-MLX-4bit
  总配置:   3 个模型
  配置文件: ~/.openclaw/openclaw.json
```

### `skill models check` 输出

```
模型连通性检查

 # │ 模型 ID                  │ 状态    │ 延迟
───┼──────────────────────────┼─────────┼──────
 1 │ bailian/qwen3.7-plus    │ ✅ OK   │ 31ms
 2 │ custom-.../Qwen3.5-9B   │ ❌ OFF  │ —
```

---

## 快速开始

```bash
# 1. 查看当前所有模型
skill models list

# 2. 切换到第 2 个模型
skill models set 2

# 3. 查看状态
skill models status

# 4. 检查连通性
skill models check
```

---

## 常见用例

| 场景 | 命令 | 说明 |
|------|------|------|
| 切换到云端模型 | `skill models set 1` | 按编号切换 |
| 切换到本地模型 | `skill models set 2` | 按编号切换 |
| 云端主 + 本地兜底 | `skill models set 1 fallback 2` | 本地↔云端互补 |
| 添加新模型 | `skill models add bailian/qwen-max` | 自动写入配置 |
| 删除不用的模型 | `skill models delete 3` | 自动处理关联 |
| 检测并修复错误 | `skill models fix` | 一键修复 |

---

## 安装与部署

### 方式 A：从 ClawHub 安装（推荐）

```bash
# 搜索技能
openclaw skills search openclaw-model-manager

# 安装
openclaw skills install openclaw-model-manager

# 验证
openclaw skills list | grep model-manager
```

### 方式 B：本地部署

```bash
# 1. 创建技能目录
mkdir -p ~/.openclaw/workspace/skills/openclaw-model-manager

# 2. 将 SKILL.md 放入目录
cp SKILL.md ~/.openclaw/workspace/skills/openclaw-model-manager/

# 3. 验证安装
openclaw skills list | grep model-manager
```

### 安装后验证

| 检查项 | 命令 | 预期结果 |
|--------|------|----------|
| 技能状态 | `openclaw skills list` | `✓ ready │ 🔧 openclaw-model-manager` |
| 触发测试 | `skill models list` | 显示当前模型列表 |
| 配置文件 | `ls ~/.openclaw/openclaw.json` | 文件存在 |

### 更新技能

```bash
# 从 ClawHub 更新
openclaw skills update openclaw-model-manager

# 或手动覆盖 SKILL.md 后重启 Gateway
openclaw gateway restart
```

### 卸载技能

```bash
# 从 ClawHub 卸载
openclaw skills uninstall openclaw-model-manager

# 或手动删除目录
rm -rf ~/.openclaw/workspace/skills/openclaw-model-manager
```

---

## 配置文件

```
~/.openclaw/openclaw.json
```

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "provider/model-id",
        "fallbacks": ["provider/model-id"]
      }
    }
  }
}
```

fallbacks 按顺序尝试：primary 失败 → fallbacks[0] → fallbacks[1] → ...

---

## 核心原则

- **用户指定的 primary 就是 primary，不做阻拦**
- **fallbacks 中不能包含 primary**（自动过滤，不询问）
- **自动选择 fallback 时，优先选与 primary 不同类型的**（本地↔云端互补）
- **所有修改一次性写回，不依赖 `openclaw models set` 的副作用**

---

## `skill models set` 完整实现逻辑

### 流程总览

```
输入: skill models set <模型> [fallback <模型>,<模型>...]
  ↓
① 解析输入（序号→完整ID，校验存在性）
  ↓
② 读取当前配置 + 保存备份
  ↓
③ 构建新配置（primary + fallbacks）
  ↓
④ 一次性写回 openclaw.json
  ↓
⑤ 切换当前 Session (/model)
  ↓
⑥ 验证结果，失败则回滚
```

### ① 解析输入

```
输入: skill models set <主模型> [fallback <兜底列表>]

主模型解析:
  纯数字（如 "2"）     → openclaw models list 按序号映射
  包含 "/"（如 "bailian/qwen3.5-plus"）→ 直接使用

Fallback 解析（可选）:
  不指定              → 进入自动选择逻辑
  "fallback 3"        → 按序号映射
  "fallback bailian/glm-5"  → 直接使用
  "fallback 3,5"      → 逗号分隔，逐个映射

校验:
  - 主模型必须在配置中存在 → 否则报错，列出可用模型
  - Fallback 每个都必须在配置中存在 → 否则报错
```

### ② 读取当前配置

```python
读取 openclaw.json:
  current_primary = agents.defaults.model.primary
  current_fallbacks = agents.defaults.model.fallbacks   # 有序数组
  all_models = list(agents.defaults.models.keys())      # 有序列表

保存备份（用于回滚）:
  backup = {
    "primary": current_primary,
    "fallbacks": list(current_fallbacks)
  }
```

### ③ 构建新配置

```
new_primary = 用户指定的主模型

─────────────────────────────────────
情况 A: 用户指定了 fallback
─────────────────────────────────────

  new_fallbacks = 用户指定的列表

  # 自动过滤掉 primary（不询问）
  new_fallbacks = [f for f in new_fallbacks if f != new_primary]

  # 去重（保持顺序）
  seen = set()
  new_fallbacks = [f for f in new_fallbacks if not (f in seen or seen.add(f))]

  # 过滤后为空 → 提示
  if not new_fallbacks:
    提示: "已过滤掉与 primary 相同的 fallback，当前无兜底，建议添加"

─────────────────────────────────────
情况 B: 用户未指定 fallback（自动选择）
─────────────────────────────────────

  remaining = [m for m in all_models if m != new_primary]

  if len(remaining) == 0:
    # 只配置了 1 个模型
    new_fallbacks = []
    提示: "只有 1 个模型，无兜底，建议添加"

  else:
    # 优先保留原有 fallback（排除已变成 primary 的）
    preserved = [f for f in current_fallbacks if f in remaining]

    if preserved:
      # 原有 fallback 仍然有效，保持不动
      new_fallbacks = preserved

    else:
      # 原有 fallback 无效，重新选择
      # 优先选与 new_primary 不同类型的
      primary_is_local = new_primary.startswith("custom-")
      local_models = [m for m in remaining if m.startswith("custom-")]
      cloud_models = [m for m in remaining if not m.startswith("custom-")]

      if primary_is_local and cloud_models:
        new_fallbacks = [cloud_models[0]]
      elif not primary_is_local and local_models:
        new_fallbacks = [local_models[0]]
      elif remaining:
        # 没有不同类型，选第一个
        new_fallbacks = [remaining[0]]
```

### ④ 一次性写回

```python
# 不依赖 openclaw models set 的副作用
# 直接修改配置后一次性写回

import json
config = json.loads(open(config_path).read())
config["agents"]["defaults"]["model"]["primary"] = new_primary
config["agents"]["defaults"]["model"]["fallbacks"] = new_fallbacks
json.dump(config, open(config_path, "w"), indent=2, ensure_ascii=False)
```

### ⑤ 切换当前 Session

```
/model <new_primary>
```

### ⑥ 验证

```
执行: session_status
检查: model 字段 == new_primary

如果不同:
  1. 重试 /model <new_primary>
  2. 再检查 session_status
  3. 仍不同 → 回滚配置:
     恢复 backup.primary 和 backup.fallbacks
     提示: "切换失败，已回滚到原配置"
```

---

## `skill models delete` 完整实现逻辑

### 流程

```
输入: skill models delete <序号/模型名>
  ↓
① 解析要删除的模型
  ↓
② 安全检查
  ↓
③ 处理影响（更新 primary / fallbacks）
  ↓
④ 一次性写回
  ↓
⑤ 如果删除了当前主模型 → 切换 Session 到新主模型
```

### ② 安全检查

```python
target = 要删除的模型
all_models = list(agents.defaults.models.keys())

# 只剩 1 个模型
if len(all_models) <= 1:
    警告: "删除后没有可用模型"
    请求用户确认
```

### ③ 处理影响

```
remaining = [m for m in all_models if m != target]

─────────────────────────────────────
情况 A: 删除的是主模型
─────────────────────────────────────

  # 新主模型：优先选原有 fallback 的第一个
  if current_fallbacks:
    valid_fallbacks = [f for f in current_fallbacks if f != target]
    if valid_fallbacks:
      new_primary = valid_fallbacks[0]
    else:
      new_primary = _select_new_primary(remaining, target)
  else:
    new_primary = _select_new_primary(remaining, target)

  # 新 fallback：从剩余中选（排除新 primary）
  remaining_for_fb = [m for m in remaining if m != new_primary]
  new_fallbacks = _select_fallbacks(remaining_for_fb, new_primary, current_fallbacks)

─────────────────────────────────────
情况 B: 删除的是 fallback
─────────────────────────────────────

  new_primary = current_primary  # 主模型不变

  # 从 fallback 列表中移除
  new_fallbacks = [f for f in current_fallbacks if f != target]

  # 如果 fallback 为空且还有其他模型，自动补一个
  if not new_fallbacks and len(remaining) > 1:
    remaining_for_fb = [m for m in remaining if m != new_primary]
    new_fallbacks = _select_fallbacks(remaining_for_fb, new_primary, [])

─────────────────────────────────────
情况 C: 既不是主模型也不是 fallback
─────────────────────────────────────

  new_primary = current_primary
  new_fallbacks = list(current_fallbacks)  # 不变
```

### 辅助函数

```python
def _select_new_primary(remaining, old_primary):
    """从剩余模型中选新主模型"""
    old_is_local = old_primary.startswith("custom-")

    # 优先选不同类型的
    local = [m for m in remaining if m.startswith("custom-")]
    cloud = [m for m in remaining if not m.startswith("custom-")]

    if old_is_local and cloud:
        return cloud[0]
    elif not old_is_local and local:
        return local[0]
    elif remaining:
        return remaining[0]

def _select_fallbacks(remaining, primary, old_fallbacks):
    """从剩余中选 fallback（保持原有顺序优先）"""
    if not remaining:
        return []

    # 优先保留原有 fallback
    preserved = [f for f in old_fallbacks if f in remaining]
    if preserved:
        return preserved

    # 否则选不同类型的
    primary_is_local = primary.startswith("custom-")
    local = [m for m in remaining if m.startswith("custom-")]
    cloud = [m for m in remaining if not m.startswith("custom-")]

    if primary_is_local and cloud:
        return [cloud[0]]
    elif not primary_is_local and local:
        return [local[0]]
    elif remaining:
        return [remaining[0]]
    return []
```

### ④ 一次性写回

```python
config = json.loads(open(config_path).read())
config["agents"]["defaults"]["model"]["primary"] = new_primary
config["agents"]["defaults"]["model"]["fallbacks"] = new_fallbacks
del config["agents"]["defaults"]["models"][target]
json.dump(config, open(config_path, "w"), indent=2, ensure_ascii=False)
```

### ⑤ 切换 Session（如果需要）

```
if target == old_primary:
    /model <new_primary>
    session_status 验证
```

---

## 错误处理

| 错误 | 处理 |
|------|------|
| 模型不存在 | 报错，列出可用模型 |
| 一次性写回失败 | 报错，不执行任何修改 |
| `/model` 切换后未生效 | 重试一次，仍失败提示重启 Gateway |
| 切换后新模型不可用 | 回滚到备份配置 |
| 401/403 API Key 问题 | 提示检查 provider 的 apiKey |
| 本地模型离线 | 提示启动 MLX 服务或切换到云端 |

---

## 独立用法（不推荐，仅供手动操作参考）

```
# 只改配置（不影响当前 Session）
openclaw models set <模型ID>

# 只改当前 Session（不持久化）
/model <模型ID>
```
