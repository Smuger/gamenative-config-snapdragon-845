@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title NFSU2 merge

set "BASE=%~dp0"
set "LOG=%BASE%nfsu2_merge.log"

echo.
echo Working folder ^(all relative paths are under this folder^):
echo   %CD%
echo.
echo Each disc folder ^(e.g. iso1, iso2^) must contain compressed.zip.
echo.

set "SZ_DEF=7z.exe"
set "WHERE7Z="
for /f "delims=" %%Q in ('where 7z.exe 2^>nul') do (
  set "WHERE7Z=%%Q"
  echo where 7z.exe: %%Q
  call :RelFromBase "%%Q" SZ_DEF
  goto :after_where7z
)
:after_where7z

set /p SZ=1/4 Relative path to 7z.exe [default: !SZ_DEF!]: 
if "!SZ!"=="" set "SZ=!SZ_DEF!"
set /p D1=2/4 Relative path to disc 1 folder [default: nfs_ug2_1]: 
if "%D1%"=="" set "D1=nfs_ug2_1"
set /p D2=3/4 Relative path to disc 2 folder [default: nfs_ug2_2]: 
if "%D2%"=="" set "D2=nfs_ug2_2"
set /p OD=4/4 Relative path to output folder [default: nfs_ug2]: 
if "%OD%"=="" set "OD=nfs_ug2"

set "SZ=%SZ:"=%"
set "D1=%D1:"=%"
set "D2=%D2:"=%"
set "OD=%OD:"=%"

for %%C in ("%SZ%" "%D1%" "%D2%" "%OD%") do (
  echo %%~C | findstr /r "[a-zA-Z]:\\" >nul 2>&1 && (
    echo ERROR: Use relative paths only ^(no drive letter / full paths^).
    pause
    exit /b 1
  )
)

set "EXE_7Z=%BASE%%SZ%"
set "SRC1=%BASE%%D1%"
set "SRC2=%BASE%%D2%"
set "OUT=%BASE%%OD%"
if "!EXE_7Z:~-1!"=="\" set "EXE_7Z=!EXE_7Z:~0,-1!"
if "!SRC1:~-1!"=="\" set "SRC1=!SRC1:~0,-1!"
if "!SRC2:~-1!"=="\" set "SRC2=!SRC2:~0,-1!"
if "!OUT:~-1!"=="\" set "OUT=!OUT:~0,-1!"
set "MERGE=!OUT!\_nfsu2_zip_work"

if not exist "%EXE_7Z%" (
  echo ERROR: 7-Zip not found: "%EXE_7Z%"
  pause
  exit /b 1
)
for %%F in ("%EXE_7Z%") do set "EXE_NAME=%%~nxF"
if /I not "!EXE_NAME!"=="7z.exe" if /I not "!EXE_NAME!"=="7za.exe" (
  echo ERROR: Use 7-Zip CLI executable ^(7z.exe or 7za.exe^), not "!EXE_NAME!".
  pause
  exit /b 1
)
if not exist "%SRC1%\compressed.zip" (
  echo ERROR: Missing "%SRC1%\compressed.zip"
  pause
  exit /b 1
)
if not exist "%SRC2%\compressed.zip" (
  echo ERROR: Missing "%SRC2%\compressed.zip"
  pause
  exit /b 1
)

echo %DATE% %TIME% --- start --- >"%LOG%"
call :append_log BASE=!BASE!
if defined WHERE7Z call :append_log where 7z.exe=!WHERE7Z!
call :append_log default SZ_DEF=!SZ_DEF!
call :append_log 7z=!EXE_7Z!
call :append_log disc1=!SRC1!
call :append_log disc2=!SRC2!
call :append_log out=!OUT!

if not exist "%OUT%" mkdir "%OUT%"
call :append_log mkdir output if missing

echo.
echo [1] Copy disc1 -^> output ^(xcopy^) ...
call :append_log "[1] xcopy disc1 -> output"
>>"%LOG%" echo %DATE% %TIME% xcopy "%SRC1%\*" "%OUT%\" /E /I /H /Y
xcopy "%SRC1%\*" "%OUT%\" /E /I /H /Y
set XR=!ERRORLEVEL!
call :append_log xcopy disc1 exit !XR!
if not "!XR!"=="0" goto :bad_xcopy

for %%S in ("%SRC1%\compressed.zip") do set "Z1=%%~zS"
call :append_log disc1 compressed.zip bytes !Z1!
if !Z1! LSS 1000000 (
  echo ERROR: disc1 compressed.zip looks too small ^(!Z1! bytes^).
  call :append_log ERROR disc1 compressed.zip too small !Z1!
  pause
  exit /b 1
)

echo [2] Copy disc2 -^> output ^(xcopy^) ...
call :append_log "[2] xcopy disc2 -> output"
>>"%LOG%" echo %DATE% %TIME% xcopy "%SRC2%\*" "%OUT%\" /E /I /H /Y
xcopy "%SRC2%\*" "%OUT%\" /E /I /H /Y
set XR=!ERRORLEVEL!
call :append_log xcopy disc2 exit !XR!
if not "!XR!"=="0" goto :bad_xcopy

if exist "%SRC1%\bin.dat" (
  copy /Y "%SRC1%\bin.dat" "%OUT%\bin.dat" >nul
  call :append_log restored bin.dat from disc1
) else (
  call :append_log WARN no bin.dat on disc1 to restore
)

for %%S in ("%SRC2%\compressed.zip") do set "Z2=%%~zS"
call :append_log disc2 compressed.zip bytes !Z2!
if !Z2! LSS 1000000 (
  echo ERROR: disc2 compressed.zip looks too small ^(!Z2! bytes^).
  call :append_log ERROR disc2 compressed.zip too small !Z2!
  pause
  exit /b 1
)

echo [3] merging src compressed.zip files directly ...
call :append_log "[3] 7z merge from SRC1/SRC2 compressed.zip -> OUT\\compressed.zip"
if exist "%MERGE%" rd /s /q "%MERGE%"
mkdir "%MERGE%"
>>"%LOG%" echo %DATE% %TIME% 7z x -y "-o%MERGE%" "%SRC1%\compressed.zip"
"%EXE_7Z%" x -y "-o%MERGE%" "%SRC1%\compressed.zip" >>"%LOG%" 2>&1
if errorlevel 2 (
  set ZERR=!ERRORLEVEL!
  goto :bad_7z
)
>>"%LOG%" echo %DATE% %TIME% 7z x -y "-o%MERGE%" "%SRC2%\compressed.zip"
"%EXE_7Z%" x -y "-o%MERGE%" "%SRC2%\compressed.zip" >>"%LOG%" 2>&1
if errorlevel 2 (
  set ZERR=!ERRORLEVEL!
  goto :bad_7z
)

pushd "%MERGE%"
if exist "%OUT%\compressed.zip" del /f /q "%OUT%\compressed.zip"
>>"%LOG%" echo %DATE% %TIME% 7z a -tzip "%OUT%\compressed.zip" *
"%EXE_7Z%" a -tzip "%OUT%\compressed.zip" * >>"%LOG%" 2>&1
set ZERR=!ERRORLEVEL!
popd
if !ZERR! GEQ 2 goto :bad_7z
if not exist "%OUT%\compressed.zip" (
  echo ERROR: merged compressed.zip was not created.
  call :append_log ERROR 7z did not create merged compressed.zip
  pause
  exit /b 1
)

rd /s /q "%MERGE%" 2>nul
call :append_log merged compressed.zip from source zips - removed work dir

echo [4] patch common_filelist.txt ...
call :append_log "[4] patch common_filelist.txt"
if exist "%OUT%\common_filelist.txt" (
  if exist "%OUT%\common_filelist.$$$" del /f /q "%OUT%\common_filelist.$$$"
  (for /f "usebackq delims=" %%L in ("%OUT%\common_filelist.txt") do (
    set "line=%%L"
    if "!line:~0,2!"=="2," (
      echo 1,!line:~2!
    ) else (
      echo %%L
    )
  )) > "%OUT%\common_filelist.$$$"
  move /y "%OUT%\common_filelist.$$$" "%OUT%\common_filelist.txt" >nul
) else (
  call :append_log WARN common_filelist.txt missing
)

echo [5] patch AutoRun\autorun.cfg ...
call :append_log "[5] patch AutoRun\autorun.cfg"
if exist "%OUT%\AutoRun\autorun.cfg" (
  if exist "%OUT%\AutoRun\autorun.$$$" del /f /q "%OUT%\AutoRun\autorun.$$$"
  (for /f "usebackq delims=" %%L in ("%OUT%\AutoRun\autorun.cfg") do (
    set "line=%%L"
    set "line=!line:StartupCD=02=StartupCD=01!"
    echo !line!
  )) > "%OUT%\AutoRun\autorun.$$$"
  move /y "%OUT%\AutoRun\autorun.$$$" "%OUT%\AutoRun\autorun.cfg" >nul
) else (
  call :append_log WARN AutoRun\autorun.cfg missing
)

echo [6] autorun.inf ^(disc 1 only - Disk=1, open=Setup.exe^) ...
call :append_log "[6] autorun.inf from disc1"
if exist "%SRC1%\autorun.inf" (
  copy /Y "%SRC1%\autorun.inf" "%OUT%\autorun.inf" >nul
  call :append_log copied autorun.inf from disc1
) else (
  echo WARN: "%SRC1%\autorun.inf" missing - writing minimal single-disc autorun.inf
  call :append_log WARN disc1 autorun.inf missing - minimal template
  (
    echo [autorun]
    echo open=Setup.exe
    echo Icon=NFSU_icon.ico
    echo Name=Need for Speed Underground 2
    echo.
    echo [Special]
    echo Disk=1
  ) > "%OUT%\autorun.inf"
)

echo %DATE% %TIME% --- done --- >>"%LOG%"
echo.
echo Done. Run Setup.exe from: "%OUT%"
echo Log: "%LOG%"
pause
exit /b 0

:append_log
>>"%LOG%" echo %DATE% %TIME% %*
goto :eof

rem Strip BASE prefix so PATH hit under this folder becomes a relative default.
:RelFromBase
setlocal EnableDelayedExpansion
set "FULL=%~1"
set "SUB=%BASE%"
call set "T=%%FULL:%SUB%=%%"
if "%T%"=="%FULL%" endlocal & exit /b 0
if "%T:~0,1%"=="\" set "T=%T:~1%"
endlocal & set "%~2=%T%"
exit /b 0

:need_args
echo ERROR: All four paths are required.
pause
exit /b 1

:bad_xcopy
echo ERROR: xcopy failed ^(exit !XR!^).
call :append_log ERROR xcopy failed !XR!
pause
exit /b 1

:bad_7z
echo ERROR: 7-Zip reported failure ^(code !ZERR!^).
>>"%LOG%" echo %DATE% %TIME% ERROR 7z code !ZERR!
pause
exit /b 1
