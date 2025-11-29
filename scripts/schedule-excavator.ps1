#!/usr/bin/env pwsh
<#
.SYNOPSIS
    设置本地 Excavator 定时任务
.DESCRIPTION
    创建 Windows 定时任务，定期运行本地 Excavator
.PARAMETER Interval
    检查间隔（小时），默认 4 小时
.PARAMETER Enable
    是否启用定时任务
.EXAMPLE
    .\scripts\schedule-excavator.ps1 -Interval 4 -Enable
    每 4 小时运行一次 Excavator
#>

param(
    [int]$Interval = 4,
    [switch]$Enable,
    [switch]$Disable,
    [switch]$List,
    [switch]$Remove
)

$TaskName = "MyBucket-Excavator"
$ScriptPath = "$PSScriptRoot/local-excavator.ps1"
$WorkingDirectory = "$PSScriptRoot/.."

function New-ScheduledTask {
    Write-Log "创建定时任务..." SUCCESS

    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $Interval)
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$ScriptPath`" -Update -Commit -Push" -WorkingDirectory $WorkingDirectory
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -Settings $settings -RunLevel Highest -Force

    Write-Log "定时任务创建成功，每 $Interval 小时运行一次" SUCCESS
}

function Enable-ScheduledTask {
    Write-Log "启用定时任务..." SUCCESS
    Start-ScheduledTask -TaskName $TaskName
    Write-Log "定时任务已启用" SUCCESS
}

function Disable-ScheduledTask {
    Write-Log "禁用定时任务..." SUCCESS
    Stop-ScheduledTask -TaskName $TaskName
    Write-Log "定时任务已禁用" SUCCESS
}

function Remove-ScheduledTask {
    Write-Log "删除定时任务..." SUCCESS
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Log "定时任务已删除" SUCCESS
}

function Get-ScheduledTaskStatus {
    Write-Log "定时任务状态:" INFO
    Get-ScheduledTask -TaskName $TaskName | Format-List TaskName, State, LastRunTime, NextRunTime
}

# 主逻辑
if ($List) {
    Get-ScheduledTaskStatus
} elseif ($Remove) {
    Remove-ScheduledTask
} elseif ($Disable) {
    Disable-ScheduledTask
} elseif ($Enable) {
    # 检查任务是否存在
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) {
        New-ScheduledTask
    }
    Enable-ScheduledTask
} else {
    Write-Host "用法:"
    Write-Host "  创建并启用: .\schedule-excavator.ps1 -Interval 4 -Enable"
    Write-Host "  仅启用:     .\schedule-excavator.ps1 -Enable"
    Write-Host "  禁用:       .\schedule-excavator.ps1 -Disable"
    Write-Host "  删除:       .\schedule-excavator.ps1 -Remove"
    Write-Host "  查看状态:   .\schedule-excavator.ps1 -List"
}