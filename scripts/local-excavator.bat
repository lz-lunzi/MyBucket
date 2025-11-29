@echo off
setlocal enabledelayedexpansion

:: 本地 Excavator 批处理版本
:: 简单的自动更新检查和提交

echo [%time%] 本地 Excavator 启动

:: 设置变量
set BUCKET_DIR=%~dp0..\bucket
set SCOOP_HOME=
for /f "tokens=*" %%i in ('scoop prefix scoop') do set SCOOP_HOME=%%i
set CHECKVER_SCRIPT=%SCOOP_HOME%\bin\checkver.ps1

:: 检查前置条件
if not exist "%BUCKET_DIR%" (
    echo [ERROR] Bucket 目录不存在: %BUCKET_DIR%
    exit /b 1
)

if not exist "%CHECKVER_SCRIPT%" (
    echo [ERROR] Scoop checkver 脚本不存在: %CHECKVER_SCRIPT%
    exit /b 1
)

:: 切换到项目根目录
cd /d "%~dp0.."

:: 检查 git 状态
for /f "tokens=*" %%i in ('git status --porcelain') do set GIT_DIRTY=%%i
if defined GIT_DIRTY (
    echo [ERROR] 工作目录有未提交的更改
    exit /b 1
)

:: 运行检查更新
echo [%time%] 开始检查应用更新...
powershell -ExecutionPolicy Bypass -File "%CHECKVER_SCRIPT%" -Dir "%BUCKET_DIR%" -Update

:: 检查是否有更新
for /f "tokens=*" %%i in ('git status --porcelain') do set HAS_CHANGES=%%i
if defined HAS_CHANGES (
    echo [%time%] 发现更新，提交更改...

    :: 添加所有更改
    git add bucket/

    :: 生成提交信息
    for /f "tokens=*" %%i in ('git diff --name-only --cached bucket/*.json') do (
        for %%f in (%%i) do (
            set filename=%%~nf
            if "!updated_apps!"=="" (
                set updated_apps=!filename!
            ) else (
                set updated_apps=!updated_apps!, !filename!
            )
        )
    )

    :: 提交更改
    git commit -m "chore(autoupdate): update apps (!updated_apps!)"

    :: 推送更改
    echo [%time%] 推送到远程仓库...
    git push origin main

    if !errorlevel! equ 0 (
        echo [%time%] 推送成功
    ) else (
        echo [ERROR] 推送失败
        exit /b 1
    )
) else (
    echo [%time%] 没有发现更新
)

echo [%time%] 本地 Excavator 完成
exit /b 0