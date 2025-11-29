param(
    [string]$BucketDir = "$PSScriptRoot/../bucket",
    [switch]$Commit,
    [switch]$Push,
    [switch]$DryRun
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "SUCCESS") { "Green" } elseif ($Level -eq "WARN") { "Yellow" } else { "White" }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

# 检查环境
Write-Log "检查环境..."
if (-not (Test-Path $BucketDir)) {
    Write-Log "Bucket 目录不存在: $BucketDir" ERROR
    exit 1
}

$scoopHome = scoop prefix scoop
$checkVerScript = "$scoopHome/bin/checkver.ps1"

if (-not (Test-Path $checkVerScript)) {
    Write-Log "Scoop checkver 脚本不存在" ERROR
    exit 1
}

# 检查 git 状态
Set-Location "$PSScriptRoot/.."
$gitStatus = git status --porcelain 2>$null
if ($gitStatus -and -not $DryRun) {
    Write-Log "工作目录有未提交的更改，请先处理" WARN
    exit 1
}

Write-Log "环境检查通过" SUCCESS

# 备份当前状态
if (-not $DryRun) {
    Write-Log "备份当前状态..."
    git stash push -m "auto-update-backup" 2>$null
}

try {
    Write-Log "开始更新应用版本..."

    # 运行 Scoop checkver
    if ($DryRun) {
        Write-Log "DRY RUN: 仅检查更新" WARN
        & $checkVerScript -Dir $BucketDir -Verbose
    } else {
        Write-Log "正在检查并更新应用..." INFO
        & $checkVerScript -Dir $BucketDir -Update -Verbose
    }

    # 检查是否有更改
    $changedFiles = git status --porcelain 2>$null
    if ($changedFiles) {
        Write-Log "检测到文件更改" SUCCESS

        if ($Commit -and -not $DryRun) {
            Write-Log "提交更改..."
            git add bucket/

            # 生成提交信息
            $apps = @()
            $changedFiles | ForEach-Object {
                if ($_ -match "bucket/(.+?)\.json") {
                    $apps += $Matches[1]
                }
            }
            $appList = $apps -join ", "
            $commitMessage = "chore(autoupdate): update apps ($appList)"

            git commit -m $commitMessage
            Write-Log "提交成功: $commitMessage" SUCCESS

            if ($Push) {
                Write-Log "推送到远程仓库..."
                git push origin main
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "推送成功" SUCCESS
                } else {
                    Write-Log "推送失败" ERROR
                }
            }
        } else {
            Write-Log "使用 -Commit 参数提交更改" INFO
        }
    } else {
        Write-Log "没有检测到文件更改，所有应用都是最新版本" INFO
    }

} catch {
    Write-Log "更新过程中出错: $($_.Exception.Message)" ERROR
} finally {
    # 恢复备份（如果有）
    if (-not $DryRun -and -not $Commit) {
        Write-Log "恢复备份状态..."
        git stash pop 2>$null
    }
}

Write-Log "自动更新完成" SUCCESS