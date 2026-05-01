---
name: model-manager
description: OpenClaw 模型配置管理技能。用于添加、删除、更新、查看、切换、检测模型配置。当用户需要：(1) 添加新模型到配置 (2) 删除模型 (3) 更新模型参数（contextWindow、maxTokens 等）(4) 查看当前模型列表 (5) 切换主模型 (6) 检查模型可用状态（测试连接）(7) 修复模型配置问题时使用此技能。
metadata: {"openclaw": {"emoji": "🔧", "always": false, "requires": {"bins": ["python3", "curl"], "env": []}}}
---

# Model Manager

OpenClaw 模型配置管理技能，用于统一维护 `openclaw.json` 中的模型与 provider 配置。

## 配置文件位置

```
~/.openclaw/openclaw.json
```

## 命令列表

| 命令 | 用途 |
|------|------|
| `skill models list` | 查看已配置模型列表（带序号、选中状态、连接状态） |
| `skill models set <序号/模型名>` | 切换主模型 |
| `skill models set <序号/模型名> fallback <序号/模型名>` | 切换主模型并指定兜底 |
| `skill models set <序号/模型名> fallback <序号/模型名>,<序号/模型名>` | 切换主模型并指定多个兜底（链式） |
| `skill models status` | 查看主模型/备用模型/配置摘要 |
| `skill models check` | 检查模型连通性（测试连接） |
| `skill models test` | 发送测试请求验证响应 |
| `skill models add <模型名>` | 添加新模型配置 |
| `skill models delete <序号/模型名>` | 删除模型配置 |
| `skill models update <序号> <参数> <值>` | 更新模型参数 |
| `skill models fix` | 自动检测并修复配置错误 |
| `skill models help` | 显示帮助信息 |

---

## 快速开始

**触发方式**：用户发送以下命令时自动激活本技能

```skill models list        # 查看模型列表
skill models set 2     # 切换到第 2 个模型
skill models check     # 检测所有模型连通性
skill models help      # 显示帮助
```

**执行前必做**：
1. 读取 `openclaw.json` 确认配置结构
2. 写入操作前保存备份到 `openclaw.json.bak`
3. 修改后验证 `session_status` 确认生效

---

## 数据结构

```
agents.defaults.model:
  primary: "provider/model-id"           # 主模型
  fallbacks: ["provider/model-id", ...]   # 兜底链（有序数组，可为空）
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

## `skill models list` 实现逻辑

### 流程

```
① 读取 openclaw.json
  ↓
② 提取 models 列表（保持顺序）
  ↓
③ 获取 primary 和 fallbacks
  ↓
④ 遍历输出：序号 + 模型名 + 选中状态
```

### 输出格式

```
已配置模型列表：
1.  custom-127-0-0-1-8000/Qwen3.5-9B-MLX-4bit [当前]
2.  bailian/qwen3.6-plus
3.  bailian/qwen3.5-plus
4.  bailian/glm-4.7
```

### 状态标记

| 标记 | 含义 |
|------|------|
| `[当前]` | 当前主模型（primary） |
| `[备用]` | 当前备用模型（在 fallbacks 中） |

---

## `skill models check` 实现逻辑

### 流程

```
① 确认 check-models.sh 脚本存在（scripts/check-models.sh）
  ↓
② 执行脚本，传入 openclaw.json 路径
  ↓
③ 输出结果表格
```

### 脚本调用

```bash
bash <skill-dir>/scripts/check-models.sh
```

或带配置路径：

```bash
bash <skill-dir>/scripts/check-models.sh ~/.openclaw/openclaw.json
```

### 输出示例

```
模型连通性检测 (3次测试，间隔3秒)
============================================================
  1. ✅ local/qwen3.5-9b (280ms) [备用]
  2. ✅ bailian/qwen3.6-plus (4691ms) [当前]
  3. ⚠️ bailian/glm-4.7 (502 200 200) (2/3)
  4. ❌ bailian/glm-5 (timeout timeout timeout)
```

---

## `skill models status` 实现逻辑

### 流程

```
① 读取 openclaw.json
  ↓
② 提取 primary, fallbacks, models 数量
  ↓
③ 格式化输出摘要
```

### 输出示例

```
当前模型状态：
  主模型：bailian/qwen3.6-plus
  备用模型：custom-127-0-0-1-8000/Qwen3.5-9B-MLX-4bit
  已配置：4 个模型
  配置路径：~/.openclaw/openclaw.json
```

---

## `skill models add` 实现逻辑

### 流程

```
输入: skill models add <provider>/<model-id>
  ↓
① 解析模型 ID（provider 和 model-id）
  ↓
② 检查是否已存在 → 已存在则报错
  ↓
③ 查找或创建 provider 配置
  ↓
④ 添加到 models 列表
  ↓
⑤ 写回配置
```

### 新增 provider 模板

```json
{
  "providers": {
    "<provider>": {
      "baseUrl": "<api-base-url>",
      "apiKey": "<api-key>",
      "api": "openai-completions",
      "models": [{
        "id": "<model-id>",
        "name": "<model-name>",
        "contextWindow": 128000,
        "maxTokens": 8192,
        "input": ["text"],
        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
      }]
    }
  }
}
```

---

## `skill models update` 实现逻辑

### 流程

```
输入: skill models update <序号> <参数> <值>
  ↓
① 序号 → 模型 ID
  ↓
② 解析参数和值
  ↓
③ 更新模型配置
  ↓
④ 写回
```

### 支持的参数

| 参数 | 类型 | 示例 |
|------|------|------|
| contextWindow | int | `32768` |
| maxTokens | int | `8192` |
| reasoning | bool | `true/false` |
| input | array | `text,image` |

---

## `skill models fix` 实现逻辑

### 检测项

```python
def check_config(cfg):
    issues = []
    
    # 1. primary 是否存在于 models 中
    primary = cfg["agents"]["defaults"]["model"]["primary"]
    models = cfg["agents"]["defaults"]["models"]
    if primary not in models:
        issues.append(f"主模型 {primary} 不存在于配置中")
    
    # 2. fallbacks 是否包含 primary
    fallbacks = cfg["agents"]["defaults"]["model"]["fallbacks"]
    if primary in fallbacks:
        issues.append("fallbacks 中包含 primary，已自动移除")
        fallbacks.remove(primary)
    
    # 3. fallback 是否存在
    for fb in list(fallbacks):
        if fb not in models:
            issues.append(f"备用模型 {fb} 不存在，已移除")
            fallbacks.remove(fb)
    
    # 4. provider baseUrl 是否配置
    providers = cfg.get("models", {}).get("providers", {})
    for model_key in models:
        provider_id = model_key.split("/")[0]
        if provider_id not in providers:
            issues.append(f"provider {provider_id} 未配置")
    
    return issues
```

---

## `skill models help` 实现逻辑

### 输出

```
模型配置管理 - 帮助

用法:
  skill models list                          - 查看模型列表
  skill models set <序号/名称>               - 切换主模型
  skill models set <序号> fallback <序号>    - 切换 + 兜底
  skill models status                        - 查看当前状态
  skill models check                         - 连通性检测
  skill models add <provider/model>          - 添加模型
  skill models delete <序号/名称>            - 删除模型
  skill models update <序号> <参数> <值>     - 更新参数
  skill models fix                           - 修复配置错误
  skill models help                          - 显示此帮助
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
