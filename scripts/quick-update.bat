@echo off
echo Starting bucket update...

cd /d "%~dp0.."

echo Checking and updating app versions...
powershell -Command "& '$(scoop prefix scoop)/bin/checkver.ps1' -Dir bucket -Update"

echo Checking for changes...
git diff --quiet bucket/
if %errorlevel% equ 0 (
    echo No updates found.
) else (
    echo Updates found! Committing changes...
    git add bucket/
    git commit -m "chore(autoupdate): update apps"
    git push origin main
    echo Update completed successfully!
)

echo Done.