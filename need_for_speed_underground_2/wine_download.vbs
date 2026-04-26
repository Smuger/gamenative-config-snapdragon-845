' HTTPS download for Wine. Usage: cscript //nologo wine_download.vbs <url> <outfile>
Option Explicit

Dim g_fso

Sub Dbg(path, msg)
  Dim fh, stamp
  stamp = Year(Now) & "-" & Right("0" & Month(Now), 2) & "-" & Right("0" & Day(Now), 2) & " " & _
          Right("0" & Hour(Now), 2) & ":" & Right("0" & Minute(Now), 2) & ":" & Right("0" & Second(Now), 2)
  On Error Resume Next
  Set fh = g_fso.OpenTextFile(path, 8, True)
  If Err.Number <> 0 Then
    Err.Clear
    Set fh = g_fso.CreateTextFile(path, True)
  End If
  If Err.Number = 0 Then
    fh.WriteLine stamp & " " & msg
    fh.Close
  End If
  On Error GoTo 0
End Sub

Function SaveBytes(outPath, body)
  Dim stream, sz
  SaveBytes = False
  On Error Resume Next
  Set stream = CreateObject("ADODB.Stream")
  If Err.Number <> 0 Then
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  stream.Type = 1
  stream.Open
  stream.Write body
  stream.SaveToFile outPath, 2
  If Err.Number <> 0 Then
    stream.Close
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  stream.Close
  On Error GoTo 0
  If Not g_fso.FileExists(outPath) Then Exit Function
  sz = g_fso.GetFile(outPath).Size
  If sz < 1 Then Exit Function
  SaveBytes = True
End Function

Function TryWinHttp(dbgPath, url, path, ignoreSsl, ByRef sourceName, ByRef success)
  Dim http, st, lb
  TryWinHttp = ""
  success = False
  sourceName = ""
  On Error Resume Next
  Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
  If Err.Number <> 0 Then
    TryWinHttp = "WinHTTP create: " & Err.Description
    Dbg dbgPath, TryWinHttp
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  http.Open "GET", url, False
  http.SetTimeouts 60000, 60000, 600000, 600000
  http.Option(6) = True
  If ignoreSsl Then http.Option(4) = &H3300
  http.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
  http.SetRequestHeader "Accept", "*/*"
  http.Send
  If Err.Number <> 0 Then
    TryWinHttp = "WinHTTP send: " & Err.Description
    Dbg dbgPath, TryWinHttp
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  On Error GoTo 0
  st = http.Status
  If st < 200 Or st >= 300 Then
    TryWinHttp = "WinHTTP HTTP " & st
    Dbg dbgPath, TryWinHttp
    Exit Function
  End If
  lb = LenB(http.ResponseBody)
  Dbg dbgPath, "WinHTTP HTTP " & st & " LenB=" & lb
  If lb < 1 Then
    TryWinHttp = "WinHTTP empty body"
    Exit Function
  End If
  If Not SaveBytes(path, http.ResponseBody) Then
    TryWinHttp = "WinHTTP save failed"
    Dbg dbgPath, TryWinHttp
    Exit Function
  End If
  sourceName = "WinHTTP"
  success = True
End Function

Function TryServerXml(dbgPath, url, path, ByRef sourceName, ByRef success)
  Dim xhr, st, lb
  TryServerXml = ""
  success = False
  sourceName = ""
  On Error Resume Next
  Set xhr = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  If Err.Number <> 0 Then
    TryServerXml = "ServerXMLHTTP create: " & Err.Description
    Dbg dbgPath, TryServerXml
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  xhr.Open "GET", url, False
  xhr.setTimeouts 60000, 60000, 600000, 600000
  xhr.setRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
  xhr.setRequestHeader "Accept", "*/*"
  xhr.send
  If Err.Number <> 0 Then
    TryServerXml = "ServerXMLHTTP send: " & Err.Description
    Dbg dbgPath, TryServerXml
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  On Error GoTo 0
  st = xhr.status
  If st < 200 Or st >= 300 Then
    TryServerXml = "ServerXMLHTTP HTTP " & st
    Dbg dbgPath, TryServerXml
    Exit Function
  End If
  lb = LenB(xhr.responseBody)
  Dbg dbgPath, "ServerXMLHTTP HTTP " & st & " LenB=" & lb
  If lb < 1 Then
    TryServerXml = "ServerXMLHTTP empty body"
    Exit Function
  End If
  If Not SaveBytes(path, xhr.responseBody) Then
    TryServerXml = "ServerXMLHTTP save failed"
    Exit Function
  End If
  sourceName = "ServerXMLHTTP"
  success = True
End Function

Function TryXmlHttp(dbgPath, url, path, ByRef sourceName, ByRef success)
  Dim xhr, st, lb
  TryXmlHttp = ""
  success = False
  sourceName = ""
  On Error Resume Next
  Set xhr = CreateObject("MSXML2.XMLHTTP.6.0")
  If Err.Number <> 0 Then
    Err.Clear
    Set xhr = CreateObject("MSXML2.XMLHTTP.3.0")
  End If
  If Err.Number <> 0 Then
    TryXmlHttp = "XMLHTTP create: " & Err.Description
    Dbg dbgPath, TryXmlHttp
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  xhr.Open "GET", url, False
  xhr.setRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
  xhr.setRequestHeader "Accept", "*/*"
  xhr.send
  If Err.Number <> 0 Then
    TryXmlHttp = "XMLHTTP send: " & Err.Description
    Dbg dbgPath, TryXmlHttp
    Err.Clear
    On Error GoTo 0
    Exit Function
  End If
  On Error GoTo 0
  st = xhr.status
  If st < 200 Or st >= 300 Then
    TryXmlHttp = "XMLHTTP HTTP " & st
    Dbg dbgPath, TryXmlHttp
    Exit Function
  End If
  lb = LenB(xhr.responseBody)
  Dbg dbgPath, "XMLHTTP HTTP " & st & " LenB=" & lb
  If lb < 1 Then
    TryXmlHttp = "XMLHTTP empty body"
    Exit Function
  End If
  If Not SaveBytes(path, xhr.responseBody) Then
    TryXmlHttp = "XMLHTTP save failed"
    Exit Function
  End If
  sourceName = "XMLHTTP"
  success = True
End Function

' --- main ---
If WScript.Arguments.Count <> 2 Then
  WScript.StdErr.WriteLine "usage: wine_download.vbs URL outfile"
  WScript.Quit 1
End If

Dim url, outPath, folder, dbgPath, ok, errMsg, source

url = WScript.Arguments(0)
outPath = WScript.Arguments(1)

Set g_fso = CreateObject("Scripting.FileSystemObject")
folder = g_fso.GetParentFolderName(outPath)
If Len(folder) > 0 Then
  If Not g_fso.FolderExists(folder) Then g_fso.CreateFolder folder
End If

dbgPath = g_fso.BuildPath(folder, "_wine_vbs_debug.txt")

If g_fso.FileExists(outPath) Then
  On Error Resume Next
  g_fso.DeleteFile outPath, True
  On Error GoTo 0
End If

Dbg dbgPath, "START url=" & url
Dbg dbgPath, "OUT path=" & outPath

ok = False
errMsg = ""
source = ""

If Not ok Then
  errMsg = TryWinHttp(dbgPath, url, outPath, False, source, ok)
  If ok Then Dbg dbgPath, "OK " & source & " bytes=" & g_fso.GetFile(outPath).Size
End If

If Not ok Then
  Dbg dbgPath, "retry WinHTTP SslErrorIgnore"
  errMsg = TryWinHttp(dbgPath, url, outPath, True, source, ok)
  If ok Then Dbg dbgPath, "OK " & source & " bytes=" & g_fso.GetFile(outPath).Size
End If

If Not ok Then
  errMsg = TryServerXml(dbgPath, url, outPath, source, ok)
  If ok Then Dbg dbgPath, "OK " & source & " bytes=" & g_fso.GetFile(outPath).Size
End If

If Not ok Then
  errMsg = TryXmlHttp(dbgPath, url, outPath, source, ok)
  If ok Then Dbg dbgPath, "OK " & source & " bytes=" & g_fso.GetFile(outPath).Size
End If

If Not ok Then
  If Len(errMsg) = 0 Then errMsg = "all download methods failed"
  Dbg dbgPath, "FAIL " & errMsg
  WScript.StdErr.WriteLine errMsg
  WScript.Quit 1
End If

If Not g_fso.FileExists(outPath) Then
  Dbg dbgPath, "FAIL file missing after ok"
  WScript.StdErr.WriteLine "file missing after download"
  WScript.Quit 1
End If

If g_fso.GetFile(outPath).Size < 1 Then
  Dbg dbgPath, "FAIL empty file on disk"
  WScript.StdErr.WriteLine "saved empty file"
  WScript.Quit 1
End If

WScript.Echo source & " OK size=" & g_fso.GetFile(outPath).Size
WScript.Quit 0
