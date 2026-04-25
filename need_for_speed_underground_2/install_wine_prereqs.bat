@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Wine prereqs installer (cmd-only)

cd /d "%~dp0"

echo.
echo ========================================
echo  Wine prerequisites installer
echo ========================================
echo  Installs if missing:
echo    - .NET Framework 4.5+  (Release >= 378389)
echo    - PowerShell (pwsh MSI)
echo ========================================
echo.

set "WORK=%~dp0_wine_setup_downloads"
if not exist "%WORK%" mkdir "%WORK%"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_EXE=%WORK%\dotNetFx_45plus_setup.exe"

set "PS_VER=7.6.1"
set "PS_URL=https://github.com/PowerShell/PowerShell/releases/download/v%PS_VER%/PowerShell-%PS_VER%-win-x64.msi"
set "PS_MSI=%WORK%\PowerShell-%PS_VER%-win-x64.msi"

set "HAVE_PS=0"
set "HAVE_DOTNET=0"

echo [1/6] Checking PowerShell executables...
where powershell.exe >nul 2>&1 && set "HAVE_PS=1"
where pwsh.exe >nul 2>&1 && set "HAVE_PS=1"
if "%HAVE_PS%"=="1" (
  echo       PowerShell already present.
) else (
  echo       PowerShell not found in PATH.
)

echo [2/6] Checking .NET 4.5+...
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

echo [3/6] Download helper selection...
set "DL_MODE="
where powershell.exe >nul 2>&1 && set "DL_MODE=powershell"
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
  echo [ERROR] No downloader found: powershell/certutil/bitsadmin.
  echo         Manual path:
  echo         - Download installers in browser:
  echo            - %DOTNET_URL%
  echo            - fallback: %DOTNET_URL_FALLBACK%
  echo            - %PS_URL%
  echo         - Put them in:
  echo            "%WORK%"
  echo         - Re-run this script.
  goto :end
)
echo       Using: %DL_MODE%

if "%HAVE_DOTNET%"=="0" (
  echo [4/6] Installing .NET Framework 4.5+...
  call :download "%DOTNET_URL%" "%DOTNET_EXE%"
  for %%A in ("%DOTNET_EXE%") do set "DOTNET_SIZE=%%~zA"
  if not exist "%DOTNET_EXE%" set "DOTNET_SIZE=0"
  if "%DOTNET_SIZE%"=="0" (
    echo       Primary URL failed, trying fallback URL...
    call :download "%DOTNET_URL_FALLBACK%" "%DOTNET_EXE%"
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
  echo [4/6] .NET already present, skipping.
)

if "%HAVE_PS%"=="0" (
  echo [5/6] Installing PowerShell %PS_VER%...
  call :download "%PS_URL%" "%PS_MSI%"
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
  echo [5/6] PowerShell already present, skipping.
)

:verify
echo [6/6] Verifying...
set "HAVE_PS=0"
where powershell.exe >nul 2>&1 && set "HAVE_PS=1"
where pwsh.exe >nul 2>&1 && set "HAVE_PS=1"
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
echo.
echo If either check is WARN under Wine, continue anyway:
echo your merge script can still complete using manual Linux zip merge fallback.
goto :end

:download
set "URL=%~1"
set "OUT=%~2"
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

if "%DL_MODE%"=="powershell" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%OUT%' -UseBasicParsing"
  goto :eof
)
if "%DL_MODE%"=="pwsh" (
  pwsh -NoProfile -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%OUT%'"
  goto :eof
)
if "%DL_MODE%"=="certutil" (
  certutil -urlcache -split -f "%URL%" "%OUT%"
  goto :eof
)
if "%DL_MODE%"=="bitsadmin" (
  bitsadmin /transfer dljob /download /priority foreground "%URL%" "%OUT%"
  goto :eof
)
goto :eof

:end
echo.
pause
endlocal
exit /b 0
