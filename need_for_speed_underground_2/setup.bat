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

set /p SZ=1/4 Relative path to 7z.exe ^(e.g. 7z.exe^): 
set /p D1=2/4 Relative path to disc 1 folder ^(e.g. iso1^): 
set /p D2=3/4 Relative path to disc 2 folder ^(e.g. iso2^): 
set /p OD=4/4 Relative path to output folder ^(e.g. merged^): 

set "SZ=%SZ:"=%"
set "D1=%D1:"=%"
set "D2=%D2:"=%"
set "OD=%OD:"=%"

if "%SZ%"=="" goto :need_args
if "%D1%"=="" goto :need_args
if "%D2%"=="" goto :need_args
if "%OD%"=="" goto :need_args

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
rem Trailing backslashes on paths can confuse robocopy argument parsing
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
call :append_log 7z=!EXE_7Z!
call :append_log disc1=!SRC1!
call :append_log disc2=!SRC2!
call :append_log out=!OUT!

if not exist "%OUT%" mkdir "%OUT%"
call :append_log mkdir output if missing

echo.
echo --- robocopy ---
where robocopy 2>nul
for /f "tokens=*" %%W in ('where robocopy 2^>nul') do (
  >>"%LOG%" echo %DATE% %TIME% robocopy exe %%W
  goto :rb_where_done
)
:rb_where_done
set "_RBVER="
for /f "tokens=*" %%L in ('robocopy /? 2^>nul ^| findstr /i "Version"') do (
  set "_RBVER=%%L"
  goto :rb_ver_done
)
:rb_ver_done
if defined _RBVER (
  echo !_RBVER!
  >>"%LOG%" echo %DATE% %TIME% !_RBVER!
) else (
  echo ^(could not parse version line from robocopy /?^)
  >>"%LOG%" echo %DATE% %TIME% WARN robocopy version line not found
)
echo ---

echo.
echo [1] Copy disc1 -^> output ...
call :append_log "[1] copy disc1 -> output"
rem Do not "call :append_log ... /E ..." — cmd treats /E as a switch to CALL and breaks the line.
>>"%LOG%" echo %DATE% %TIME% robocopy "%SRC1%" "%OUT%" /E /COPY:DAT /R:2 /W:2 /NFL /NDL
robocopy "%SRC1%" "%OUT%" /E /COPY:DAT /R:2 /W:2 /NFL /NDL
set RC=!ERRORLEVEL!
call :append_log robocopy disc1 exit !RC!
if !RC! LSS 8 goto :disc1_ok
echo.
echo robocopy failed with code !RC!.
echo   Code 16 = robocopy serious error ^(bad paths, permissions, or unsupported args — not missing robocopy^).
echo Trying xcopy fallback...
call :append_log fallback xcopy disc1
if not exist "%OUT%" mkdir "%OUT%"
>>"%LOG%" echo %DATE% %TIME% xcopy disc1 fallback to "%OUT%"
xcopy "%SRC1%\*" "%OUT%\" /E /I /H /Y
set XR=!ERRORLEVEL!
call :append_log xcopy exit !XR!
if !XR! EQU 0 goto :disc1_ok
echo ERROR: xcopy failed ^(exit !XR!^). Check paths and nfsu2_merge.log
call :append_log ERROR xcopy disc1 failed !XR!
pause
exit /b 1

:disc1_ok

if not exist "%OUT%\compressed.zip" (
  echo ERROR: compressed.zip missing after disc1 copy.
  call :append_log ERROR compressed.zip missing after disc1
  pause
  exit /b 1
)
if exist "%OUT%\compressed_cd1.zip" del /f /q "%OUT%\compressed_cd1.zip"
ren "%OUT%\compressed.zip" compressed_cd1.zip
call :append_log renamed compressed.zip -^> compressed_cd1.zip

echo [2] Copy disc2 -^> output ^(normally skip bin.dat from disc2^) ...
call :append_log "[2] copy disc2 -> output"
>>"%LOG%" echo %DATE% %TIME% robocopy "%SRC2%" "%OUT%" /E /COPY:DAT /R:2 /W:2 /NFL /NDL /XF bin.dat
robocopy "%SRC2%" "%OUT%" /E /COPY:DAT /R:2 /W:2 /NFL /NDL /XF bin.dat
set RC=!ERRORLEVEL!
call :append_log robocopy disc2 exit !RC!
if !RC! LSS 8 goto :disc2_ok
echo.
echo robocopy failed with code !RC!. Trying xcopy + restore disc1 bin.dat...
call :append_log fallback xcopy disc2 then restore bin.dat from disc1
>>"%LOG%" echo %DATE% %TIME% xcopy disc2 fallback to "%OUT%"
xcopy "%SRC2%\*" "%OUT%\" /E /I /H /Y
set XR=!ERRORLEVEL!
call :append_log xcopy exit !XR!
if exist "%SRC1%\bin.dat" (
  copy /Y "%SRC1%\bin.dat" "%OUT%\bin.dat" >nul
  call :append_log restored bin.dat from disc1
) else (
  call :append_log WARN no bin.dat on disc1 to restore
)
if !XR! EQU 0 goto :disc2_ok
echo ERROR: xcopy disc2 failed ^(exit !XR!^).
call :append_log ERROR xcopy disc2 failed !XR!
pause
exit /b 1

:disc2_ok

if not exist "%OUT%\compressed.zip" (
  echo ERROR: compressed.zip from disc2 missing in output.
  call :append_log ERROR missing compressed.zip after disc2
  pause
  exit /b 1
)
if exist "%OUT%\compressed_cd2.zip" del /f /q "%OUT%\compressed_cd2.zip"
ren "%OUT%\compressed.zip" compressed_cd2.zip
call :append_log renamed compressed.zip -^> compressed_cd2.zip

echo [3] merging compressed_cd1.zip + compressed_cd2.zip ...
call :append_log "[3] 7z merge -> compressed.zip"
if exist "%MERGE%" rd /s /q "%MERGE%"
mkdir "%MERGE%"
"%EXE_7Z%" x -y "-o%MERGE%" "%OUT%\compressed_cd1.zip"
if errorlevel 2 (
  set ZERR=!ERRORLEVEL!
  goto :bad_7z
)
"%EXE_7Z%" x -y "-o%MERGE%" "%OUT%\compressed_cd2.zip"
if errorlevel 2 (
  set ZERR=!ERRORLEVEL!
  goto :bad_7z
)

pushd "%MERGE%"
if exist "%OUT%\compressed.zip" del /f /q "%OUT%\compressed.zip"
"%EXE_7Z%" a -tzip "%OUT%\compressed.zip" *
set ZERR=!ERRORLEVEL!
popd
if !ZERR! GEQ 2 goto :bad_7z
if not exist "%OUT%\compressed.zip" (
  echo ERROR: merged compressed.zip was not created.
  call :append_log ERROR 7z did not create merged compressed.zip
  pause
  exit /b 1
)

del /f /q "%OUT%\compressed_cd1.zip" "%OUT%\compressed_cd2.zip" 2>nul
rd /s /q "%MERGE%" 2>nul
call :append_log merged compressed.zip - removed split zips and work dir

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

echo [6] patch autorun.inf ...
call :append_log "[6] patch autorun.inf"
if exist "%OUT%\autorun.inf" (
  if exist "%OUT%\autorun.inf.$$$" del /f /q "%OUT%\autorun.inf.$$$"
  (for /f "usebackq delims=" %%L in ("%OUT%\autorun.inf") do (
    set "line=%%L"
    set "line=!line:Disk=2=Disk=1!"
    set "line=!line:open=RunGame.exe=open=Setup.exe!"
    echo !line!
  )) > "%OUT%\autorun.inf.$$$"
  move /y "%OUT%\autorun.inf.$$$" "%OUT%\autorun.inf" >nul
) else (
  call :append_log WARN autorun.inf missing
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

:need_args
echo ERROR: All four paths are required.
pause
exit /b 1

:bad_7z
echo ERROR: 7-Zip reported failure ^(code !ZERR!^).
>>"%LOG%" echo %DATE% %TIME% ERROR 7z code !ZERR!
pause
exit /b 1
