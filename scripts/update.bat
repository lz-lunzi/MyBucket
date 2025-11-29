@echo off
echo Starting bucket update...

cd /d "%~dp0.."

echo Running Scoop checkver...
powershell -Command "& '$(scoop prefix scoop)/bin/checkver.ps1' -Dir bucket -Update"

echo Checking git status...
git status --porcelain bucket/ >nul 2>&1

if errorlevel 1 (
    echo No changes detected - all apps are up to date
) else (
    echo Changes found!

    if "%1"=="-commit" (
        echo Committing changes...
        git add bucket/
        git commit -m "chore(autoupdate): update apps"

        if "%2"=="-push" (
            echo Pushing to remote...
            git push origin main
            if errorlevel 1 (
                echo Push failed!
            ) else (
                echo Push successful!
            )
        )
    ) else (
        echo Use: update.bat -commit [-push] to save changes
    )
)

echo Update complete