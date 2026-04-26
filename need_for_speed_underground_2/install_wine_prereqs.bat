@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Wine prereqs

cd /d "%~dp0"

set "WORK=%~dp0_wine_setup_downloads"
if not exist "%WORK%" mkdir "%WORK%"

set "VBS=%~dp0wine_download.vbs"
set "PROG86=%SystemDrive%\Program Files (x86)"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_EXE=%WORK%\dotNetFx_45plus_setup.exe"
set "DOTNET_MIN=200000"

set "ZIP_EXE=%WORK%\7zip_setup_x64.exe"
set "ZIP_MIN=250000"
set "ZIP_URL_1=https://www.7-zip.org/a/7z2409-x64.exe"
set "ZIP_URL_2=https://www.7-zip.org/a/7z2408-x64.exe"
set "ZIP_URL_3=https://www.7-zip.org/a/7z2301-x64.exe"

call :wine_detect
call :dotnet_read

echo.
echo  Prerequisites: 7-Zip ^(+ .NET on Windows only^). Batch + VBS, no PowerShell.
if "%UNDER_WINE%"=="1" echo  Wine detected ^(WINEPREFIX, registry, or ASSUME_WINE=1^).
if not exist "%VBS%" echo  [WARN] Missing "%VBS%" - VBS download will not run.
echo.

echo [1/4] .NET check...
if "%HAVE_DOTNET%"=="1" echo       Release %DOTNET_RELEASE% OK.
if "%HAVE_DOTNET%"=="0" echo       Not found or below 4.5 ^(Release=%DOTNET_RELEASE%^).

echo [2/4] .NET install...
if "%UNDER_WINE%"=="1" goto :dotnet_skip_wine
if "%HAVE_DOTNET%"=="1" goto :dotnet_skip_ok
call :need_downloader
if errorlevel 1 goto :end
call :dotnet_install_win
if errorlevel 1 goto :end
goto :sec_7z
:dotnet_skip_wine
echo       Skipped under Wine ^(not needed for 7-Zip; use winetricks for apps^).
goto :sec_7z
:dotnet_skip_ok
echo       Already satisfied.

:sec_7z
echo [3/4] 7-Zip...
call :detect_7z
if "%HAVE_7Z%"=="1" goto :zip_skip_have
call :need_downloader
if errorlevel 1 goto :end
call :fetch_7zip
call :size "%ZIP_EXE%" ZS
if "!ZS!" LSS "%ZIP_MIN%" goto :zip_too_small
echo       Running silent setup...
"%ZIP_EXE%" /S
call :prepend_7z_path
call :detect_7z
if "%HAVE_7Z%"=="1" echo       Installed.
if "%HAVE_7Z%"=="0" echo       [WARN] 7z.exe still not found - add 7-Zip to PATH manually.
goto :sec_sum
:zip_skip_have
echo       Already available.
goto :sec_sum
:zip_too_small
echo [WARN] 7-Zip download too small ^(!ZS! bytes^). Copy installer to:
echo        "%ZIP_EXE%"

:sec_sum
echo [4/4] Summary...
call :dotnet_read
call :prepend_7z_path
call :detect_7z
echo.
if "%UNDER_WINE%"=="1" echo   Wine: .NET was not installed by this script.
if "%UNDER_WINE%"=="0" if %DOTNET_RELEASE% GEQ 378389 echo   .NET OK ^(Release %DOTNET_RELEASE%^)
if "%UNDER_WINE%"=="0" if %DOTNET_RELEASE% LSS 378389 echo   .NET WARN ^(Release %DOTNET_RELEASE%^)
if "%HAVE_7Z%"=="1" echo   7-Zip OK
if "%HAVE_7Z%"=="0" echo   7-Zip missing
echo.

goto :end

:wine_detect
set "UNDER_WINE=0"
if /i "%ASSUME_WINE%"=="1" set "UNDER_WINE=1"
if defined WINEPREFIX set "UNDER_WINE=1"
if "%UNDER_WINE%"=="1" goto :eof
reg query "HKCU\Software\Wine" 2>nul | find "HKEY" >nul
if not errorlevel 1 set "UNDER_WINE=1"
goto :eof

:dotnet_read
set "DOTNET_RELEASE=0"
set "HAVE_DOTNET=0"
for /f "tokens=3" %%R in ('reg query "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^| find "Release"') do set "DOTNET_RELEASE=%%R"
if not defined DOTNET_RELEASE set "DOTNET_RELEASE=0"
if "%DOTNET_RELEASE%"=="" set "DOTNET_RELEASE=0"
if %DOTNET_RELEASE% GEQ 378389 set "HAVE_DOTNET=1"
goto :eof

:need_downloader
where curl.exe >nul 2>&1 && exit /b 0
where curl >nul 2>&1 && exit /b 0
if exist "%VBS%" where cscript.exe >nul 2>&1 && exit /b 0
where bitsadmin.exe >nul 2>&1 && exit /b 0
if not "%UNDER_WINE%"=="1" where certutil.exe >nul 2>&1 && exit /b 0
echo [ERROR] No downloader: need curl, or cscript + wine_download.vbs, or bitsadmin.
if "%UNDER_WINE%"=="0" echo         On Windows, certutil also works.
echo         Manual 7-Zip x64: save as "%ZIP_EXE%"
exit /b 1

:dotnet_install_win
set "GOT=0"
for %%U in ("%DOTNET_URL%" "%DOTNET_URL_FALLBACK%") do call :dotnet_try_url "%%~U"
if "!GOT!"=="0" echo [ERROR] .NET download failed.
if "!GOT!"=="0" exit /b 1
"%DOTNET_EXE%" /passive /norestart
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" exit /b 0
if "!RC!"=="3010" exit /b 0
echo       [WARN] .NET installer exit !RC!
exit /b 0

:dotnet_try_url
if "!GOT!"=="1" goto :eof
if exist "%DOTNET_EXE%" del /f /q "%DOTNET_EXE%" >nul 2>&1
call :download "%~1" "%DOTNET_EXE%"
call :size "%DOTNET_EXE%" DS
if !DS! GEQ %DOTNET_MIN% set "GOT=1"
goto :eof

:fetch_7zip
set "ZS=0"
for %%U in ("%ZIP_URL_1%" "%ZIP_URL_2%" "%ZIP_URL_3%") do call :zip_try_url "%%~U"
goto :eof

:zip_try_url
if !ZS! GEQ %ZIP_MIN% goto :eof
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
echo       [7Z] %~1
call :download "%~1" "%ZIP_EXE%"
call :size "%ZIP_EXE%" ZS
goto :eof

:download
set "URL=%~1"
set "OUT=%~2"
set "DL_OK=0"
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_curl
if "!DL_OK!"=="1" goto :dl_end
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_vbs
if "!DL_OK!"=="1" goto :dl_end
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_bits
if "!DL_OK!"=="1" goto :dl_end
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :try_certutil
if "!DL_OK!"=="1" goto :dl_end

:dl_end
if "!DL_OK!"=="0" echo       [DL] failed %URL%
if "!DL_OK!"=="1" call :size "%OUT%" SZ
if "!DL_OK!"=="1" echo       [DL] OK !SZ! bytes
goto :eof

:try_curl
where curl.exe >nul 2>&1
if errorlevel 1 where curl >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] curl
curl.exe -fsSL --connect-timeout 30 --max-time 600 -o "%OUT%" "%URL%"
if errorlevel 1 curl -fsSL --connect-timeout 30 --max-time 600 -o "%OUT%" "%URL%"
call :dl_ok "%OUT%"
goto :eof

:try_vbs
if not exist "%VBS%" goto :eof
where cscript.exe >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] cscript VBS
cscript.exe //nologo "%VBS%" "%URL%" "%OUT%"
if errorlevel 1 goto :eof
call :dl_ok "%OUT%"
goto :eof

:try_bits
where bitsadmin.exe >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] bitsadmin
set "BJ=dl%RANDOM%%RANDOM%"
bitsadmin.exe /transfer "!BJ!" /download /priority HIGH "%URL%" "%OUT%"
call :dl_ok "%OUT%"
goto :eof

:try_certutil
if "%UNDER_WINE%"=="1" goto :eof
where certutil.exe >nul 2>&1
if errorlevel 1 goto :eof
echo       [DL] certutil
certutil.exe -urlcache -split -f "%URL%" "%OUT%"
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

:prepend_7z_path
if exist "%ProgramFiles%\7-Zip\7z.exe" set "PATH=%ProgramFiles%\7-Zip;%PATH%"
if exist "%PROG86%\7-Zip\7z.exe" set "PATH=%PROG86%\7-Zip;%PATH%"
goto :eof

:detect_7z
set "HAVE_7Z=0"
where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="1" goto :eof
where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="1" goto :eof
if exist "%ProgramFiles%\7-Zip\7z.exe" set "HAVE_7Z=1"
if "%HAVE_7Z%"=="1" goto :eof
if exist "%PROG86%\7-Zip\7z.exe" set "HAVE_7Z=1"
goto :eof

:end
pause
endlocal
exit /b 0
