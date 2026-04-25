@echo off
setlocal EnableExtensions EnableDelayedExpansion
title NFSU2 CD merge

cd /d "%~dp0"

echo.
echo ========================================
echo  NFS Underground 2 - two CD to one
echo ========================================
echo.
echo Base directory: %CD%
echo  (Put this .bat here next to your two CD folders. Relative paths use this folder.)
echo.
echo Zip merge order: (1) tar.exe if present  (2) PowerShell helper
echo       (3) if both fail, you merge zips on Linux, then re-run
echo       steps 6-7 only OR finish by hand - see messages below.
echo Needs: robocopy. Optional: tar (Win10+) OR PowerShell + .NET 4.5+
echo Keep merge_nfsu2_zip_helper.ps1 next to this .bat for fallback (2).
echo Source folders must contain full CD roots.
echo.

set /p "SRC1=CD1 folder (relative or full path): "
set /p "SRC2=CD2 folder (relative or full path): "
set /p "OUT=Output folder (relative or full path, will be created): "

set "SRC1=%SRC1:"=%"
set "SRC2=%SRC2:"=%"
set "OUT=%OUT:"=%"

if "%SRC1%"=="" goto :badpath
if "%SRC2%"=="" goto :badpath
if "%OUT%"=="" goto :badpath

for %%I in ("%SRC1%") do set "SRC1=%%~fI"
for %%I in ("%SRC2%") do set "SRC2=%%~fI"
for %%I in ("%OUT%") do set "OUT=%%~fI"

echo.
echo Resolved paths:
echo   CD1: "%SRC1%"
echo   CD2: "%SRC2%"
echo   OUT: "%OUT%"
echo.

if not exist "%SRC1%\*" (
  echo [ERROR] CD1 folder not found or empty: "%SRC1%"
  goto :end
)
if not exist "%SRC2%\*" (
  echo [ERROR] CD2 folder not found or empty: "%SRC2%"
  goto :end
)
if not exist "%SRC1%\compressed.zip" (
  echo [ERROR] CD1 has no compressed.zip: "%SRC1%"
  goto :end
)
if not exist "%SRC2%\compressed.zip" (
  echo [ERROR] CD2 has no compressed.zip: "%SRC2%"
  goto :end
)

echo.
echo [1/8] Creating output folder...
if exist "%OUT%\*" (
  echo [WARN] Output folder already has files. Merge will add/overwrite.
)
mkdir "%OUT%" 2>nul
if not exist "%OUT%\*" (
  echo [ERROR] Could not create: "%OUT%"
  goto :end
)

echo [2/8] Copying CD1 to output...
robocopy "%SRC1%" "%OUT%" /E /COPY:DAT /R:2 /W:2 /NFL /NDL /NJH /NJS
set "RC=!ERRORLEVEL!"
if !RC! GEQ 8 (
  echo [ERROR] robocopy CD1 failed (code !RC!)
  goto :end
)
echo       CD1 copy finished (robocopy code !RC!).

echo [3/8] Renaming CD1 compressed.zip ...
if not exist "%OUT%\compressed.zip" (
  echo [WARN] compressed.zip missing after CD1 robocopy. Trying direct copy...
  if exist "%SRC1%\compressed.zip" (
    copy /y "%SRC1%\compressed.zip" "%OUT%\compressed.zip" >nul
  )
)
if not exist "%OUT%\compressed.zip" (
  echo [ERROR] compressed.zip still missing after CD1 copy.
  echo        Source checked: "%SRC1%\compressed.zip"
  goto :end
)
if exist "%OUT%\compressed_cd1.zip" del /f /q "%OUT%\compressed_cd1.zip"
ren "%OUT%\compressed.zip" "compressed_cd1.zip"
if errorlevel 1 (
  echo [ERROR] Could not rename compressed.zip from CD1.
  goto :end
)
echo       Renamed to compressed_cd1.zip

echo [4/8] Copying CD2 (excluding bin.dat so CD1 token stays)...
robocopy "%SRC2%" "%OUT%" /E /COPY:DAT /R:2 /W:2 /NFL /NDL /NJH /NJS /XF bin.dat
set "RC=!ERRORLEVEL!"
if !RC! GEQ 8 (
  echo [ERROR] robocopy CD2 failed (code !RC!)
  goto :end
)
echo       CD2 copy finished (robocopy code !RC!).

if not exist "%OUT%\compressed.zip" (
  echo [WARN] compressed.zip missing after CD2 robocopy. Trying direct copy...
  if exist "%SRC2%\compressed.zip" (
    copy /y "%SRC2%\compressed.zip" "%OUT%\compressed.zip" >nul
  )
)
if not exist "%OUT%\compressed.zip" (
  echo [ERROR] CD2 compressed.zip did not appear in output.
  echo        Source checked: "%SRC2%\compressed.zip"
  goto :end
)
if exist "%OUT%\compressed_cd2.zip" del /f /q "%OUT%\compressed_cd2.zip"
ren "%OUT%\compressed.zip" "compressed_cd2.zip"
if errorlevel 1 (
  echo [ERROR] Could not rename compressed.zip from CD2.
  goto :end
)
echo       Renamed to compressed_cd2.zip

echo [5/8] Merging both compressed archives (may take several minutes)...
set "MERGE=%OUT%\_nfsu2_zip_work"
set "ZIPOK=0"
if exist "%MERGE%" rd /s /q "%MERGE%" 2>nul
mkdir "%MERGE%"
if errorlevel 1 (
  echo [ERROR] Could not create temp folder: "%MERGE%"
  goto :end
)

where tar >nul 2>&1
if not errorlevel 1 (
  echo       Trying tar.exe ...
  tar -xf "%OUT%\compressed_cd1.zip" -C "%MERGE%"
  if errorlevel 1 (
    echo [WARN] tar extract CD1 failed, trying next method...
    rd /s /q "%MERGE%" 2>nul
    mkdir "%MERGE%" 2>nul
  ) else (
    tar -xf "%OUT%\compressed_cd2.zip" -C "%MERGE%"
    if errorlevel 1 (
      echo [WARN] tar extract CD2 failed, trying next method...
      rd /s /q "%MERGE%" 2>nul
      mkdir "%MERGE%" 2>nul
    ) else (
      if exist "%OUT%\compressed.zip" del /f /q "%OUT%\compressed.zip"
      pushd "%MERGE%"
      tar -a -cf "%OUT%\compressed.zip" .
      set "TZ=!ERRORLEVEL!"
      popd
      set "TARFAIL=1"
      if !TZ! EQU 0 if exist "%OUT%\compressed.zip" set "TARFAIL=0"
      if "!TARFAIL!"=="0" (
        set "ZIPOK=1"
        echo       tar: merged compressed.zip OK.
      ) else (
        echo [WARN] tar did not produce compressed.zip, trying next method...
        if exist "%OUT%\compressed.zip" del /f /q "%OUT%\compressed.zip"
        rd /s /q "%MERGE%" 2>nul
        mkdir "%MERGE%" 2>nul
      )
    )
  )
)

if "!ZIPOK!"=="0" (
  set "HELPER=%~dp0merge_nfsu2_zip_helper.ps1"
  if exist "!HELPER!" (
    set "PSCMD="
    where powershell >nul 2>&1
    if not errorlevel 1 set "PSCMD=powershell"
    if not defined PSCMD (
      where pwsh >nul 2>&1
      if not errorlevel 1 set "PSCMD=pwsh"
    )
    if defined PSCMD (
      echo       Trying !PSCMD! + .NET ZipFile ...
      !PSCMD! -NoProfile -ExecutionPolicy Bypass -File "!HELPER!" -Zip1 "%OUT%\compressed_cd1.zip" -Zip2 "%OUT%\compressed_cd2.zip" -WorkDir "%MERGE%" -OutZip "%OUT%\compressed.zip"
      if errorlevel 1 (
        echo [WARN] !PSCMD! zip helper failed.
      ) else if exist "%OUT%\compressed.zip" (
        set "ZIPOK=1"
        echo       !PSCMD!: merged compressed.zip OK.
      )
    ) else (
      echo [WARN] Neither powershell.exe nor pwsh.exe in PATH.
    )
  ) else (
    echo [WARN] merge_nfsu2_zip_helper.ps1 not found beside this .bat
  )
)

if "!ZIPOK!"=="0" (
  echo.
  echo [5/8] Automatic zip merge failed or was skipped.
  echo       Your output folder still has:
  echo         compressed_cd1.zip
  echo         compressed_cd2.zip
  echo       On Linux (host PC), merge then place result as compressed.zip in OUT:
  echo         mkdir work ^&^& cd work
  echo         unzip -o "/path/to/compressed_cd1.zip"
  echo         unzip -o "/path/to/compressed_cd2.zip"
  echo         zip -r -q ../compressed.zip .
  echo         cd ..   ^(then copy compressed.zip into OUT folder above^)
  echo       Then delete compressed_cd1.zip and compressed_cd2.zip there.
  echo       Continuing with text patches (safe even before you merge zips).
  echo.
  if exist "%MERGE%" rd /s /q "%MERGE%" 2>nul
) else (
  echo       Removing split zips and work folder...
  del /f /q "%OUT%\compressed_cd1.zip" "%OUT%\compressed_cd2.zip" 2>nul
  rd /s /q "%MERGE%" 2>nul
)

echo [6/8] Patching common_filelist.txt (disc 2 -^> disc 1)...
if not exist "%OUT%\common_filelist.txt" (
  echo [WARN] common_filelist.txt not in output. Patch skipped.
  goto :patchcfg
)
set "CFL=%OUT%\common_filelist.txt"
set "CFLNEW=%OUT%\common_filelist.$$$"
if exist "%CFLNEW%" del /f /q "%CFLNEW%"
(for /f "usebackq delims=" %%L in ("%CFL%") do (
  set "line=%%L"
  if "!line:~0,2!"=="2," (
    echo 1,!line:~2!
  ) else (
    echo %%L
  )
)) > "%CFLNEW%"
if errorlevel 1 (
  echo [WARN] common_filelist patch step failed, leaving original.
  if exist "%CFLNEW%" del /f /q "%CFLNEW%"
) else (
  move /y "%CFLNEW%" "%CFL%" >nul
  echo       common_filelist.txt updated.
)

:patchcfg
echo [7/8] Patching AutoRun\autorun.cfg (StartupCD=02 -^> 01)...
set "CFG=%OUT%\AutoRun\autorun.cfg"
set "CFGNEW=%OUT%\AutoRun\autorun.$$$"
if not exist "%CFG%" (
  echo [WARN] AutoRun\autorun.cfg not found. Edit StartupCD by hand if needed.
  goto :patchinf
)
if exist "%CFGNEW%" del /f /q "%CFGNEW%"
(for /f "usebackq delims=" %%L in ("%CFG%") do (
  set "line=%%L"
  set "line=!line:StartupCD=02=StartupCD=01!"
  echo !line!
)) > "%CFGNEW%"
if errorlevel 1 (
  echo [WARN] autorun.cfg patch failed, leaving original.
  if exist "%CFGNEW%" del /f /q "%CFGNEW%"
) else (
  move /y "%CFGNEW%" "%CFG%" >nul
  echo       autorun.cfg updated.
)

:patchinf
echo [8/8] Fixing root autorun.inf (CD2 copy leaves Disk=2 / RunGame)...
set "INF=%OUT%\autorun.inf"
set "INFNEW=%OUT%\autorun.inf.$$$"
if not exist "%INF%" (
  echo [WARN] autorun.inf not in output. Optional for Setup.exe; fix if Autorun misbehaves.
  goto :done_ok
)
if exist "%INFNEW%" del /f /q "%INFNEW%"
(for /f "usebackq delims=" %%L in ("%INF%") do (
  set "line=%%L"
  set "line=!line:Disk=2=Disk=1!"
  set "line=!line:open=RunGame.exe=open=Setup.exe!"
  echo !line!
)) > "%INFNEW%"
if errorlevel 1 (
  echo [WARN] autorun.inf patch failed, leaving original.
  if exist "%INFNEW%" del /f /q "%INFNEW%"
) else (
  move /y "%INFNEW%" "%INF%" >nul
  echo       autorun.inf: Disk=1, open=Setup.exe
)

:done_ok
echo.
echo ========================================
echo  Finished.
echo ========================================
if "!ZIPOK!"=="0" (
  echo  IMPORTANT: You still need merged compressed.zip in OUT before install.
  echo  See zip-merge instructions that were printed above.
  echo.
)
echo  Run Setup.exe from:
echo    "%OUT%"
echo  Or burn this folder to one DVD (see your CD2DVD label notes).
echo.
goto :end

:badpath
echo [ERROR] Empty path.
goto :end

:end
echo.
pause
endlocal
exit /b 0
