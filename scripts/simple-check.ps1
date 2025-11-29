param(
    [string]$BucketDir = "$PSScriptRoot/../bucket"
)

Write-Host "Starting local Excavator test..." -ForegroundColor Green
Write-Host "Bucket directory: $BucketDir"

# Check if bucket directory exists
if (-not (Test-Path $BucketDir)) {
    Write-Host "ERROR: Bucket directory not found: $BucketDir" -ForegroundColor Red
    exit 1
}

# Get Scoop installation path
$scoopHome = scoop prefix scoop
$checkVerScript = "$scoopHome/bin/checkver.ps1"

Write-Host "Scoop home: $scoopHome"
Write-Host "CheckVer script: $checkVerScript"

# Check if checkver script exists
if (-not (Test-Path $checkVerScript)) {
    Write-Host "ERROR: Scoop checkver script not found: $checkVerScript" -ForegroundColor Red
    exit 1
}

# Run checkver
try {
    Write-Host "Running checkver..." -ForegroundColor Yellow
    & $checkVerScript -Dir $BucketDir
    Write-Host "Checkver completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR running checkver: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}