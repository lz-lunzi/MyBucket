# MyBucket - Scoop Bucket 项目

## 项目概述

这是一个用于 [Scoop](https://scoop.sh) 的自定义 Bucket（软件包仓库），用于在 Windows 上通过命令行安装和管理各种应用程序。

### 主要特性

- **自动化版本更新**：通过 GitHub Actions 每 5 天自动检查新版本并创建 PR
- **自动测试**：支持 PowerShell 和 PowerShell Core 的自动化测试
- **多架构支持**：支持 x64、x86 和 ARM64 架构的应用程序

### 项目结构

```
MyBucket/
├── bucket/              # 应用程序清单文件（.json）
├── bin/                 # 辅助脚本（版本检查、测试等）
├── .github/
│   └── workflows/       # CI/CD 配置
├── deprecated/          # 已弃用的应用清单
└── README.md            # 项目说明文档
```

## 构建和运行

### 本地测试

```powershell
# 测试所有清单文件
.\bin\test.ps1

# 检查版本更新
.\bin\checkver.ps1

# 检查特定应用的版本
.\bin\checkver.ps1 app-name

# 自动创建 PR（需要配置 GitHub token）
.\bin\auto-pr.ps1
```

### 安装 Bucket

```powershell
# 添加此 Bucket
scoop bucket add MyBucket https://github.com/lz-lunzi/MyBucket

# 安装应用
scoop install MyBucket/<manifestname>

# 检查更新
scoop checkver MyBucket/*
```

## 开发约定

### 清单文件规范

每个应用程序清单（`bucket/*.json`）必须包含以下字段：

**必需字段：**
- `version`: 应用版本
- `description`: 应用描述
- `homepage`: 应用主页
- `license`: 许可证信息
- `url`: 下载链接
- `hash`: 文件哈希值（SHA256）

**自动更新支持：**
- `checkver`: 版本检查配置
- `autoupdate`: 自动更新配置

### 清单模板

使用 `bucket/app-name.json.template` 作为新清单的模板。

**Checkver 配置示例：**
```json
"checkver": {
    "github": "https://github.com/user/repo"
}
```

或使用自定义 URL：
```json
"checkver": {
    "url": "https://example.com",
    "regex": "version ([\\d.]+)"
}
```

### GitHub Actions

- **CI 测试**：在 push 和 PR 时运行，验证清单文件格式
- **Excavator**：每 5 天自动运行，检查版本更新并创建 PR

### 贡献流程

1. 复制 `bucket/app-name.json.template` 创建新清单
2. 填写必需字段
3. 添加 `checkver` 和 `autoupdate` 配置
4. 运行 `.\bin\test.ps1` 验证
5. 提交并创建 PR

## 工具脚本说明

| 脚本 | 功能 |
|------|------|
| `bin/test.ps1` | 测试所有清单文件的格式和有效性 |
| `bin/checkver.ps1` | 检查应用是否有新版本 |
| `bin/checkhashes.ps1` | 验证下载文件的哈希值 |
| `bin/checkurls.ps1` | 检查下载链接是否有效 |
| `bin/auto-pr.ps1` | 自动创建版本更新 PR |
| `bin/formatjson.ps1` | 格式化 JSON 文件 |
| `bin/missing-checkver.ps1` | 检查缺少 checkver 的清单 |

## 参考资源

- [Scoop 官方文档](https://github.com/ScoopInstaller/Scoop)
- [Scoop Wiki - App Manifests](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests)
- [Scoop Wiki - Checkver](https://github.com/ScoopInstaller/Scoop/wiki/Checkver)
- [贡献指南](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md)