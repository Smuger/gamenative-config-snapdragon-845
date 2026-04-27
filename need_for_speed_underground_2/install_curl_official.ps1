#Requires -Version 5.1
# Official curl only: https://curl.se/windows/latest.cgi?p=win64-mingw.zip
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

function Show-VersionLine {
    $line = curl.exe --version 2>&1 | Select-Object -First 1
    Write-Host $line
    return $line
}

if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    Write-Host ''
    Write-Host '=== SUCCESS: curl.exe already on PATH ===' -ForegroundColor Green
    Show-VersionLine | Out-Null
    if (-not $env:BATCH_LAUNCHED) { Read-Host 'Press Enter to close' }
    exit 0
}

$root = $PSScriptRoot
$url = 'https://curl.se/windows/latest.cgi?p=win64-mingw.zip'
$zip = Join-Path $root '_curl_ps_work\curl.zip'
$inst = Join-Path $root '_curl_official_install'
New-Item -ItemType Directory -Force -Path (Split-Path $zip) | Out-Null
Remove-Item -Recurse -Force $inst -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $inst | Out-Null

Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Expand-Archive -LiteralPath $zip -DestinationPath $inst -Force
$exe = Get-ChildItem $inst -Recurse -Filter curl.exe | Select-Object -First 1
if (-not $exe) { throw 'curl.exe missing in official archive' }

$bin = $exe.Directory.FullName.TrimEnd('\')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$normalized = ($userPath -split ';' | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() })
if ($normalized -notcontains $bin.ToLowerInvariant()) {
    [Environment]::SetEnvironmentVariable('Path', "$bin;$userPath", 'User')
}
$env:Path = "$bin;$env:Path"
Set-Content -Path (Join-Path $root '_add_official_curl_path.cmd') -Encoding ASCII -Value "@echo off`r`nset `"PATH=$bin;%%PATH%%`"`r`n"

Write-Host ''
Write-Host '=== SUCCESS: installed official curl from curl.se ===' -ForegroundColor Green
Write-Host 'Version line:'
Show-VersionLine | Out-Null
if (-not $env:BATCH_LAUNCHED) { Read-Host 'Press Enter to close' }
