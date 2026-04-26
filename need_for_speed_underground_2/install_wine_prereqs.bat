@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Downloads via certutil

rem Five files from Microsoft and 7-zip.org; only certutil -v -urlcache -f. Needs certutil.exe on PATH.

cd /d "%~dp0"

set "WORK=%~dp0_wine_setup_downloads"
set "LOG=%WORK%\certutil_download.log"
if not exist "%WORK%" mkdir "%WORK%"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_MIN=200000"

set "ZIP_URL_1=https://www.7-zip.org/a/7z2409-x64.exe"
set "ZIP_URL_2=https://www.7-zip.org/a/7z2408-x64.exe"
set "ZIP_URL_3=https://www.7-zip.org/a/7z2301-x64.exe"
set "ZIP_MIN=250000"

del /f /q "%LOG%" 2>nul
call :log "START %DATE% %TIME%"
call :log "WORK=%WORK%"

where certutil.exe >nul 2>&1
if not errorlevel 1 goto :have_certutil
echo certutil.exe not found in PATH.
call :log "ERROR: certutil.exe not in PATH"
goto :end
:have_certutil
call :log "Each file uses: certutil -v -urlcache -f URL outfile"

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

call :log "DONE. Log: %LOG%"
echo.
echo Log: "%LOG%"
:end
pause
endlocal
exit /b 0

:download
set "_U=%~1"
set "_O=%~2"
set "_N=%~3"
set "_M=%~4"
call :log ""
call :log "JOB %_N%"
call :log "OUT=%_O%"
if exist "%_O%" del /f /q "%_O%" >nul 2>&1
echo.
echo Downloading %_N% ...
certutil.exe -v -urlcache -f "!_U!" "!_O!" >>"%LOG%" 2>&1
set "_RC=!ERRORLEVEL!"
set "_Z=0"
if exist "!_O!" for %%A in ("!_O!") do set "_Z=%%~zA"
call :log "certutil exit !_RC! size=!_Z!"
if !_Z! GEQ !_M! call :log "PASS %_N%"
if !_Z! LSS !_M! call :log "FAIL %_N% need !_M! bytes"
goto :eof

:log
echo %DATE% %TIME% %~1
echo %DATE% %TIME% %~1>>"%LOG%"
goto :eof
