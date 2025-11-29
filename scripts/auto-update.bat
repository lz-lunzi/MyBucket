@echo off
setlocal enabledelayedexpansion

echo === Bucket Auto Update Tool ===
echo.

:: Check if bucket directory exists
if not exist "%~dp0..\bucket" (
    echo ERROR: Bucket directory not found
    exit /b 1
)

:: Get Scoop path
for /f "tokens=*" %%i in ('scoop prefix scoop') do set SCOOP_HOME=%%i
set CHECKVER_SCRIPT=%SCOOP_HOME%\bin\checkver.ps1

if not exist "%CHECKVER_SCRIPT%" (
    echo ERROR: Scoop checkver script not found
    exit /b 1
)

echo Bucket directory: %~dp0..\bucket
echo Scoop home: %SCOOP_HOME%
echo.

:: Change to project root
cd /d "%~dp0.."

:: Run checkver
echo Checking for updates...
powershell -ExecutionPolicy Bypass -File "%CHECKVER_SCRIPT%" -Dir bucket -Update

:: Check for changes
for /f "tokens=*" %%i in ('git status --porcelain 2^>nul') do set HAS_CHANGES=%%i

if defined HAS_CHANGES (
    echo.
    echo Updates found!
    echo Changed files:
    for /f "tokens=*" %%i in ('git status --porcelain ^| findstr bucket') do echo   %%i

    if "%1"=="-commit" (
        echo.
        echo Committing changes...
        git add bucket/
        git commit -m "chore(autoupdate): update apps"

        if "%2"=="-push" (
            echo Pushing to remote...
            git push origin main
            if !errorlevel! equ 0 (
                echo Push successful!
            ) else (
                echo Push failed!
            )
        ) else (
            echo Use -push argument to push changes
        )
    ) else (
        echo Use -commit argument to commit changes
    )
) else (
    echo No updates found, all apps are up to date
)

echo.
echo === Done ===