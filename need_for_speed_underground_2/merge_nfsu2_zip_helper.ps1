# Merge two NFSU2 compressed.zip archives (CD1 + CD2) into one zip.
# Used when tar.exe is not available (e.g. older Wine). Requires PowerShell
# and .NET 4.5+ (System.IO.Compression.ZipFile).

param(
    [Parameter(Mandatory = $true)][string]$Zip1,
    [Parameter(Mandatory = $true)][string]$Zip2,
    [Parameter(Mandatory = $true)][string]$WorkDir,
    [Parameter(Mandatory = $true)][string]$OutZip
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path -LiteralPath $Zip1)) { throw "Missing: $Zip1" }
if (-not (Test-Path -LiteralPath $Zip2)) { throw "Missing: $Zip2" }

if (Test-Path -LiteralPath $WorkDir) {
    Remove-Item -LiteralPath $WorkDir -Recurse -Force
}
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

$z1 = (Resolve-Path -LiteralPath $Zip1).Path
$z2 = (Resolve-Path -LiteralPath $Zip2).Path

[System.IO.Compression.ZipFile]::ExtractToDirectory($z1, $WorkDir)

$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ('nfsu2_cd2_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp2 -Force | Out-Null
try {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($z2, $tmp2)
    Copy-Item -Path (Join-Path $tmp2 '*') -Destination $WorkDir -Recurse -Force
}
finally {
    if (Test-Path -LiteralPath $tmp2) {
        Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path -LiteralPath $OutZip) {
    Remove-Item -LiteralPath $OutZip -Force
}
[System.IO.Compression.ZipFile]::CreateFromDirectory($WorkDir, $OutZip)
Write-Host 'merge_nfsu2_zip_helper: merged zip created OK.'
