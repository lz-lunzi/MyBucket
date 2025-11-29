#!/usr/bin/env pwsh
<#
.SYNOPSIS
    验证 bucket 中所有 manifest 文件的配置质量
.DESCRIPTION
    检查 manifest 文件的规范性和完整性
#>

$BucketDir = "$PSScriptRoot/../bucket"
$requiredFields = @('version', 'description', 'homepage', 'license', 'url', 'hash', 'checkver', 'autoupdate')
$recommendedFields = @('bin', 'shortcuts', 'persist')

function Test-ManifestFile {
    param([string]$FilePath)

    Write-Host "检查: $(Split-Path $FilePath -Leaf)" -ForegroundColor Cyan

    try {
        $manifest = Get-Content $FilePath -Raw | ConvertFrom-Json
        $issues = @()
        $warnings = @()

        # 检查必需字段
        foreach ($field in $requiredFields) {
            if (-not (Get-Member -InputObject $manifest -Name $field -MemberType Properties)) {
                $issues += "❌ 缺少必需字段: $field"
            }
        }

        # 检查推荐字段
        foreach ($field in $recommendedFields) {
            if (-not (Get-Member -InputObject $manifest -Name $field -MemberType Properties)) {
                $warnings += "⚠️  建议添加字段: $field"
            }
        }

        # 检查架构配置
        if ($manifest.PSObject.Properties.Name -contains 'architecture') {
            if ($manifest.architecture.PSObject.Properties.Name -notcontains '64bit') {
                $warnings += "⚠️  建议添加 64bit 架构支持"
            }
        }

        # 检查 autoupdate 架构一致性
        if ($manifest.PSObject.Properties.Name -contains 'autoupdate' -and
            $manifest.PSObject.Properties.Name -contains 'architecture') {
            $archKeys = $manifest.architecture.PSObject.Properties.Name
            $autoArchKeys = $manifest.autoupdate.PSObject.Properties.Name

            # 如果有架构但没有对应的 autoupdate 架构
            foreach ($arch in $archKeys) {
                if ($autoArchKeys -notcontains $arch -and $arch -ne 'notes') {
                    $warnings += "⚠️  autoupdate 缺少 $arch 架构配置"
                }
            }
        }

        # 输出结果
        if ($issues.Count -gt 0) {
            Write-Host "  问题:" -ForegroundColor Red
            $issues | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        }

        if ($warnings.Count -gt 0) {
            Write-Host "  建议:" -ForegroundColor Yellow
            $warnings | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
        }

        if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
            Write-Host "  ✅ 配置完善" -ForegroundColor Green
        }

        return @{
            Issues = $issues.Count
            Warnings = $warnings.Count
        }

    } catch {
        Write-Host "  ❌ JSON 解析失败: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Issues = 1
            Warnings = 0
        }
    }
}

function Start-BucketValidation {
    Write-Host "=== Bucket 配置验证 ===" -ForegroundColor Green
    Write-Host "Bucket 目录: $BucketDir"
    Write-Host ""

    $manifestFiles = Get-ChildItem -Path $BucketDir -Filter "*.json" | Where-Object {
        $_.Name -notlike "*.template*" -and $_.Name -ne "claude.json"
    }

    $totalIssues = 0
    $totalWarnings = 0

    foreach ($file in $manifestFiles) {
        $result = Test-ManifestFile -FilePath $file.FullName
        $totalIssues += $result.Issues
        $totalWarnings += $result.Warnings
        Write-Host ""
    }

    Write-Host "=== 验证汇总 ===" -ForegroundColor Green
    Write-Host "检查的文件数: $($manifestFiles.Count)" -ForegroundColor Cyan
    Write-Host "问题总数: $totalIssues" -ForegroundColor $(if ($totalIssues -gt 0) { 'Red' } else { 'Green' })
    Write-Host "建议总数: $totalWarnings" -ForegroundColor Yellow

    if ($totalIssues -eq 0) {
        Write-Host "🎉 所有 manifest 文件都通过了基本验证!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  发现 $totalIssues 个问题需要修复" -ForegroundColor Yellow
    }
}

# 执行验证
Start-BucketValidation