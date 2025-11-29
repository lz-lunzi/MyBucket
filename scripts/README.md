# 本地 Excavator 使用指南

这个目录包含了将 GitHub Actions Excavator 工作流移植到本地运行的解决方案。

## 🚀 快速开始

### 方法1: PowerShell 版本（推荐）

```powershell
# 仅检查更新（不修改文件）
.\scripts\local-excavator.ps1 -DryRun

# 检查并更新文件
.\scripts\local-excavator.ps1 -Update

# 检查、更新并提交
.\scripts\local-excavator.ps1 -Update -Commit

# 完整流程：检查、更新、提交并推送
.\scripts\local-excavator.ps1 -Update -Commit -Push
```

### 方法2: 批处理版本（简化）

```batch
# 一键执行：检查、更新、提交、推送
.\scripts\local-excavator.bat
```

### 方法3: 直接使用 Scoop 工具

```powershell
# 检查所有应用更新
& "$(scoop prefix scoop)/bin/checkver.ps1" -Dir bucket

# 检查并更新
& "$(scoop prefix scoop)/bin/checkver.ps1" -Dir bucket -Update
```

## ⏰ 定时任务设置

### 使用 PowerShell 脚本设置

```powershell
# 创建每4小时运行一次的定时任务
.\scripts\schedule-excavator.ps1 -Interval 4 -Enable

# 查看任务状态
.\scripts\schedule-excavator.ps1 -List

# 禁用任务
.\scripts\schedule-excavator.ps1 -Disable

# 删除任务
.\scripts\schedule-excavator.ps1 -Remove
```

### 手动设置 Windows 定时任务

1. 打开"任务计划程序"
2. 创建基本任务
3. 触发器：每4小时
4. 操作：启动程序
   - 程序：`pwsh.exe`
   - 参数：`-File "E:\CloudStorage\Code\MyBucket\scripts\local-excavator.ps1" -Update -Commit -Push`
   - 起始于：`E:\CloudStorage\Code\MyBucket`

## 📋 功能对比

| 功能 | GitHub Actions | 本地 PowerShell | 本地批处理 |
|------|---------------|----------------|-----------|
| 自动检查更新 | ✅ | ✅ | ✅ |
| 自动更新版本 | ✅ | ✅ | ✅ |
| 自动提交 | ✅ | ✅ | ✅ |
| 自动推送 | ✅ | ✅ | ✅ |
| 定时执行 | ✅ | ✅ | ✅ |
| 错误处理 | ✅ | ✅ | ⚠️ |
| 详细日志 | ✅ | ✅ | ⚠️ |
| 通知机制 | ✅ | ⚠️ | ❌ |

## 🔧 配置选项

### local-excavator.ps1 参数

- `-BucketDir`: Bucket 目录路径
- `-Update`: 是否自动更新清单文件
- `-Commit`: 是否提交更改
- `-Push`: 是否推送到远程仓库
- `-DryRun`: 仅检查，不执行实际操作
- `-Verbose`: 显示详细输出

### schedule-excavator.ps1 参数

- `-Interval`: 检查间隔（小时），默认4小时
- `-Enable`: 启用定时任务
- `-Disable`: 禁用定时任务
- `-Remove`: 删除定时任务
- `-List`: 查看任务状态

## 🛠️ 故障排除

### 权限问题
```powershell
# 设置 PowerShell 执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Git 配置
```powershell
# 确保已配置 Git 用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Scoop 工具问题
```powershell
# 重新安装 Scoop
scoop uninstall scoop
scoop install scoop

# 确保 Scoop 工具可用
scoop prefix scoop
```

## 📈 监控和日志

### 查看执行日志
```powershell
# PowerShell 版本会输出彩色日志
.\scripts\local-excavator.ps1 -Verbose

# 批处理版本输出简单日志
.\scripts\local-excavator.bat
```

### Git 历史查看
```bash
# 查看自动提交记录
git log --oneline --grep="autoupdate"

# 查看最近更改
git log --oneline -10
```

## 🔄 迁移建议

1. **测试阶段**：先使用 `-DryRun` 参数测试
2. **逐步迁移**：保留 GitHub Actions 作为备份
3. **监控对比**：同时运行一段时间，对比效果
4. **完全切换**：确认稳定后禁用 GitHub Actions

## 🎯 最佳实践

1. **定期检查**：建议每周手动运行一次完整检查
2. **备份策略**：重要更新前先备份仓库
3. **通知设置**：可配置邮件或 Webhook 通知
4. **性能优化**：避免在高峰时段运行大量更新

## 📞 支持

如果遇到问题，请检查：
1. Scoop 是否正确安装
2. Git 配置是否正确
3. 网络连接是否正常
4. 权限设置是否足够