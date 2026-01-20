@echo off
setlocal EnableDelayedExpansion

:: ---------------------------------------------------
::  CONFIGURATION & SETUP
:: ---------------------------------------------------
:: 1. Set the script to work in the folder where this file is located
cd /d "%~dp0"
title Dungeon Jump - Git Sync Tool
color 0F

echo ===================================================
echo        DUNGEON JUMP - GITHUB SYNC WIZARD
echo ===================================================
echo.

:: ---------------------------------------------------
::  STEP 0: CHECK REPO STATUS
:: ---------------------------------------------------
echo [INFO] Checking repository status...

:: Check if git is actually installed/working
git --version >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Git is not installed or not found in PATH!
    pause
    exit /b
)

:: Auto-detect the current branch (works for 'main', 'master', or 'dev')
for /f "tokens=*" %%a in ('git branch --show-current') do set CURRENT_BRANCH=%%a
echo [INFO] Detected Branch: %CURRENT_BRANCH%
echo.

:: ---------------------------------------------------
::  STEP 1: PULL (Safety First!)
:: ---------------------------------------------------
echo [1/4] Pulling latest changes from remote...
echo -------------------------------------------
git pull origin %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERROR] Pull failed! You might have merge conflicts.
    echo Fix them manually before running this script.
    pause
    exit /b
)
echo.

:: ---------------------------------------------------
::  STEP 2: ADD
:: ---------------------------------------------------
echo [2/4] Staging files...
git add -A
echo.

:: ---------------------------------------------------
::  STEP 3: COMMIT
:: ---------------------------------------------------
:: Check if there are actually changes to commit
git diff-index --quiet HEAD
if %errorlevel% equ 0 (
    echo [INFO] No new changes to commit.
    echo [INFO] Checking if push is needed anyway...
    goto :PUSH_STEP
)

echo [3/4] Committing...
set /p commitMsg="Enter Commit Message (Press Enter for 'Update %date%'): "
if "%commitMsg%"=="" set commitMsg=Update %date% %time%

git commit -m "%commitMsg%"
echo.

:: ---------------------------------------------------
::  STEP 4: PUSH
:: ---------------------------------------------------
:PUSH_STEP
echo [4/4] Pushing to GitHub (%CURRENT_BRANCH%)...
echo -------------------------------------------
echo  NOTE: If this hangs, check for a browser login popup!
echo -------------------------------------------
git push origin %CURRENT_BRANCH%

if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERROR] Push failed. Check your internet or credentials.
    echo.
) else (
    color 0A
    echo.
    echo ===================================================
    echo        SUCCESS: SYNC COMPLETE!
    echo ===================================================
)

echo.
echo Press any key to exit...
pause >nul