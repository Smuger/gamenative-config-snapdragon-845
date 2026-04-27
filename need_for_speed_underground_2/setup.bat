@echo off
cd /d "%~dp0"
title NFSU2 setup
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
set PS_ERR=%ERRORLEVEL%
echo.
if not "%PS_ERR%"=="0" echo PowerShell exited with error %PS_ERR%.
pause
