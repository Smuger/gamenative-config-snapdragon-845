' HTTPS download helper for Wine.
' Usage: cscript //nologo wine_download.vbs <url> <outfile>
If WScript.Arguments.Count <> 2 Then
  WScript.StdErr.WriteLine "usage: wine_download.vbs URL outfile"
  WScript.Quit 1
End If

url = WScript.Arguments(0)
path = WScript.Arguments(1)

Set fso = CreateObject("Scripting.FileSystemObject")
folder = fso.GetParentFolderName(path)
If Len(folder) > 0 Then
  If Not fso.FolderExists(folder) Then fso.CreateFolder folder
End If

If fso.FileExists(path) Then
  On Error Resume Next
  fso.DeleteFile path, True
  On Error GoTo 0
End If

ok = False
status = 0
errMsg = ""
source = ""

' Try WinHTTP first
On Error Resume Next
Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
If Err.Number <> 0 Then
  errMsg = "WinHTTP COM create failed: " & Err.Description
  Err.Clear
Else
  http.Open "GET", url, False
  http.SetTimeouts 45000, 45000, 600000, 600000
  http.Option(6) = True
  http.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
  http.SetRequestHeader "Accept", "*/*"
  http.Send
  If Err.Number <> 0 Then
    errMsg = "WinHTTP send failed: " & Err.Description
    Err.Clear
  Else
    status = http.Status
    If status >= 200 And status < 300 Then
      ok = SaveBody(http.ResponseBody, path)
      If ok Then source = "WinHTTP"
      If Not ok Then errMsg = "WinHTTP save failed"
    Else
      errMsg = "WinHTTP HTTP status: " & status
    End If
  End If
End If
On Error GoTo 0

' Fallback: XMLHTTP
If Not ok Then
  On Error Resume Next
  Set xhr = CreateObject("MSXML2.XMLHTTP.6.0")
  If Err.Number <> 0 Then
    If Len(errMsg) > 0 Then errMsg = errMsg & " | "
    errMsg = errMsg & "XMLHTTP COM create failed: " & Err.Description
    Err.Clear
  Else
    xhr.Open "GET", url, False
    xhr.setRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    xhr.setRequestHeader "Accept", "*/*"
    xhr.send
    If Err.Number <> 0 Then
      If Len(errMsg) > 0 Then errMsg = errMsg & " | "
      errMsg = errMsg & "XMLHTTP send failed: " & Err.Description
      Err.Clear
    Else
      status = xhr.status
      If status >= 200 And status < 300 Then
        ok = SaveBody(xhr.responseBody, path)
        If ok Then source = "XMLHTTP"
        If Not ok Then
          If Len(errMsg) > 0 Then errMsg = errMsg & " | "
          errMsg = errMsg & "XMLHTTP save failed"
        End If
      Else
        If Len(errMsg) > 0 Then errMsg = errMsg & " | "
        errMsg = errMsg & "XMLHTTP HTTP status: " & status
      End If
    End If
  End If
  On Error GoTo 0
End If

If Not ok Then
  If Len(errMsg) = 0 Then errMsg = "unknown download failure"
  WScript.StdErr.WriteLine errMsg
  WScript.Quit 1
End If

If Not fso.FileExists(path) Then
  WScript.StdErr.WriteLine source & " saved but file is missing"
  WScript.Quit 1
End If
If fso.GetFile(path).Size < 1 Then
  WScript.StdErr.WriteLine source & " saved empty file"
  WScript.Quit 1
End If

WScript.Echo source & " OK size=" & fso.GetFile(path).Size
WScript.Quit 0

Function SaveBody(body, outPath)
  SaveBody = False
  On Error Resume Next
  Set stream = CreateObject("ADODB.Stream")
  If Err.Number <> 0 Then
    Err.Clear
    Exit Function
  End If
  stream.Type = 1
  stream.Open
  stream.Write body
  stream.SaveToFile outPath, 2
  If Err.Number <> 0 Then
    stream.Close
    Err.Clear
    Exit Function
  End If
  stream.Close
  SaveBody = True
  On Error GoTo 0
End Function
