@echo off
cd /d "E:\Dungeon Jump"

echo ========================================
echo      DUNGEON JUMP - GITHUB SYNC
echo ========================================
echo.

:: Force Git to ask for credentials if needed
set GIT_TERMINAL_PROMPT=1

git status
echo.

echo [1/3] Adding new files...
git add .

echo.
set /p commitMsg="Enter Commit Name (or press Enter for 'Auto Update'): "
if "%commitMsg%"=="" set commitMsg=Auto Update

echo [2/3] Committing...
git commit -m "%commitMsg%"

echo.
echo [3/3] Pushing to GitHub...
echo ---------------------------------------------------
echo  IMPORTANT:
echo  If the window stops here, check for a browser popup!
echo  If it fails immediately, read the error text below.
echo ---------------------------------------------------
echo.

git push origin master

echo.
echo ========================================
echo    PROCESS FINISHED - READ ABOVE
echo ========================================
echo.
echo Press any key to close this window...
pause >nul
exit