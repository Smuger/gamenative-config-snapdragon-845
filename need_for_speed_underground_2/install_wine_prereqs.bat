@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Wine setup downloads ^(curl only^)

rem All HTTPS transfers use curl.exe. Run install_curl_official.ps1 first if needed, or put curl.exe next to this script.

cd /d "%~dp0"
set "SCRIPTDIR=%~dp0"
if exist "%SCRIPTDIR%curl.exe" set "PATH=%SCRIPTDIR%;%PATH%"

set "WORK=%~dp0_wine_setup_downloads"
set "LOG=%WORK%\download.log"
if not exist "%WORK%" mkdir "%WORK%"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_MIN=200000"

set "ZIP_URL_1=https://www.7-zip.org/a/7z2409-x64.exe"
set "ZIP_URL_2=https://www.7-zip.org/a/7z2408-x64.exe"
set "ZIP_URL_3=https://www.7-zip.org/a/7z2301-x64.exe"
set "ZIP_MIN=250000"

echo.
echo === 0^) Official curl ^(install_curl_official.ps1^) ===
if exist "%SCRIPTDIR%_add_official_curl_path.cmd" call "%SCRIPTDIR%_add_official_curl_path.cmd"
if exist "%SCRIPTDIR%install_curl_official.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTDIR%install_curl_official.ps1"
  if exist "%SCRIPTDIR%_add_official_curl_path.cmd" call "%SCRIPTDIR%_add_official_curl_path.cmd"
)

where curl.exe >nul 2>&1
if errorlevel 1 where curl >nul 2>&1
if errorlevel 1 (
  echo ERROR: curl.exe required. Run install_curl_official.ps1 or add curl to PATH.
  pause
  endlocal
  exit /b 1
)

echo.
echo === 1^) Write test ===
echo     "%WORK%"
set "WT=%WORK%\_write_perm_test.tmp"
if exist "%WT%" del /f /q "%WT%" >nul 2>&1
copy /y nul "%WT%" >nul 2>&1
if errorlevel 1 echo FAIL: cannot create file in WORK. & goto :end_fail
echo ok>>"%WT%" 2>nul
for %%S in ("%WT%") do set "WTS=%%~zS"
if "!WTS!" LSS "1" echo FAIL: write test. & goto :end_fail
del /f /q "%WT%" >nul 2>&1
echo OK.

del /f /q "%LOG%" 2>nul
call :log "START %DATE% %TIME%"
call :log "WORK=%WORK%"
call :log "curl-only downloads"

echo.
echo === 2^) Ping 8.8.8.8 ===
set "PINGOUT=%WORK%\_ping_out.txt"
ping -n 2 -w 4000 8.8.8.8 > "%PINGOUT%" 2>&1
type "%PINGOUT%"
type "%PINGOUT%" >>"%LOG%"
set "PINGRC=!ERRORLEVEL!"
call :log "ping exit !PINGRC!"
del /f /q "%PINGOUT%" >nul 2>&1
if not "!PINGRC!"=="0" echo FAIL: no internet. & goto :end_fail

call :log "curl on PATH"
where curl.exe >>"%LOG%" 2>&1

call :download "%DOTNET_URL%" "%WORK%\01_dotnet_fwlink.exe" dotnet_fwlink %DOTNET_MIN%
call :download "%DOTNET_URL_FALLBACK%" "%WORK%\02_dotnet_full.exe" dotnet_full %DOTNET_MIN%
call :download "%ZIP_URL_1%" "%WORK%\03_7z2409_x64.exe" 7z2409 %ZIP_MIN%
call :download "%ZIP_URL_2%" "%WORK%\04_7z2408_x64.exe" 7z2408 %ZIP_MIN%
call :download "%ZIP_URL_3%" "%WORK%\05_7z2301_x64.exe" 7z2301 %ZIP_MIN%

call :log ""
call :log "FINAL sizes:"
if exist "%WORK%\01_dotnet_fwlink.exe" for %%F in ("%WORK%\01_dotnet_fwlink.exe") do call :log "01 size=%%~zF min=%DOTNET_MIN%"
if not exist "%WORK%\01_dotnet_fwlink.exe" call :log "01 MISSING"
if exist "%WORK%\02_dotnet_full.exe" for %%F in ("%WORK%\02_dotnet_full.exe") do call :log "02 size=%%~zF min=%DOTNET_MIN%"
if not exist "%WORK%\02_dotnet_full.exe" call :log "02 MISSING"
if exist "%WORK%\03_7z2409_x64.exe" for %%F in ("%WORK%\03_7z2409_x64.exe") do call :log "03 size=%%~zF min=%ZIP_MIN%"
if not exist "%WORK%\03_7z2409_x64.exe" call :log "03 MISSING"
if exist "%WORK%\04_7z2408_x64.exe" for %%F in ("%WORK%\04_7z2408_x64.exe") do call :log "04 size=%%~zF min=%ZIP_MIN%"
if not exist "%WORK%\04_7z2408_x64.exe" call :log "04 MISSING"
if exist "%WORK%\05_7z2301_x64.exe" for %%F in ("%WORK%\05_7z2301_x64.exe") do call :log "05 size=%%~zF min=%ZIP_MIN%"
if not exist "%WORK%\05_7z2301_x64.exe" call :log "05 MISSING"

echo.
echo Log: "%LOG%"
call :log "DONE"
goto :end_ok

:end_fail
pause
endlocal
exit /b 1

:end_ok
pause
endlocal
exit /b 0

:download
set "_U=%~1"
set "_O=%~2"
set "_N=%~3"
set "_M=%~4"
call :log ""
call :log "JOB %_N% OUT=%_O%"
if exist "%_O%" del /f /q "%_O%" >nul 2>&1
echo Download %_N% ...
curl.exe -fSL --connect-timeout 30 --max-time 600 -o "!_O!" "!_U!" >>"%LOG%" 2>&1
if errorlevel 1 curl.exe -kfSL --connect-timeout 30 --max-time 600 -o "!_O!" "!_U!" >>"%LOG%" 2>&1
set "_Z=0"
if exist "!_O!" for %%A in ("!_O!") do set "_Z=%%~zA"
call :log "size=!_Z! min=%_M%"
if !_Z! GEQ !_M! (
  call :log "PASS %_N%"
  goto :eof
)
call :log "FAIL %_N%"
goto :eof

:log
echo %DATE% %TIME% %~1
echo %DATE% %TIME% %~1>>"%LOG%"
goto :eof
