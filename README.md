# OpenClaw Model Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-Skill-blue)](https://docs.openclaw.ai)

OpenClaw 模型配置管理技能，用于统一维护 `openclaw.json` 中的模型与 provider 配置。支持查看、切换、检测、添加、删除模型，自动选择兜底模型，修复配置错误。

## 功能

| 功能 | 说明 |
|------|------|
| 📋 模型列表 | 查看已配置模型（序号、选中状态、连接状态） |
| 🔄 切换模型 | 切换主模型，自动管理兜底链 |
| 🏓 连通检测 | 每个模型 3 次测试，间隔 3 秒，输出延迟 |
| ➕ 添加模型 | 添加新 provider 和模型配置 |
| 🗑️ 删除模型 | 安全删除，自动处理影响面 |
| 🔧 配置修复 | 自动检测并修复配置错误 |

## 安装

### 方式一：ClawHub（推荐）

```bash
openclaw skills install openclaw-model-manager
```

### 方式二：手动克隆

```bash
git clone https://github.com/yikexiaoyao/openclaw-model-manager.git <skills-dir>/openclaw-model-manager
```

### 方式三：直接下载

下载 `SKILL.md` 和 `scripts/check-models.sh` 到 skills 目录：

```bash
mkdir -p <skills-dir>/openclaw-model-manager/scripts
curl -o <skills-dir>/openclaw-model-manager/SKILL.md https://raw.githubusercontent.com/yikexiaoyao/openclaw-model-manager/main/SKILL.md
curl -o <skills-dir>/openclaw-model-manager/scripts/check-models.sh https://raw.githubusercontent.com/yikexiaoyao/openclaw-model-manager/main/scripts/check-models.sh
chmod +x <skills-dir>/openclaw-model-manager/scripts/check-models.sh
```

## 依赖

- **OpenClaw** ≥ 2026.4.0
- **Python** ≥ 3.8（连通性检测脚本）
- **curl**（连通性检测脚本）

## 命令列表

### 查看

| 命令 | 说明 | 示例 |
|------|------|------|
| `skill models list` | 查看已配置模型列表 | 显示序号、状态、延迟 |
| `skill models status` | 查看当前主/备用模型 | 显示配置摘要 |
| `skill models check` | 连通性检测 | 3 次测试/模型，间隔 3 秒 |
| `skill models test` | 发送测试请求 | 验证模型响应 |

### 切换

| 命令 | 说明 | 示例 |
|------|------|------|
| `skill models set 2` | 按序号切换 | 切换到列表第 2 个模型 |
| `skill models set bailian/qwen3.5-plus` | 按名称切换 | 直接指定模型 ID |
| `skill models set 2 fallback 1` | 切换 + 兜底 | 主模型 + 兜底模型 |
| `skill models set 2 fallback 1,3` | 切换 + 多个兜底 | 链式兜底 |

### 管理

| 命令 | 说明 |
|------|------|
| `skill models add <模型名>` | 添加新模型配置 |
| `skill models delete <序号/模型名>` | 删除模型配置 |
| `skill models update <序号> <参数> <值>` | 更新模型参数 |
| `skill models fix` | 自动检测并修复配置错误 |
| `skill models help` | 显示帮助信息 |

## 连通性检测

`skill models check` 会对每个已配置模型执行 3 次连通性测试（间隔 3 秒）。

### 输出示例

```
模型连通性检测 (3次测试，间隔3秒)
============================================================
  1. ✅ local/qwen3.5-9b (280ms) [备用]
  2. ✅ bailian/qwen3.6-plus (4691ms) [当前]
  3. ✅ bailian/glm-4.7 (3527ms)
  4. ❌ bailian/glm-5 (timeout)
```

### 状态说明

| 符号 | 含义 |
|------|------|
| ✅ | 3/3 测试成功（稳定） |
| ⚠️ | 2/3 测试成功（不稳定） |
| ❌ | 0-1/3 测试成功（不可用） |

### 错误码

| 错误码 | 含义 |
|--------|------|
| 200 | 正常 |
| 401/403 | API Key 无效 |
| 429 | 请求频率过高 |
| timeout | 连接超时 |
| 000 | 无法连接 |

## 兜底模型策略

切换模型时，如未指定 fallback：

1. **自动过滤**：从 fallback 列表中移除与 primary 相同的模型
2. **优先保留**：保留原有有效的 fallback
3. **类型互补**：本地模型 ↔ 云端模型互相兜底
4. **顺序选择**：无互补类型时，选列表第一个

## 常见问题

### 检测脚本报错

- 确认 Python ≥ 3.8：`python3 --version`
- 确认 curl 已安装：`curl --version`
- 确认配置文件存在：`~/.openclaw/openclaw.json`

### 切换后未生效

- 检查 `session_status` 确认当前模型
- 必要时重启 Gateway：`openclaw gateway restart`

### 401/403 错误

- 检查 provider 的 `apiKey` 是否有效
- 检查 `baseUrl` 是否正确

## 贡献

欢迎提交 Issue 和 PR！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 提交 Pull Request

## License

MIT
