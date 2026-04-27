@echo off
cd /d "%~dp0"
title install_curl_official.ps1
echo.
echo Starting PowerShell script ^(same folder as this .bat^)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_curl_official.ps1"
echo.
echo Exit code: %ERRORLEVEL%
pause
