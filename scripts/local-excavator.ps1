#!/usr/bin/env pwsh
<#
.SYNOPSIS
    本地版本的 Excavator - 自动检查和更新 bucket 中的应用版本
.DESCRIPTION
    模拟 GitHub Actions Excavator 的功能，在本地环境中自动检查应用更新并生成 PR
.PARAMETER BucketDir
    Bucket 目录路径，默认为当前目录下的 bucket 文件夹
.PARAMETER Update
    是否自动更新清单文件
.PARAMETER Commit
    是否提交更改
.PARAMETER Push
    是否推送到远程仓库
.PARAMETER DryRun
    仅检查更新，不执行实际操作
.EXAMPLE
    .\scripts\local-excavator.ps1 -DryRun
    仅检查更新，不修改文件
.EXAMPLE
    .\scripts\local-excavator.ps1 -Update -Commit
    检查更新、修改文件并提交
#>

param(
    [string]$BucketDir = "$PSScriptRoot/../bucket",
    [switch]$Update,
    [switch]$Commit,
    [switch]$Push,
    [switch]$DryRun,
    [switch]$Verbose
)

# 导入 Scoop 工具
$ScoopHome = scoop prefix scoop
$CheckVerScript = "$ScoopHome/bin/checkver.ps1"
$AutoPrScript = "$ScoopHome/bin/auto-pr.ps1"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "检查前置条件..."

    if (-not (Test-Path $BucketDir)) {
        Write-Log "Bucket 目录不存在: $BucketDir" ERROR
        return $false
    }

    if (-not (Test-Path $CheckVerScript)) {
        Write-Log "Scoop checkver 脚本不存在: $CheckVerScript" ERROR
        return $false
    }

    # 检查 git 状态
    Set-Location $PSScriptRoot/..
    $gitStatus = git status --porcelain
    if ($gitStatus -and -not $DryRun) {
        Write-Log "工作目录有未提交的更改，请先提交或暂存" ERROR
        return $false
    }

    Write-Log "前置条件检查通过" SUCCESS
    return $true
}

function Get-AppManifests {
    param([string]$Directory)

    Write-Log "扫描应用清单文件..."
    $manifests = Get-ChildItem -Path $Directory -Filter "*.json" | Where-Object {
        $_.Name -ne "claude.json" -and $_.Name -notlike "*.template*"
    }

    Write-Log "发现 $($manifests.Count) 个应用清单" SUCCESS
    return $manifests
}

function Check-AppUpdates {
    param(
        [array]$Manifests,
        [string]$BucketDirectory
    )

    Write-Log "开始检查应用更新..."
    $updates = @()

    foreach ($manifest in $Manifests) {
        $appName = $manifest.BaseName
        Write-Log "检查 $appName..." -Level "INFO"

        try {
            if ($DryRun) {
                # 仅检查版本，不更新文件
                $result = & $CheckVerScript -App $appName -Dir $BucketDirectory -Verbose:$Verbose
            } else {
                # 检查并更新
                $result = & $CheckVerScript -App $appName -Dir $BucketDirectory -Update -Verbose:$Verbose
            }

            if ($LASTEXITCODE -eq 0 -and $result -match "(?:New version|Updated)") {
                $updates += @{
                    Name = $appName
                    File = $manifest.FullName
                    Status = "Updated"
                }
                Write-Log "$appName 有更新" SUCCESS
            } elseif ($Verbose) {
                Write-Log "$appName 无更新"
            }
        } catch {
            Write-Log "检查 $appName 时出错: $($_.Exception.Message)" ERROR
        }
    }

    return $updates
}

function New-CommitChanges {
    param([array]$Updates)

    if ($Updates.Count -eq 0) {
        Write-Log "没有需要提交的更新"
        return
    }

    Write-Log "提交更新更改..."

    # 添加更新的文件
    foreach ($update in $Updates) {
        git add "$($update.File)"
    }

    # 创建提交
    $appNames = $Updates | ForEach-Object { $_.Name } | Join-String -Separator ", "
    $commitMessage = "chore(autoupdate): update apps ($appNames)"

    git commit -m $commitMessage

    if ($LASTEXITCODE -eq 0) {
        Write-Log "提交成功" SUCCESS
    } else {
        Write-Log "提交失败" ERROR
    }
}

function Push-Changes {
    Write-Log "推送到远程仓库..."

    git push origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Log "推送成功" SUCCESS
    } else {
        Write-Log "推送失败" ERROR
    }
}

# 主执行逻辑
function Main {
    Write-Log "本地 Excavator 启动" SUCCESS
    Write-Log "Bucket 目录: $BucketDir"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    $manifests = Get-AppManifests -Directory $BucketDir
    $updates = Check-AppUpdates -Manifests $manifests -BucketDirectory $BucketDir

    Write-Log "检查完成，发现 $($updates.Count) 个更新" SUCCESS

    if ($updates.Count -gt 0) {
        Write-Log "更新的应用:"
        $updates | ForEach-Object { Write-Log "  - $($_.Name)" }

        if ($Update -and -not $DryRun) {
            if ($Commit) {
                New-CommitChanges -Updates $updates
                if ($Push) {
                    Push-Changes
                }
            }
        }
    } else {
        Write-Log "所有应用都是最新版本"
    }

    Write-Log "本地 Excavator 完成" SUCCESS
}

# 执行主函数
Main