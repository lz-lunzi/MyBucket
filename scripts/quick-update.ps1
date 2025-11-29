#!/usr/bin/env pwsh

Write-Host "=== Bucket Quick Update ===" -ForegroundColor Green

$BucketDir = "$PSScriptRoot/../bucket"
$ScoopHome = scoop prefix scoop
$CheckVerScript = "$ScoopHome/bin/checkver.ps1"

Write-Host "Bucket directory: $BucketDir"
Write-Host "Scoop checkver: $CheckVerScript"

# 检查环境
if (-not (Test-Path $BucketDir)) {
    Write-Host "ERROR: Bucket directory not found" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $CheckVerScript)) {
    Write-Host "ERROR: Scoop checkver script not found" -ForegroundColor Red
    exit 1
}

# 切换到项目根目录
Set-Location "$PSScriptRoot/.."

# 检查 git 状态
$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host "WARNING: Working directory has uncommitted changes" -ForegroundColor Yellow
}

# 运行更新
Write-Host "Updating app versions..." -ForegroundColor Cyan
try {
    & $CheckVerScript -Dir $BucketDir -Update
} catch {
    Write-Host "ERROR during update: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查结果
$changedFiles = git status --porcelain 2>$null
if ($changedFiles) {
    Write-Host "Updates found!" -ForegroundColor Green
    Write-Host "Changed files:"
    $changedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

    # 如果有参数 -commit，则提交更改
    if ($args -contains "-commit") {
        Write-Host "Committing changes..." -ForegroundColor Cyan
        git add bucket/
        $commitMessage = "chore(autoupdate): update apps ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        git commit -m $commitMessage

        if ($args -contains "-push") {
            Write-Host "Pushing to remote..." -ForegroundColor Cyan
            git push origin main
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Push successful!" -ForegroundColor Green
            } else {
                Write-Host "Push failed!" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Use -commit argument to commit changes" -ForegroundColor Yellow
    }
} else {
    Write-Host "No updates found, all apps are up to date" -ForegroundColor Green
}

Write-Host "=== Update Complete ===" -ForegroundColor Green