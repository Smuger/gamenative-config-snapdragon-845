@echo off
cd /d "%~dp0"
title install_curl_official.ps1
rem Same console as PowerShell; skip Read-Host inside .ps1 so one pause at the end shows everything.
set BATCH_LAUNCHED=1

echo.
echo Running install_curl_official.ps1 ...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_curl_official.ps1"
set "PS_EXIT=%ERRORLEVEL%"

if exist "%~dp0_add_official_curl_path.cmd" call "%~dp0_add_official_curl_path.cmd"

echo.
echo ----------------------------------------
if "%PS_EXIT%"=="0" (
  echo PowerShell script finished: OK ^(exit 0^)
) else (
  echo PowerShell script finished: FAILED ^(exit %PS_EXIT%^)
)
echo.
echo curl.exe on PATH in this window:
where curl.exe 2>nul
if errorlevel 1 (
  echo   ^(not found — open a NEW cmd so User PATH is picked up, or re-run this .bat^)
) else (
  echo.
  curl.exe --version 2>nul
)
echo ----------------------------------------
echo.
pause
