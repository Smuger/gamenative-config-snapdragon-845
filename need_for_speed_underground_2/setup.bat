@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title NFSU2 setup

echo.
echo Working folder:
echo   %CD%
echo.
echo Type each path below in this window ^(cmd.exe^). Wine often cannot show PowerShell prompts.
echo.

if not exist "%~dp0setup.ps1" (
  echo ERROR: setup.ps1 not found beside this file.
  pause
  exit /b 1
)

set /p SETUP_CURL=1/5 Full path to curl.exe: 
set /p SETUP_7Z=2/5 Full path to 7z.exe: 
set /p SETUP_D1=3/5 Disc 1 folder ^(contains compressed.zip^): 
set /p SETUP_D2=4/5 Disc 2 folder: 
set /p SETUP_OUT=5/5 Output folder ^(merged install^): 

if "%SETUP_CURL%"=="" goto :need_paths
if "%SETUP_7Z%"=="" goto :need_paths
if "%SETUP_D1%"=="" goto :need_paths
if "%SETUP_D2%"=="" goto :need_paths
if "%SETUP_OUT%"=="" goto :need_paths
goto :run_ps
:need_paths
echo.
echo ERROR: All five paths are required. Run this .bat again.
pause
exit /b 1

:run_ps
echo.
echo Running setup.ps1 ...
echo --------------------------------------------------------------------------------
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -CurlExe "%SETUP_CURL%" -SevenZip "%SETUP_7Z%" -Disc1 "%SETUP_D1%" -Disc2 "%SETUP_D2%" -OutDir "%SETUP_OUT%"
set PS_ERR=%ERRORLEVEL%

echo --------------------------------------------------------------------------------
echo PowerShell exit code: %PS_ERR%
echo.
echo -------- nfsu2_merge.log ^(same folder as this .bat^) --------
if exist "%~dp0nfsu2_merge.log" (type "%~dp0nfsu2_merge.log") else (echo Log file was not created.)
echo -------------------------------------------------------------
echo.
pause
