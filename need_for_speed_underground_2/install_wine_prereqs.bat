@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Wine prereqs - no PowerShell

cd /d "%~dp0"

set "WORK=%~dp0_wine_setup_downloads"
if not exist "%WORK%" mkdir "%WORK%"

set "VBS=%~dp0wine_download.vbs"
set "PROG86=%SystemDrive%\Program Files (x86)"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_EXE=%WORK%\dotNetFx_45plus_setup.exe"

set "ZIP_EXE=%WORK%\7zip_setup_x64.exe"
set "ZIP_MIN=250000"
set "ZIP_URL_1=https://www.7-zip.org/a/7z2409-x64.exe"
set "ZIP_URL_2=https://www.7-zip.org/a/7z2408-x64.exe"
set "ZIP_URL_3=https://www.7-zip.org/a/7z2301-x64.exe"

set "HAVE_DOTNET=0"
set "HAVE_7Z=0"

echo.
echo ========================================
echo  Wine prerequisites - batch + VBS only
echo  No PowerShell used for download or 7-Zip.
echo ========================================
echo.
if not exist "%VBS%" echo [WARN] Missing "%VBS%" - place wine_download.vbs next to this .bat.
if not exist "%VBS%" echo.


echo [1/5] Checking .NET 4.5+...
set "DOTNET_RELEASE=0"
for /f "tokens=3" %%R in ('reg query "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^| find "Release"') do set "DOTNET_RELEASE=%%R"
if not defined DOTNET_RELEASE set "DOTNET_RELEASE=0"
if "%DOTNET_RELEASE%"=="" set "DOTNET_RELEASE=0"
if %DOTNET_RELEASE% GEQ 378389 set "HAVE_DOTNET=1"
if "%HAVE_DOTNET%"=="1" echo       OK .NET present Release=%DOTNET_RELEASE%
if "%HAVE_DOTNET%"=="0" echo       .NET 4.5+ not detected Release=%DOTNET_RELEASE%

echo [2/5] Picking download tool...
set "DL_MODE="
where curl.exe >nul 2>&1 && set "DL_MODE=curl"
if not defined DL_MODE where curl >nul 2>&1 && set "DL_MODE=curl"
if not defined DL_MODE where certutil.exe >nul 2>&1 && set "DL_MODE=certutil"
if not defined DL_MODE where bitsadmin.exe >nul 2>&1 && set "DL_MODE=bitsadmin"
if not defined DL_MODE where cscript.exe >nul 2>&1 && set "DL_MODE=vbs"
if defined DL_MODE goto :have_dl
echo [ERROR] Need curl OR certutil OR bitsadmin OR cscript for downloads.
echo         Copy wine_download.vbs next to this .bat for VBS mode.
echo         Manual: https://www.7-zip.org/download.html
echo         Save x64 installer as: "%ZIP_EXE%"
goto :end
:have_dl
echo       Downloads try in order: curl, certutil, bitsadmin, VBS until one works.

echo [3/5] .NET...
if "%HAVE_DOTNET%"=="1" goto :after_dotnet
echo       Installing .NET from Microsoft...
call :download "%DOTNET_URL%" "%DOTNET_EXE%"
call :size "%DOTNET_EXE%" DOTNET_SIZE
echo       [DL] primary size=!DOTNET_SIZE!
if not "!DOTNET_SIZE!"=="0" goto :dotnet_have_file
echo       [DL] retry Microsoft direct package...
call :download "%DOTNET_URL_FALLBACK%" "%DOTNET_EXE%"
call :size "%DOTNET_EXE%" DOTNET_SIZE
echo       [DL] fallback size=!DOTNET_SIZE!
:dotnet_have_file
if not exist "%DOTNET_EXE%" goto :dotnet_fail
call :size "%DOTNET_EXE%" DOTNET_SIZE
if "!DOTNET_SIZE!"=="0" goto :dotnet_fail
"%DOTNET_EXE%" /passive /norestart
set "DNRC=!ERRORLEVEL!"
if "!DNRC!"=="0" echo       .NET installer exit 0
if "!DNRC!"=="3010" echo       .NET installer exit 3010 reboot may be needed
if not "!DNRC!"=="0" if not "!DNRC!"=="3010" echo       [WARN] .NET exit !DNRC!
goto :after_dotnet
:dotnet_fail
echo [ERROR] .NET download failed.
goto :end
:after_dotnet
if "%HAVE_DOTNET%"=="1" echo [3/5] .NET already present, skipping.

echo [4/5] 7-Zip...
where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%ProgramFiles%\7-Zip\7z.exe" set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%PROG86%\7-Zip\7z.exe" set "HAVE_7Z=1"
where 7z.exe >nul 2>&1
if errorlevel 1 if exist "%ProgramFiles%\7-Zip\7z.exe" set "PATH=%ProgramFiles%\7-Zip;%PATH%"
where 7z.exe >nul 2>&1
if errorlevel 1 if exist "%PROG86%\7-Zip\7z.exe" set "PATH=%PROG86%\7-Zip;%PATH%"

if "%HAVE_7Z%"=="1" goto :after_7zip
echo       Downloading from www.7-zip.org ...
call :fetch_7zip
call :size "%ZIP_EXE%" ZS
echo       [7Z] final size=!ZS! need min %ZIP_MIN%
if "!ZS!" LSS "%ZIP_MIN%" goto :zip_fail
echo       [7Z] Running silent setup...
"%ZIP_EXE%" /S
set "PATH=%ProgramFiles%\7-Zip;%PATH%"
set "PATH=%PROG86%\7-Zip;%PATH%"
set "HAVE_7Z=0"
where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%ProgramFiles%\7-Zip\7z.exe" set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%PROG86%\7-Zip\7z.exe" set "HAVE_7Z=1"
if "%HAVE_7Z%"=="1" echo       7-Zip install done.
if "%HAVE_7Z%"=="0" echo       [WARN] 7z.exe not on PATH after install.
goto :after_7zip
:zip_fail
echo [WARN] 7-Zip download failed. Copy installer to:
echo       "%ZIP_EXE%"
goto :after_7zip
:after_7zip

echo [5/5] Summary...
set "DOTNET_RELEASE=0"
for /f "tokens=3" %%R in ('reg query "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^| find "Release"') do set "DOTNET_RELEASE=%%R"
if not defined DOTNET_RELEASE set "DOTNET_RELEASE=0"
set "HAVE_7Z=0"
where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%ProgramFiles%\7-Zip\7z.exe" set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%PROG86%\7-Zip\7z.exe" set "HAVE_7Z=1"
echo.
if %DOTNET_RELEASE% GEQ 378389 echo   OK .NET Release=%DOTNET_RELEASE%
if %DOTNET_RELEASE% LSS 378389 echo   WARN .NET Release=%DOTNET_RELEASE%
if "%HAVE_7Z%"=="1" echo   OK 7-Zip found
if "%HAVE_7Z%"=="0" echo   WARN 7-Zip not found
echo.
goto :end

:fetch_7zip
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
call :one_zip "%ZIP_URL_1%" 1
call :size "%ZIP_EXE%" ZS
if "!ZS!" GEQ "%ZIP_MIN%" goto :eof
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
call :one_zip "%ZIP_URL_2%" 2
call :size "%ZIP_EXE%" ZS
if "!ZS!" GEQ "%ZIP_MIN%" goto :eof
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
call :one_zip "%ZIP_URL_3%" 3
goto :eof

:one_zip
echo       [7Z] try %~2 url=%~1
call :download "%~1" "%ZIP_EXE%"
goto :eof

:download
set "URL=%~1"
set "OUT=%~2"
set "DL_OK=0"
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_curl
if "!DL_OK!"=="1" goto :dl_end
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_certutil
if "!DL_OK!"=="1" goto :dl_end
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_bits
if "!DL_OK!"=="1" goto :dl_end
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_vbs
if "!DL_OK!"=="1" goto :dl_end

:dl_end
if "!DL_OK!"=="0" echo       [DL] failed URL=%URL%
if "!DL_OK!"=="1" call :size "%OUT%" SZ
if "!DL_OK!"=="1" echo       [DL] saved !SZ! bytes
goto :eof

:try_curl
where curl.exe >nul 2>&1
if errorlevel 1 where curl >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] curl...
curl.exe -sSL -L --connect-timeout 30 --max-time 600 -o "%OUT%" "%URL%"
if errorlevel 1 curl -sSL -L --connect-timeout 30 --max-time 600 -o "%OUT%" "%URL%"
call :dl_ok "%OUT%"
goto :eof

:try_certutil
where certutil.exe >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] certutil...
certutil.exe -urlcache -split -f "%URL%" "%OUT%"
call :dl_ok "%OUT%"
goto :eof

:try_bits
where bitsadmin.exe >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] bitsadmin...
bitsadmin.exe /transfer dlt /download /priority HIGH "%URL%" "%OUT%"
call :dl_ok "%OUT%"
goto :eof

:try_vbs
if not exist "%VBS%" goto :eof
where cscript.exe >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] cscript wine_download.vbs...
cscript.exe //nologo "%VBS%" "%URL%" "%OUT%"
if errorlevel 1 goto :eof
call :dl_ok "%OUT%"
goto :eof

:dl_ok
set "DL_OK=0"
set "F=%~1"
if not exist "%F%" goto :eof
for %%S in ("%F%") do if %%~zS GTR 0 set "DL_OK=1"
goto :eof

:size
set "%~2=0"
if not exist "%~1" goto :eof
for %%A in ("%~1") do set "%~2=%%~zA"
goto :eof

:end
echo.
pause
endlocal
exit /b 0
