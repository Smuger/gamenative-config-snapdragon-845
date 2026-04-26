@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Wine prereqs installer (cmd-only)

cd /d "%~dp0"

set "FETCHPS=%~dp0wine_fetch.ps1"

echo.
echo ========================================
echo  Wine prerequisites installer
echo ========================================
echo  Installs if missing:
echo    - .NET Framework 4.5+  Release ge 378389
echo    - PowerShell pwsh MSI
echo    - 7-Zip command line 7z.exe
echo ========================================
echo.
if not exist "%FETCHPS%" (
  echo [WARN] Missing "%FETCHPS%"
  echo        Copy wine_fetch.ps1 next to this .bat for reliable HTTPS downloads in Wine.
  echo.
)

set "WORK=%~dp0_wine_setup_downloads"
if not exist "%WORK%" mkdir "%WORK%"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_EXE=%WORK%\dotNetFx_45plus_setup.exe"

set "PS_VER=7.6.1"
set "PS_URL=https://github.com/PowerShell/PowerShell/releases/download/v%PS_VER%/PowerShell-%PS_VER%-win-x64.msi"
set "PS_MSI=%WORK%\PowerShell-%PS_VER%-win-x64.msi"

set "ZIP_EXE=%WORK%\7zip_setup_x64.exe"
set "ZIP_MIN=250000"
set "PF86=%ProgramFiles(x86)%"
REM 7-Zip: official site only (https://www.7-zip.org/). Try newest x64 SFX first, then older builds.
set "ZIP_URL_1=https://www.7-zip.org/a/7z2409-x64.exe"
set "ZIP_URL_2=https://www.7-zip.org/a/7z2408-x64.exe"
set "ZIP_URL_3=https://www.7-zip.org/a/7z2301-x64.exe"

set "HAVE_PS=0"
set "HAVE_DOTNET=0"
set "HAVE_7Z=0"

echo [1/7] Checking PowerShell executables...
where powershell.exe >nul 2>&1 && set "HAVE_PS=1"
where pwsh.exe >nul 2>&1 && set "HAVE_PS=1"
if "%HAVE_PS%"=="1" (
  echo       PowerShell already present.
) else (
  echo       PowerShell not found in PATH.
)

echo [2/7] Checking .NET 4.5+...
set "DOTNET_RELEASE=0"
for /f "tokens=3" %%R in ('reg query "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^| find "Release"') do set "DOTNET_RELEASE=%%R"
if not defined DOTNET_RELEASE set "DOTNET_RELEASE=0"
if "%DOTNET_RELEASE%"=="" set "DOTNET_RELEASE=0"

if %DOTNET_RELEASE% GEQ 378389 (
  set "HAVE_DOTNET=1"
  echo       .NET 4.5+ present. Release=%DOTNET_RELEASE%
) else (
  echo       .NET 4.5+ not detected. Release=%DOTNET_RELEASE%
)

echo [3/7] Download helper selection...
set "DL_MODE="
where curl.exe >nul 2>&1 && set "DL_MODE=curl"
if not defined DL_MODE where curl >nul 2>&1 && set "DL_MODE=curl"
if not defined DL_MODE where powershell.exe >nul 2>&1 && set "DL_MODE=powershell"
if not defined DL_MODE (
  where pwsh.exe >nul 2>&1 && set "DL_MODE=pwsh"
)
if not defined DL_MODE (
  where certutil.exe >nul 2>&1 && set "DL_MODE=certutil"
)
if not defined DL_MODE (
  where bitsadmin.exe >nul 2>&1 && set "DL_MODE=bitsadmin"
)

if not defined DL_MODE (
  echo [ERROR] No downloader found: curl/powershell/pwsh/certutil/bitsadmin.
  echo         Manual path:
  echo         - Download installers in browser:
  echo            - %DOTNET_URL%
  echo            - fallback: %DOTNET_URL_FALLBACK%
  echo            - %PS_URL%
  echo            - 7-Zip x64: https://www.7-zip.org/download.html
  echo         - Put them in:
  echo            "%WORK%"
  echo         - Re-run this script.
  goto :end
)
echo       Downloader selected: %DL_MODE%
echo       Download folder: "%WORK%"

if "%HAVE_DOTNET%"=="0" (
  echo [4/7] Installing .NET Framework 4.5+...
  echo       [DL] .NET primary: Microsoft fwlink
  call :download "%DOTNET_URL%" "%DOTNET_EXE%"
  for %%A in ("%DOTNET_EXE%") do set "DOTNET_SIZE=%%~zA"
  if not exist "%DOTNET_EXE%" set "DOTNET_SIZE=0"
  echo       [DL] .NET file size after primary: !DOTNET_SIZE! bytes
  if "!DOTNET_SIZE!"=="0" (
    echo       [DL] .NET primary empty or missing, trying Microsoft direct download.microsoft.com...
    call :download "%DOTNET_URL_FALLBACK%" "%DOTNET_EXE%"
    for %%A in ("%DOTNET_EXE%") do set "DOTNET_SIZE=%%~zA"
    if not exist "%DOTNET_EXE%" set "DOTNET_SIZE=0"
    echo       [DL] .NET file size after fallback: !DOTNET_SIZE! bytes
  )
  if not exist "%DOTNET_EXE%" (
    echo [ERROR] Failed to download .NET installer.
    goto :end
  )
  "%DOTNET_EXE%" /passive /norestart
  set "DNRC=%ERRORLEVEL%"
  if not "%DNRC%"=="0" if not "%DNRC%"=="3010" (
    echo [WARN] .NET installer exit code: %DNRC%
    echo       Wine may reject this installer on some prefixes.
  ) else (
    echo       .NET installer finished with code %DNRC%.
  )
) else (
  echo [4/7] .NET already present, skipping.
)

if "%HAVE_PS%"=="0" (
  echo [5/7] Installing PowerShell %PS_VER%...
  echo       [DL] PowerShell MSI from GitHub releases (official packages)
  call :download "%PS_URL%" "%PS_MSI%"
  if exist "%PS_MSI%" (
    for %%A in ("%PS_MSI%") do echo       [DL] PowerShell MSI size: %%~zA bytes
  ) else (
    echo       [DL] PowerShell MSI missing.
  )
  if not exist "%PS_MSI%" (
    echo [ERROR] Failed to download PowerShell MSI.
    goto :verify
  )
  msiexec /i "%PS_MSI%" /qn ADD_PATH=1
  set "PSRC=%ERRORLEVEL%"
  if not "%PSRC%"=="0" if not "%PSRC%"=="3010" (
    echo [WARN] PowerShell MSI exit code: %PSRC%
  ) else (
    echo       PowerShell installer finished with code %PSRC%.
  )
) else (
  echo [5/7] PowerShell already present, skipping.
)

echo [6/7] Checking or installing 7-Zip...
where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%ProgramFiles%\7-Zip\7z.exe" (
  set "HAVE_7Z=1"
  set "PATH=%ProgramFiles%\7-Zip;%PATH%"
)
if "%HAVE_7Z%"=="0" if exist "%PF86%\7-Zip\7z.exe" (
  set "HAVE_7Z=1"
  set "PATH=%PF86%\7-Zip;%PATH%"
)
if "%HAVE_7Z%"=="1" (
  echo       7-Zip already present.
) else (
  echo       7-Zip not found. Installing from www.7-zip.org only...
  call :fetch_7zip
  if exist "%ZIP_EXE%" (
    for %%A in ("%ZIP_EXE%") do echo       [DL] 7-Zip installer ready, size %%~zA bytes
  )
  if exist "%ZIP_EXE%" (
    echo       [7Z] Running silent install...
    "%ZIP_EXE%" /S
    if exist "%ProgramFiles%\7-Zip\7z.exe" set "PATH=%ProgramFiles%\7-Zip;%PATH%"
    if exist "%PF86%\7-Zip\7z.exe" set "PATH=%PF86%\7-Zip;%PATH%"
    where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
    where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
    if "%HAVE_7Z%"=="1" (
      echo       7-Zip install completed.
    ) else (
      echo [WARN] 7-Zip installer ran but 7z.exe still not found.
    )
  ) else (
    echo [WARN] Could not download a valid 7-Zip installer.
    echo       Save 7z*-x64.exe as: "%ZIP_EXE%" then re-run this script.
  )
)

:verify
echo [7/7] Verifying...
set "HAVE_PS=0"
where powershell.exe >nul 2>&1 && set "HAVE_PS=1"
where pwsh.exe >nul 2>&1 && set "HAVE_PS=1"
set "HAVE_7Z=0"
where 7z.exe >nul 2>&1 && set "HAVE_7Z=1"
where 7za.exe >nul 2>&1 && set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%ProgramFiles%\7-Zip\7z.exe" set "HAVE_7Z=1"
if "%HAVE_7Z%"=="0" if exist "%PF86%\7-Zip\7z.exe" set "HAVE_7Z=1"
set "DOTNET_RELEASE=0"
for /f "tokens=3" %%R in ('reg query "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^| find "Release"') do set "DOTNET_RELEASE=%%R"
if not defined DOTNET_RELEASE set "DOTNET_RELEASE=0"

echo.
echo Result:
if %DOTNET_RELEASE% GEQ 378389 (
  echo   [OK] .NET 4.5+ detected. Release=%DOTNET_RELEASE%
) else (
  echo   [WARN] .NET 4.5+ still not detected.
)
if "%HAVE_PS%"=="1" (
  echo   [OK] PowerShell executable found.
) else (
  echo   [WARN] PowerShell executable not found in PATH.
)
if "%HAVE_7Z%"=="1" (
  echo   [OK] 7-Zip executable found.
) else (
  echo   [WARN] 7-Zip executable not found in PATH.
)
echo.
echo If either check is WARN under Wine, continue anyway:
echo your merge script can still complete using manual Linux zip merge fallback.
goto :end

:fetch_7zip
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
echo       [7Z] attempt 1/3 official build...
call :download_try "%ZIP_URL_1%" "1"
set "ZS=0"
if exist "%ZIP_EXE%" for %%A in ("%ZIP_EXE%") do set "ZS=%%~zA"
echo       [7Z] size=!ZS! min required=%ZIP_MIN%
if "!ZS!" GEQ "%ZIP_MIN%" goto :fetch_7zip_ok
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
echo       [7Z] attempt 2/3 official build...
call :download_try "%ZIP_URL_2%" "2"
set "ZS=0"
if exist "%ZIP_EXE%" for %%A in ("%ZIP_EXE%") do set "ZS=%%~zA"
echo       [7Z] size=!ZS! min required=%ZIP_MIN%
if "!ZS!" GEQ "%ZIP_MIN%" goto :fetch_7zip_ok
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
echo       [7Z] attempt 3/3 official build...
call :download_try "%ZIP_URL_3%" "3"
set "ZS=0"
if exist "%ZIP_EXE%" for %%A in ("%ZIP_EXE%") do set "ZS=%%~zA"
echo       [7Z] size=!ZS! min required=%ZIP_MIN%
if "!ZS!" GEQ "%ZIP_MIN%" goto :fetch_7zip_ok
if exist "%ZIP_EXE%" del /f /q "%ZIP_EXE%" >nul 2>&1
echo       [7Z] all official download attempts failed or file too small.
goto :eof
:fetch_7zip_ok
echo       [7Z] download OK.
goto :eof

:download_try
set "TRY_URL=%~1"
set "TRY_N=%~2"
echo       [DL] try !TRY_N! url=!TRY_URL!
call :download "!TRY_URL!" "%ZIP_EXE%"
goto :eof

:download
set "URL=%~1"
set "OUT=%~2"
set "DL_OK=0"
echo       [DL] DL_MODE=%DL_MODE%
echo       [DL] out=%OUT%

if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

where curl.exe >nul 2>&1
if errorlevel 1 where curl >nul 2>&1
if errorlevel 1 goto :dl_try_ps1
echo       [DL] try curl -L ...
curl.exe -sSL -L --connect-timeout 30 --max-time 600 -o "%OUT%" "%URL%"
if errorlevel 1 curl -sSL -L --connect-timeout 30 --max-time 600 -o "%OUT%" "%URL%"
call :dl_check_ok "%OUT%"
if "!DL_OK!"=="1" goto :dl_done

:dl_try_ps1
if "!DL_OK!"=="0" if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
if not exist "%FETCHPS%" goto :dl_try_cert
where powershell.exe >nul 2>&1
if errorlevel 1 goto :dl_try_pwsh_file
echo       [DL] try powershell -File wine_fetch.ps1 WebClient...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%FETCHPS%" -Url "!URL!" -Out "!OUT!"
call :dl_check_ok "%OUT%"
if "!DL_OK!"=="1" goto :dl_done

:dl_try_pwsh_file
if "!DL_OK!"=="0" if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
if not exist "%FETCHPS%" goto :dl_try_cert
where pwsh.exe >nul 2>&1
if errorlevel 1 goto :dl_try_cert
echo       [DL] try pwsh -File wine_fetch.ps1 WebClient...
pwsh.exe -NoProfile -File "%FETCHPS%" -Url "!URL!" -Out "!OUT!"
call :dl_check_ok "%OUT%"
if "!DL_OK!"=="1" goto :dl_done

:dl_try_cert
if "!DL_OK!"=="0" if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
where certutil.exe >nul 2>&1
if errorlevel 1 goto :dl_try_bits
echo       [DL] try certutil...
certutil.exe -urlcache -split -f "%URL%" "%OUT%"
call :dl_check_ok "%OUT%"
if "!DL_OK!"=="1" goto :dl_done

:dl_try_bits
if "!DL_OK!"=="0" if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
where bitsadmin.exe >nul 2>&1
if errorlevel 1 goto :dl_done_fail
echo       [DL] try bitsadmin...
bitsadmin.exe /transfer dljob /download /priority foreground "%URL%" "%OUT%"
call :dl_check_ok "%OUT%"
if "!DL_OK!"=="1" goto :dl_done

:dl_done_fail
if "!DL_OK!"=="0" echo       [DL] all download attempts failed or zero-byte file

:dl_done
if exist "%OUT%" goto :dl_show_size
echo       [DL] no file written
goto :eof
:dl_show_size
for %%A in ("%OUT%") do echo       [DL] saved %%~zA bytes
goto :eof

:dl_check_ok
set "CHK=%~1"
set "DL_OK=0"
if not exist "%CHK%" goto :eof
for %%S in ("%CHK%") do if %%~zS GTR 0 set "DL_OK=1"
goto :eof

:end
echo.
pause
endlocal
exit /b 0
