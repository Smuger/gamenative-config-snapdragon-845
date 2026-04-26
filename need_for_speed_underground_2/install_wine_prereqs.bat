@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Downloads: curl.se bootstrap + certutil + VBS

rem Step 0: optional official curl from https://curl.se/windows/ ^(win64-mingw zip^). Then write test, ping, downloads. curl used first when on PATH.

cd /d "%~dp0"

set "SCRIPTDIR=%~dp0"
set "VBS=%SCRIPTDIR%wine_download.vbs"
set "WORK=%~dp0_wine_setup_downloads"
set "LOG=%WORK%\certutil_download.log"
if not exist "%WORK%" mkdir "%WORK%"
call :ensure_vbs

rem Official curl for Windows ^(curl.se^); second URL is older build if first is removed.
set "CURL_URL_1=https://curl.se/windows/dl-8.19.0_8/curl-8.19.0_8-win64-mingw.zip"
set "CURL_URL_2=https://curl.se/windows/dl-8.12.1_3/curl-8.12.1_3-win64-mingw.zip"
set "CURL_ZIP_MIN=400000"

set "DOTNET_URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "DOTNET_URL_FALLBACK=https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotNetFx45_Full_setup.exe"
set "DOTNET_MIN=200000"

set "ZIP_URL_1=https://www.7-zip.org/a/7z2409-x64.exe"
set "ZIP_URL_2=https://www.7-zip.org/a/7z2408-x64.exe"
set "ZIP_URL_3=https://www.7-zip.org/a/7z2301-x64.exe"
set "ZIP_MIN=250000"

call :bootstrap_curl_official

echo.
echo === 1^) Write test: can we create files in WORK? ===
echo     "%WORK%"
set "WT=%WORK%\_write_perm_test.tmp"
if exist "%WT%" del /f /q "%WT%" >nul 2>&1
copy /y nul "%WT%" >nul 2>&1
if errorlevel 1 echo FAIL: could not create a file here. & goto :end_fail
if not exist "%WT%" echo FAIL: file did not appear after create. & goto :end_fail
echo ok>>"%WT%" 2>nul
if errorlevel 1 echo FAIL: could not append to the test file. & del /f /q "%WT%" >nul 2>&1 & goto :end_fail
for %%S in ("%WT%") do set "WTS=%%~zS"
if "!WTS!" LSS "1" echo FAIL: test file is empty. & del /f /q "%WT%" >nul 2>&1 & goto :end_fail
del /f /q "%WT%" >nul 2>&1
if exist "%WT%" echo FAIL: could not delete the test file. & goto :end_fail
echo OK: WORK folder is writable.

del /f /q "%LOG%" 2>nul
call :log "START %DATE% %TIME%"
call :log "WORK=%WORK%"
call :log "Write test: create, append, delete in WORK succeeded."
call :log "Step 0 already ran: official curl bootstrap from curl.se ^(see console if this log was cleared^)."

echo.
echo === 2^) Internet test: ping 8.8.8.8 ===
set "PINGOUT=%WORK%\_ping_out.txt"
del /f /q "%PINGOUT%" 2>nul
ping -n 2 -w 4000 8.8.8.8 > "%PINGOUT%" 2>&1
set "PINGRC=!ERRORLEVEL!"
if not exist "%PINGOUT%" echo FAIL: could not save ping output into WORK. & goto :end_fail
type "%PINGOUT%"
type "%PINGOUT%" >>"%LOG%"
call :log "ping -n 2 -w 4000 8.8.8.8 exit code !PINGRC!"
del /f /q "%PINGOUT%" >nul 2>&1
if "!PINGRC!"=="0" call :log "Internet check: ping OK."
if not "!PINGRC!"=="0" call :log "Internet check: ping FAILED ^(no reply or error^)."
if not "!PINGRC!"=="0" echo FAIL: ping did not succeed. Downloads will not be tried. & goto :end_fail

where certutil.exe >nul 2>&1
if not errorlevel 1 goto :have_certutil
echo certutil.exe not found in PATH.
call :log "ERROR: certutil.exe not in PATH"
goto :end_fail
:have_certutil
set "HACURL=0"
where curl.exe >nul 2>&1
if not errorlevel 1 set "HACURL=1"
if "%HACURL%"=="0" where curl >nul 2>&1
if not errorlevel 1 set "HACURL=1"
if "%HACURL%"=="1" call :log "curl on PATH - will try curl first for each file."
if "%HACURL%"=="0" call :log "No curl on PATH - certutil then VBS."

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
goto :end_ok

:end_fail
echo.
echo Stopped. If a log exists: "%LOG%"
pause
endlocal
exit /b 1

:end_ok
pause
endlocal
exit /b 0

:ensure_vbs
if exist "%VBS%" goto :eof
echo Creating missing wine_download.vbs at:
echo   "%VBS%"
> "%VBS%" echo ' Auto-created downloader helper for Wine.
>>"%VBS%" echo If WScript.Arguments.Count ^<^> 2 Then
>>"%VBS%" echo   WScript.StdErr.WriteLine "usage: wine_download.vbs URL outfile"
>>"%VBS%" echo   WScript.Quit 1
>>"%VBS%" echo End If
>>"%VBS%" echo url = WScript.Arguments(0)
>>"%VBS%" echo path = WScript.Arguments(1)
>>"%VBS%" echo Set fso = CreateObject("Scripting.FileSystemObject")
>>"%VBS%" echo folder = fso.GetParentFolderName(path)
>>"%VBS%" echo If Not fso.FolderExists(folder) Then fso.CreateFolder folder
>>"%VBS%" echo Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
>>"%VBS%" echo http.Open "GET", url, False
>>"%VBS%" echo http.SetTimeouts 45000, 45000, 600000, 600000
>>"%VBS%" echo http.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
>>"%VBS%" echo http.SetRequestHeader "Accept", "*/*"
>>"%VBS%" echo On Error Resume Next
>>"%VBS%" echo http.Send
>>"%VBS%" echo If Err.Number ^<^> 0 Then
>>"%VBS%" echo   WScript.StdErr.WriteLine "Send error: " ^& Err.Description
>>"%VBS%" echo   WScript.Quit 1
>>"%VBS%" echo End If
>>"%VBS%" echo On Error GoTo 0
>>"%VBS%" echo status = http.Status
>>"%VBS%" echo If status ^< 200 Or status ^>= 300 Then
>>"%VBS%" echo   WScript.StdErr.WriteLine "HTTP status: " ^& status
>>"%VBS%" echo   WScript.Quit 1
>>"%VBS%" echo End If
>>"%VBS%" echo Set stream = CreateObject("ADODB.Stream")
>>"%VBS%" echo stream.Type = 1
>>"%VBS%" echo stream.Open
>>"%VBS%" echo stream.Write http.ResponseBody
>>"%VBS%" echo stream.SaveToFile path, 2
>>"%VBS%" echo stream.Close
>>"%VBS%" echo If Not fso.FileExists(path) Then
>>"%VBS%" echo   WScript.StdErr.WriteLine "file missing after save"
>>"%VBS%" echo   WScript.Quit 1
>>"%VBS%" echo End If
>>"%VBS%" echo If fso.GetFile(path).Size ^< 1 Then
>>"%VBS%" echo   WScript.StdErr.WriteLine "empty file"
>>"%VBS%" echo   WScript.Quit 1
>>"%VBS%" echo End If
>>"%VBS%" echo WScript.Quit 0
if exist "%VBS%" echo OK: wine_download.vbs was created.
if not exist "%VBS%" echo WARN: could not create wine_download.vbs automatically.
goto :eof

:bootstrap_curl_official
where curl.exe >nul 2>&1
if not errorlevel 1 goto :bootstrap_curl_skip
where curl >nul 2>&1
if not errorlevel 1 goto :bootstrap_curl_skip
echo.
echo === 0^) Official curl from curl.se ===
echo     If this fails, keep wine_download.vbs next to this .bat and check internet.
set "CURLZIP=%WORK%\curl_official_win64.zip"
set "CURLX=%WORK%\curl_official_extract"
if exist "%CURLZIP%" del /f /q "%CURLZIP%" >nul 2>&1
if exist "%CURLX%" rd /s /q "%CURLX%" >nul 2>&1
mkdir "%CURLX%" 2>nul
set "CURL_GOT=0"
for %%U in ("%CURL_URL_1%" "%CURL_URL_2%") do if "!CURL_GOT!"=="0" call :fetch_official_curl_zip "%%~U"
if "!CURL_GOT!"=="0" echo Bootstrap FAIL: could not download curl zip from curl.se
if "!CURL_GOT!"=="0" goto :bootstrap_curl_skip
call :filebytes "%CURLZIP%" CZS
if !CZS! LSS %CURL_ZIP_MIN% echo Bootstrap FAIL: zip too small. & goto :bootstrap_curl_skip
where tar >nul 2>&1
if errorlevel 1 echo Bootstrap FAIL: tar.exe not found - unpack "%CURLZIP%" by hand into "%CURLX%" and add bin to PATH. & goto :bootstrap_curl_skip
echo Extracting with tar...
tar -xf "%CURLZIP%" -C "%CURLX%"
if errorlevel 1 echo Bootstrap FAIL: tar extract error. & goto :bootstrap_curl_skip
set "CF="
for /f "delims=" %%G in ('dir /b /ad "%CURLX%" 2^>nul') do set "CF=%%G"
if "!CF!"=="" echo Bootstrap FAIL: no folder after extract. & goto :bootstrap_curl_skip
if not exist "%CURLX%\!CF!\bin\curl.exe" echo Bootstrap FAIL: curl.exe not in expected bin folder. & goto :bootstrap_curl_skip
set "PATH=%CURLX%\!CF!\bin;%PATH%"
echo OK: curl.exe from curl.se is on PATH for this session:
where curl.exe 2>nul
where curl 2>nul
:bootstrap_curl_skip
goto :eof

:fetch_official_curl_zip
if exist "%CURLZIP%" del /f /q "%CURLZIP%" >nul 2>&1
echo Download: %~1
if exist "%VBS%" cscript.exe //nologo "%VBS%" "%~1" "%CURLZIP%" >nul 2>&1
call :filebytes "%CURLZIP%" Z1
if !Z1! GEQ %CURL_ZIP_MIN% set "CURL_GOT=1"
if "!CURL_GOT!"=="1" goto :eof
if exist "%CURLZIP%" del /f /q "%CURLZIP%" >nul 2>&1
where certutil.exe >nul 2>&1
if errorlevel 1 goto :eof
echo Retry same URL with certutil...
certutil.exe -urlcache -split -f "%~1" "%CURLZIP%" >nul 2>&1
call :filebytes "%CURLZIP%" Z2
if !Z2! GEQ %CURL_ZIP_MIN% set "CURL_GOT=1"
goto :eof

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
set "_Z=0"
set "HAS_CURL=0"
where curl.exe >nul 2>&1
if not errorlevel 1 set "HAS_CURL=1"
if "!HAS_CURL!"=="0" where curl >nul 2>&1
if not errorlevel 1 set "HAS_CURL=1"
if "!HAS_CURL!"=="0" goto :after_curl_fail
call :try_curl_get "!_U!" "!_O!"
call :filebytes "!_O!" _Z
call :log "after curl size=!_Z!"
if !_Z! LSS !_M! goto :after_curl_fail
call :log "PASS %_N% curl"
goto :eof
:after_curl_fail
if "!HAS_CURL!"=="0" call :log "curl not on PATH: skip curl for this job."
if exist "!_O!" del /f /q "!_O!" >nul 2>&1
set "_Z=0"
set "CLOG=%WORK%\_certutil_last.txt"
del /f /q "%CLOG%" 2>nul
call :log "TRY certutil -v -urlcache -split -f URL OUT"
certutil.exe -v -urlcache -split -f "!_U!" "!_O!" >"%CLOG%" 2>&1
set "_RC=!ERRORLEVEL!"
type "%CLOG%" >>"%LOG%"
call :log "certutil exit !_RC!"
call :filebytes "!_O!" _Z
call :log "after certutil size=!_Z!"
if !_Z! LSS !_M! goto :dl_vbs
call :log "PASS %_N% certutil"
goto :eof

:try_curl_get
where curl.exe >nul 2>&1
if errorlevel 1 where curl >nul 2>&1
if errorlevel 1 goto :eof
curl.exe -fSL --connect-timeout 30 --max-time 600 -o "%~2" "%~1" >>"%LOG%" 2>&1
if errorlevel 1 curl -fSL --connect-timeout 30 --max-time 600 -o "%~2" "%~1" >>"%LOG%" 2>&1
goto :eof

:dl_vbs
call :log "certutil empty or tiny ^(common on Wine^); TRY cscript wine_download.vbs"
if exist "!_O!" del /f /q "!_O!" >nul 2>&1
if not exist "%VBS%" call :log "SKIP vbs: put wine_download.vbs next to this .bat" & goto :dl_endfail
where cscript.exe >nul 2>&1
if errorlevel 1 call :log "SKIP vbs: cscript not in PATH" & goto :dl_endfail
cscript.exe //nologo "%VBS%" "!_U!" "!_O!" >>"%LOG%" 2>&1
set "_VRC=!ERRORLEVEL!"
call :log "cscript exit !_VRC!"
call :filebytes "!_O!" _Z
call :log "after vbs size=!_Z!"
if !_Z! LSS !_M! goto :dl_endfail
call :log "PASS %_N% vbs"
goto :eof

:dl_endfail
call :log "FAIL %_N% need !_M! bytes last size=!_Z!"
goto :eof

:filebytes
set "%~2=0"
if not exist "%~1" goto :eof
for %%A in ("%~1") do set "%~2=%%~zA"
goto :eof

:log
echo %DATE% %TIME% %~1
echo %DATE% %TIME% %~1>>"%LOG%"
goto :eof
