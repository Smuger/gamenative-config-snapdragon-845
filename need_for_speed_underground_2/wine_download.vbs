' HTTPS download without PowerShell. Usage: cscript //nologo wine_download.vbs <url> <outfile>
If WScript.Arguments.Count <> 2 Then
  WScript.StdErr.WriteLine "usage: wine_download.vbs URL outfile"
  WScript.Quit 1
End If

url = WScript.Arguments(0)
path = WScript.Arguments(1)

Set fso = CreateObject("Scripting.FileSystemObject")
folder = fso.GetParentFolderName(path)
If Not fso.FolderExists(folder) Then fso.CreateFolder folder

Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
http.Open "GET", url, False
http.SetTimeouts 45000, 45000, 600000, 600000
http.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
http.SetRequestHeader "Accept", "*/*"
On Error Resume Next
http.Send
If Err.Number <> 0 Then
  WScript.StdErr.WriteLine "Send error: " & Err.Description
  WScript.Quit 1
End If
On Error GoTo 0

status = http.Status
If status < 200 Or status >= 300 Then
  WScript.StdErr.WriteLine "HTTP status: " & status
  WScript.Quit 1
End If

Set stream = CreateObject("ADODB.Stream")
stream.Type = 1
stream.Open
stream.Write http.ResponseBody
stream.SaveToFile path, 2
stream.Close

If Not fso.FileExists(path) Then
  WScript.StdErr.WriteLine "file missing after save"
  WScript.Quit 1
End If
If fso.GetFile(path).Size < 1 Then
  WScript.StdErr.WriteLine "empty file"
  WScript.Quit 1
End If

WScript.Quit 0
