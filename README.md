# OpenClaw Model Manager Skill

OpenClaw 模型配置管理技能，用于统一维护 `openclaw.json` 中的模型与 provider 配置。

## 功能

- 查看已配置模型列表（带序号、选中状态、连接状态）
- 切换主模型和兜底模型
- 检查模型连通性（3次测试，间隔3秒）
- 添加、删除、更新模型配置
- 自动检测并修复配置错误

## 安装

```bash
# 通过 ClawHub 安装
openclaw skills install openclaw-model-manager

# 或手动克隆到 skills 目录
git clone https://github.com/yikexiaoyao/openclaw-model-manager.git <your-skills-dir>/openclaw-model-manager
```

## 命令列表

| 命令 | 用途 |
|------|------|
| `skill models list` | 查看已配置模型列表 |
| `skill models set <序号/模型名>` | 切换主模型 |
| `skill models set <序号/模型名> fallback <序号/模型名>` | 切换主模型并指定兜底 |
| `skill models status` | 查看主模型/备用模型/配置摘要 |
| `skill models check` | 检查模型连通性 |
| `skill models test` | 发送测试请求验证响应 |
| `skill models add <模型名>` | 添加新模型配置 |
| `skill models delete <序号/模型名>` | 删除模型配置 |
| `skill models update <序号> <参数> <值>` | 更新模型参数 |
| `skill models fix` | 自动检测并修复配置错误 |
| `skill models help` | 显示帮助信息 |

## 连通性检测

`skill models check` 会对每个已配置模型执行 3 次连通性测试（间隔 3 秒），输出：

```
模型连通性检测 (3次测试，间隔3秒)
============================================================
  1. ✅ local/qwen3.5-9b (280ms) [备用]
  2. ✅ bailian/qwen3.6-plus (4691ms) [当前]
  3. ✅ bailian/glm-4.7 (3527ms)
  ...
```

状态说明：
- ✅ 3/3 测试成功
- ⚠️ 2/3 测试成功
- ❌ 0-1/3 测试成功

## License

MIT
