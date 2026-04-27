@echo off
cd /d "%~dp0"
title NFSU2 setup

echo.
echo Working folder:
echo   %CD%
echo.

if not exist "%~dp0setup.ps1" (
  echo ERROR: setup.ps1 not found beside this file.
  pause
  exit /b 1
)

echo Starting setup.ps1 ...
echo --------------------------------------------------------------------------------

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" 2>&1
set PS_ERR=%ERRORLEVEL%

echo --------------------------------------------------------------------------------
echo PowerShell exit code: %PS_ERR%
if not "%PS_ERR%"=="0" echo Check nfsu2_merge.log in this folder if the script ran at all.
echo.
pause
