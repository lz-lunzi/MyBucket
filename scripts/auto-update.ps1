#!/usr/bin/env pwsh
<#
.SYNOPSIS
    自动更新 bucket 中所有应用的版本信息
.DESCRIPTION
    使用 Scoop 的 checkver 工具自动检查并更新应用的版本号、下载链接和哈希值
.PARAMETER BucketDir
    Bucket 目录路径
.PARAMETER Commit
    是否自动提交更改
.PARAMETER Push
    是否推送到远程仓库
.PARAMETER DryRun
    仅检查更新，不修改文件
.EXAMPLE
    .\auto-update.ps1 -DryRun
    仅检查更新
.EXAMPLE
    .\auto-update.ps1 -Commit -Push
    更新并提交推送
#>

param(
    [string]$BucketDir = "$PSScriptRoot/../bucket",
    [switch]$Commit,
    [switch]$Push,
    [switch]$DryRun
)

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

function Test-Environment {
    Write-Log "检查环境..."

    if (-not (Test-Path $BucketDir)) {
        Write-Log "Bucket 目录不存在: $BucketDir" ERROR
        return $false
    }

    # 检查 Scoop 工具
    $scoopHome = scoop prefix scoop
    $checkVerScript = "$scoopHome/bin/checkver.ps1"

    if (-not (Test-Path $checkVerScript)) {
        Write-Log "Scoop checkver 脚本不存在" ERROR
        return $false
    }

    # 检查 Git 状态
    Set-Location "$PSScriptRoot/.."
    $gitStatus = git status --porcelain 2>$null
    if ($gitStatus -and -not $DryRun) {
        Write-Log "工作目录有未提交的更改，请先处理" WARN
        return $false
    }

    Write-Log "环境检查通过" SUCCESS
    return $true
}

function Get-CurrentVersions {
    param([string]$Directory)

    Write-Log "获取当前版本信息..."
    $currentVersions = @{}

    Get-ChildItem -Path $Directory -Filter "*.json" | Where-Object {
        $_.Name -notlike "*.template*" -and $_.Name -ne "claude.json"
    } | ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $currentVersions[$_.BaseName] = @{
                Version = $content.version
                File = $_.FullName
            }
        } catch {
            Write-Log "读取 $($_.Name) 时出错: $($_.Exception.Message)" WARN
        }
    }

    Write-Log "找到 $($currentVersions.Count) 个应用" SUCCESS
    return $currentVersions
}

function Update-Applications {
    param(
        [hashtable]$CurrentVersions,
        [string]$Directory
    )

    Write-Log "开始更新应用版本..."

    $scoopHome = scoop prefix scoop
    $checkVerScript = "$scoopHome/bin/checkver.ps1"

    $updatedApps = @()
    $failedApps = @()

    try {
        if ($DryRun) {
            Write-Log "DRY RUN: 仅检查更新，不修改文件" WARN
            $result = & $checkVerScript -Dir $Directory -Verbose 2>&1
        } else {
            Write-Log "正在检查并更新应用..." INFO
            $result = & $checkVerScript -Dir $Directory -Update -Verbose 2>&1
        }

        # 分析结果
        $result | ForEach-Object {
            if ($_ -match "(.+?):\s+([\d.]+)\s+\(scoop version is ([\d.]+)\)") {
                $appName = $Matches[1]
                $newVersion = $Matches[2]
                $oldVersion = $Matches[3]

                if ($newVersion -ne $oldVersion) {
                    $updatedApps += @{
                        Name = $appName
                        OldVersion = $oldVersion
                        NewVersion = $newVersion
                    }
                    Write-Log "$appName: $oldVersion → $newVersion" SUCCESS
                }
            } elseif ($_ -match "Writing updated (.+) manifest") {
                $appName = $Matches[1]
                if ($updatedApps.Name -notcontains $appName) {
                    $updatedApps += @{
                        Name = $appName
                        Status = "Updated"
                        Message = "版本信息已更新"
                    }
                }
            } elseif ($_ -match "ERROR.*update (.+),") {
                $appName = $Matches[1]
                $failedApps += $appName
                Write-Log "$appName 更新失败" ERROR
            }
        }

    } catch {
        Write-Log "更新过程中出错: $($_.Exception.Message)" ERROR
    }

    return @{
        Updated = $updatedApps
        Failed = $failedApps
    }
}

function Commit-Changes {
    param([array]$UpdatedApps)

    if ($UpdatedApps.Count -eq 0) {
        Write-Log "没有需要提交的更改"
        return $false
    }

    Write-Log "提交更新更改..."

    # 检查实际修改的文件
    $changedFiles = git diff --name-only 2>$null
    if (-not $changedFiles) {
        Write-Log "没有检测到文件更改" WARN
        return $false
    }

    # 添加更改的文件
    git add bucket/

    # 生成提交信息
    $appList = $UpdatedApps | ForEach-Object {
        if ($_.OldVersion -and $_.NewVersion) {
            "$($_.Name) ($($_.OldVersion)→$($_.NewVersion))"
        } else {
            $_.Name
        }
    } | Join-String -Separator ", "

    $commitMessage = "chore(autoupdate): update apps ($appList)"

    # 提交
    git commit -m $commitMessage

    if ($LASTEXITCODE -eq 0) {
        Write-Log "提交成功: $commitMessage" SUCCESS
        return $true
    } else {
        Write-Log "提交失败" ERROR
        return $false
    }
}

function Push-Changes {
    Write-Log "推送到远程仓库..."

    git push origin main 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Log "推送成功" SUCCESS
        return $true
    } else {
        Write-Log "推送失败" ERROR
        return $false
    }
}

function Show-Summary {
    param(
        [array]$UpdatedApps,
        [array]$FailedApps
    )

    Write-Log "=== 更新汇总 ===" INFO

    if ($UpdatedApps.Count -gt 0) {
        Write-Log "✅ 成功更新的应用 ($($UpdatedApps.Count)):" SUCCESS
        $UpdatedApps | ForEach-Object {
            if ($_.OldVersion -and $_.NewVersion) {
                Write-Log "  • $($_.Name): $($_.OldVersion) → $($_.NewVersion)"
            } else {
                Write-Log "  • $($_.Name): 已更新"
            }
        }
    }

    if ($FailedApps.Count -gt 0) {
        Write-Log "❌ 更新失败的应用 ($($FailedApps.Count)):" ERROR
        $FailedApps | ForEach-Object {
            Write-Log "  • $_"
        }
    }

    if ($UpdatedApps.Count -eq 0 -and $FailedApps.Count -eq 0) {
        Write-Log "📋 所有应用都是最新版本" INFO
    }
}

# 主程序
function Main {
    Write-Log "=== Bucket 自动更新工具启动 ===" SUCCESS
    Write-Log "Bucket 目录: $BucketDir"
    if ($DryRun) { Write-Log "模式: DRY RUN (仅检查)" WARN }

    if (-not (Test-Environment)) {
        exit 1
    }

    $currentVersions = Get-CurrentVersions -Directory $BucketDir
    $updateResult = Update-Applications -CurrentVersions $currentVersions -Directory $BucketDir

    Show-Summary -UpdatedApps $updateResult.Updated -FailedApps $updateResult.Failed

    if ($updateResult.Updated.Count -gt 0 -and -not $DryRun) {
        if ($Commit) {
            $commitSuccess = Commit-Changes -UpdatedApps $updateResult.Updated
            if ($commitSuccess -and $Push) {
                Push-Changes
            }
        } else {
            Write-Log "使用 -Commit 参数提交更改" INFO
        }
    }

    Write-Log "=== 自动更新完成 ===" SUCCESS
}

# 执行主函数
Main