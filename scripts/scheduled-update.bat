@echo off
set LOG_FILE=%~dp0update-log.txt

echo [%date% %time%] Starting scheduled update... >> "%LOG_FILE%"

cd /d "%~dp0.."

echo [%date% %time%] Checking for updates... >> "%LOG_FILE%"
powershell -Command "& '$(scoop prefix scoop)/bin/checkver.ps1' -Dir bucket -Update" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Checking git status... >> "%LOG_FILE%"
git diff --quiet bucket/
if %errorlevel% equ 0 (
    echo [%date% %time%] No updates found. >> "%LOG_FILE%"
) else (
    echo [%date% %time%] Updates found! Committing and pushing... >> "%LOG_FILE%"
    git add bucket/
    git commit -m "chore(autoupdate): update apps"
    git push origin main
    echo [%date% %time%] Update completed! >> "%LOG_FILE%"
)

echo [%date% %time%] Scheduled update finished. >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"