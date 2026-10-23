@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 34872 -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
  echo Rojo live-sync is already running at localhost:34872.
  echo Connect with the Rojo plugin in Roblox Studio, then use Play/Stop as usual.
  pause
  exit /b 0
)
"%~dp0.tools\rojo.exe" serve
pause
