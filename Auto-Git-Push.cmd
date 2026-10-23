@echo off
chcp 65001 >nul
echo ===================================================
echo   RoROK - Auto Git Sync ^& Push
echo ===================================================
echo.

cd /d "%~dp0"

echo [1/3] Adding changes...
git add .

echo [2/3] Committing changes...
git commit -m "update: manual sync %date% %time%"

echo [3/3] Pushing to GitHub (main branch)...
git push origin main

echo.
echo ===================================================
echo   Sync Complete! All files are up to date on GitHub.
echo ===================================================
echo.
timeout /t 5
