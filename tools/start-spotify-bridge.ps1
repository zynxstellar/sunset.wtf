$ErrorActionPreference = 'Stop'
$url = 'http://127.0.0.1:47821/now-playing'

try {
    $null = Invoke-RestMethod -Uri $url -TimeoutSec 2
    Write-Output 'Spotify bridge is already running.'
    return
} catch {
    # Start the bridge if its local endpoint is not available.
}

$bridge = Join-Path $PSScriptRoot 'spotify-bridge.ps1'
$runner = (Get-Command powershell.exe -ErrorAction Stop).Source

$process = Start-Process -FilePath $runner -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$bridge`""
) -WindowStyle Hidden -PassThru

Start-Sleep -Milliseconds 800
try {
    $playing = Invoke-RestMethod -Uri $url -TimeoutSec 2
    Write-Output "Spotify bridge started (PID $($process.Id))."
    if ($playing.available) { Write-Output "Song: $($playing.title)" }
} catch {
    throw 'Spotify bridge did not start. Run spotify-bridge.ps1 directly for details.'
}
