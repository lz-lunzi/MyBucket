$BucketDir = "$PSScriptRoot/../bucket"
$DryRun = $args -contains "-DryRun"

Write-Host "=== Bucket 自动更新工具 ===" -ForegroundColor Green

# 检查环境
if (-not (Test-Path $BucketDir)) {
    Write-Host "错误: Bucket 目录不存在" -ForegroundColor Red
    exit 1
}

$scoopHome = scoop prefix scoop
$checkVerScript = "$scoopHome/bin/checkver.ps1"

if (-not (Test-Path $checkVerScript)) {
    Write-Host "错误: Scoop checkver 脚本不存在" -ForegroundColor Red
    exit 1
}

Write-Host "Bucket 目录: $BucketDir"
if ($DryRun) { Write-Host "模式: 仅检查" -ForegroundColor Yellow }

# 切换到项目根目录
Set-Location "$PSScriptRoot/.."

# 运行更新
Write-Host "开始检查更新..." -ForegroundColor Cyan
try {
    if ($DryRun) {
        & $checkVerScript -Dir $BucketDir -Verbose
    } else {
        & $checkVerScript -Dir $BucketDir -Update -Verbose
    }
} catch {
    Write-Host "检查更新时出错: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查结果
$changedFiles = git status --porcelain 2>$null
if ($changedFiles) {
    Write-Host "发现更新!" -ForegroundColor Green
    Write-Host "更改的文件:"
    $changedFiles | ForEach-Object { Write-Host "  $_" }

    if ($args -contains "-Commit" -and -not $DryRun) {
        Write-Host "提交更改..." -ForegroundColor Cyan
        git add bucket/
        git commit -m "chore(autoupdate): update apps"
        Write-Host "提交完成" -ForegroundColor Green

        if ($args -contains "-Push") {
            Write-Host "推送到远程..." -ForegroundColor Cyan
            git push origin main
            if ($LASTEXITCODE -eq 0) {
                Write-Host "推送成功" -ForegroundColor Green
            } else {
                Write-Host "推送失败" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "使用 -Commit 参数提交更改" -ForegroundColor Yellow
    }
} else {
    Write-Host "没有发现更新，所有应用都是最新版本" -ForegroundColor Green
}

Write-Host "=== 完成 ===" -ForegroundColor Green