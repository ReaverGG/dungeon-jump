@echo off
:: Switch to the project drive and directory
cd /d "E:\Dungeon Jump"

echo ========================================
echo      DUNGEON JUMP - GITHUB SYNC
echo ========================================
echo.

:: 1. Check status
git status
echo.

:: 2. Add all changes
echo [1/3] Adding new files...
git add .

:: 3. Ask for a message with Exit option
echo.
echo Type '..' and press Enter to CANCEL.
set /p commitMsg="Enter Commit Name (or press Enter for 'Auto Update'): "

:: Check if user wants to cancel
if "%commitMsg%"==".." goto cancelled

:: Set default if empty
if "%commitMsg%"=="" set commitMsg=Auto Update

echo [2/3] Committing as "%commitMsg%"...
git commit -m "%commitMsg%"

:: 4. Push to Master
echo [3/3] Pushing to GitHub...
git push origin master

echo.
echo ========================================
echo                DONE!
echo ========================================
timeout /t 5
exit

:cancelled
echo.
echo ========================================
echo        OPERATION CANCELLED
echo ========================================
timeout /t 3