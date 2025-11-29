#!/usr/bin/env pwsh

$BucketDir = "$PSScriptRoot/../bucket"

Write-Host "=== Bucket Validation ===" -ForegroundColor Green

$manifestFiles = Get-ChildItem -Path $BucketDir -Filter "*.json" | Where-Object {
    $_.Name -notlike "*.template*" -and $_.Name -ne "claude.json"
}

Write-Host "Found $($manifestFiles.Count) manifest files:"
$manifestFiles | ForEach-Object { Write-Host "  $($_.Name)" }

Write-Host "`n=== Checking Required Fields ===" -ForegroundColor Cyan

$requiredFields = @('version', 'description', 'homepage', 'license', 'url', 'hash', 'checkver', 'autoupdate')

foreach ($file in $manifestFiles) {
    Write-Host "`nChecking: $($file.Name)" -ForegroundColor White

    try {
        $manifest = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $missing = @()

        foreach ($field in $requiredFields) {
            if (-not (Get-Member -InputObject $manifest -Name $field -MemberType Properties)) {
                $missing += $field
            }
        }

        if ($missing.Count -eq 0) {
            Write-Host "  OK - All required fields present" -ForegroundColor Green
        } else {
            Write-Host "  Missing: $($missing -join ', ')" -ForegroundColor Red
        }

        # Check recommended fields
        $recommended = @('bin', 'shortcuts', 'persist')
        $missingRec = @()

        foreach ($field in $recommended) {
            if (-not (Get-Member -InputObject $manifest -Name $field -MemberType Properties)) {
                $missingRec += $field
            }
        }

        if ($missingRec.Count -gt 0) {
            Write-Host "  Recommended missing: $($missingRec -join ', ')" -ForegroundColor Yellow
        }

    } catch {
        Write-Host "  ERROR: Invalid JSON" -ForegroundColor Red
    }
}

Write-Host "`n=== Validation Complete ===" -ForegroundColor Green