#!/usr/bin/env pwsh

param(
    [string]$BucketDir = "$PSScriptRoot/../bucket",
    [switch]$DryRun = $true
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

    $scoopHome = scoop prefix scoop
    $checkVerScript = "$scoopHome/bin/checkver.ps1"

    if (-not (Test-Path $checkVerScript)) {
        Write-Log "Scoop checkver 脚本不存在: $checkVerScript" ERROR
        return $false
    }

    Write-Log "环境检查通过" SUCCESS
    return $true
}

function Check-Updates {
    Write-Log "开始检查更新..."

    $scoopHome = scoop prefix scoop
    $checkVerScript = "$scoopHome/bin/checkver.ps1"

    try {
        $result = & $checkVerScript -Dir $BucketDir -Verbose
        Write-Log "检查完成" SUCCESS
        return $result
    } catch {
        Write-Log "检查更新时出错: $($_.Exception.Message)" ERROR
        return $null
    }
}

# 主程序
Write-Log "本地 Excavator 测试启动" SUCCESS
Write-Log "Bucket 目录: $BucketDir"

if (-not (Test-Environment)) {
    exit 1
}

$updates = Check-Updates
if ($updates) {
    Write-Log "检查结果:"
    $updates
}

Write-Log "测试完成" SUCCESS