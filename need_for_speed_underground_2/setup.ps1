#Requires -Version 5.1
# nfsu2: two CD folders -> one install folder. Needs: robocopy (Windows), 7-Zip.
#
# Paths: pass -CurlExe … -OutDir from setup.bat (required under Wine: cmd prompts, not Read-Host).
# Or run this script directly and answer prompts (Windows console).
param(
    [string] $CurlExe,
    [string] $SevenZip,
    [string] $Disc1,
    [string] $Disc2,
    [string] $OutDir
)

$ErrorActionPreference = 'Stop'

# Host output (Write-Host) often does not show when started from cmd.exe / Wine; use stdout.
$here = $PSScriptRoot
if (-not $here -and $MyInvocation.MyCommand.Path) {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$log = Join-Path $here 'nfsu2_merge.log'
try {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') setup.ps1 starting (folder=$here)" |
        Out-File -LiteralPath $log -Encoding utf8 -Force
}
catch {
    Write-Output "WARN: could not write log at $log — $($_.Exception.Message)"
}

function Write-Log([string] $Message) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Output $line
    Add-Content -LiteralPath $log -Value $line -Encoding utf8 -ErrorAction Stop
}

function Read-LinePrompt([string] $Question) {
    Write-Output ''
    Write-Output $Question
    Write-Output 'Type the path and press Enter (blank lines are not allowed).'
    Read-Host '>'
}

function Join-Here([string] $Path) {
    $Path = $Path.Trim().Trim('"')
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    Join-Path $here $Path
}

function Require-Path([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Not found: $Path" }
    (Resolve-Path -LiteralPath $Path).Path
}

$pathArgs = @($CurlExe, $SevenZip, $Disc1, $Disc2, $OutDir)
$nonEmpty = ($pathArgs | Where-Object { $_ }).Count
if ($nonEmpty -gt 0 -and $nonEmpty -lt 5) {
    throw 'Provide all five paths (-CurlExe, -SevenZip, -Disc1, -Disc2, -OutDir) or run without args for interactive mode.'
}
$useBatArgs = ($nonEmpty -eq 5)

try {
    Write-Log '--- start ---'

    if ($useBatArgs) {
        Write-Log 'Using paths from command line (setup.bat).'
        $curl = Require-Path (Join-Here $CurlExe)
        $sevenZip = Require-Path (Join-Here $SevenZip)
        $cd1 = Require-Path (Join-Here $Disc1)
        $cd2 = Require-Path (Join-Here $Disc2)
        $out = Join-Here $OutDir
    }
    else {
        Write-Output ''
        Write-Output '=== Interactive mode (answer in this window) ==='
        Write-Output "Paths can be full or relative to: $here"
        Write-Output ''

        $curl = Require-Path (Join-Here (Read-LinePrompt '1/5 Full path to curl.exe'))
        $sevenZip = Require-Path (Join-Here (Read-LinePrompt '2/5 Full path to 7z.exe'))
        $cd1 = Require-Path (Join-Here (Read-LinePrompt '3/5 Disc 1 folder (game root; contains compressed.zip)'))
        $cd2 = Require-Path (Join-Here (Read-LinePrompt '4/5 Disc 2 folder'))
        $out = Join-Here (Read-LinePrompt '5/5 Output folder for merged install (created if missing)')
    }

    $env:CURL_EXE = $curl
    $env:SEVENZIP_EXE = $sevenZip
    $env:Path = "$(Split-Path $sevenZip);$(Split-Path $curl);$env:Path"

    foreach ($label in @('disc 1', 'disc 2')) {
        $dir = if ($label -eq 'disc 1') { $cd1 } else { $cd2 }
        $z = Join-Path $dir 'compressed.zip'
        if (-not (Test-Path -LiteralPath $z)) { throw "Missing compressed.zip under ${label}: $z" }
    }

    Write-Log "disc1=$cd1"
    Write-Log "disc2=$cd2"
    Write-Log "out=$out"

    if (-not (Test-Path -LiteralPath $out)) {
        New-Item -ItemType Directory -Path $out -Force | Out-Null
        Write-Log "created output folder"
    }

    Write-Log '[1] robocopy disc1 -> output'
    & robocopy.exe $cd1 $out /E /COPY:DAT /R:2 /W:2 /NFL /NDL
    $rc = $LASTEXITCODE
    if ($rc -ge 8) { throw "robocopy disc1 failed (code $rc)" }
    Write-Log "robocopy disc1 exit $rc"

    $zOut1 = Join-Path $out 'compressed.zip'
    $zCd1 = Join-Path $out 'compressed_cd1.zip'
    if (-not (Test-Path -LiteralPath $zOut1)) { throw 'compressed.zip missing after disc1 copy' }
    if (Test-Path -LiteralPath $zCd1) { Remove-Item -LiteralPath $zCd1 -Force }
    Rename-Item -LiteralPath $zOut1 -NewName 'compressed_cd1.zip'
    Write-Log 'renamed compressed.zip -> compressed_cd1.zip'

    Write-Log '[2] robocopy disc2 -> output (skip bin.dat; keep disc1 key)'
    & robocopy.exe $cd2 $out /E /COPY:DAT /R:2 /W:2 /NFL /NDL /XF bin.dat
    $rc = $LASTEXITCODE
    if ($rc -ge 8) { throw "robocopy disc2 failed (code $rc)" }
    Write-Log "robocopy disc2 exit $rc"

    $zCd2 = Join-Path $out 'compressed_cd2.zip'
    if (-not (Test-Path -LiteralPath $zOut1)) {
        throw 'compressed.zip from disc2 missing in output'
    }
    Rename-Item -LiteralPath $zOut1 -NewName 'compressed_cd2.zip'
    Write-Log 'renamed compressed.zip -> compressed_cd2.zip'

    $merge = Join-Path $out '_nfsu2_zip_work'
    if (Test-Path -LiteralPath $merge) { Remove-Item -LiteralPath $merge -Recurse -Force }
    New-Item -ItemType Directory -Path $merge -Force | Out-Null

    Write-Log '[3] merge compressed_cd1.zip + compressed_cd2.zip -> compressed.zip (7-Zip)'
    & $sevenZip 'x' '-y' '-bsp1' '-bso1' "-o$merge" $zCd1
    if ($LASTEXITCODE -ne 0) { throw '7z extract disc1 zip failed' }
    & $sevenZip 'x' '-y' '-bsp1' '-bso1' "-o$merge" $zCd2
    if ($LASTEXITCODE -ne 0) { throw '7z extract disc2 zip failed' }
    Push-Location $merge
    try {
        if (Test-Path -LiteralPath $zOut1) { Remove-Item -LiteralPath $zOut1 -Force }
        & $sevenZip 'a' '-tzip' '-bsp1' '-bso1' $zOut1 '*'
        if (-not (Test-Path -LiteralPath $zOut1)) { throw '7z did not create merged compressed.zip' }
    }
    finally {
        Pop-Location
    }
    Remove-Item -LiteralPath $zCd1 -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $zCd2 -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $merge -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log 'merged compressed.zip; removed split zips and work dir'

    $enc = [System.Text.Encoding]::Default

    $cfl = Join-Path $out 'common_filelist.txt'
    if (Test-Path -LiteralPath $cfl) {
        Write-Log '[4] patch common_filelist.txt (disc 2 -> disc 1 in first column)'
        $lines = [System.IO.File]::ReadAllLines($cfl, $enc)
        $lines = $lines | ForEach-Object {
            if ($_.Length -ge 2 -and $_.Substring(0, 2) -eq '2,') { '1,' + $_.Substring(2) } else { $_ }
        }
        [System.IO.File]::WriteAllLines($cfl, $lines, $enc)
    }
    else {
        Write-Log 'WARN: common_filelist.txt missing; skipped'
    }

    $cfg = Join-Path $out 'AutoRun\autorun.cfg'
    if (Test-Path -LiteralPath $cfg) {
        Write-Log '[5] patch AutoRun\autorun.cfg StartupCD=02 -> 01'
        $t = [System.IO.File]::ReadAllText($cfg, $enc)
        $t = $t.Replace('StartupCD=02', 'StartupCD=01')
        [System.IO.File]::WriteAllText($cfg, $t, $enc)
    }
    else {
        Write-Log 'WARN: AutoRun\autorun.cfg missing; skipped'
    }

    $inf = Join-Path $out 'autorun.inf'
    if (Test-Path -LiteralPath $inf) {
        Write-Log '[6] patch autorun.inf (single-disc style)'
        $t = [System.IO.File]::ReadAllText($inf, $enc)
        $t = $t.Replace('Disk=2', 'Disk=1').Replace('open=RunGame.exe', 'open=Setup.exe')
        [System.IO.File]::WriteAllText($inf, $t, $enc)
    }
    else {
        Write-Log 'WARN: autorun.inf missing; skipped'
    }

    Write-Log '--- done: run Setup.exe from output when ready ---'
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
