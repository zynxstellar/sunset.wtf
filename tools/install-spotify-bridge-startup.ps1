param([switch]$Remove)

$ErrorActionPreference = 'Stop'
$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Rift Music Bridge.lnk'

if ($Remove) {
    if (Test-Path -LiteralPath $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath
    }
    Write-Output 'Rift music bridge startup removed.'
    return
}

$launcher = Join-Path $PSScriptRoot 'start-spotify-bridge.ps1'
if (-not (Test-Path -LiteralPath $launcher)) {
    throw 'Music bridge launcher is missing.'
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = (Get-Command powershell.exe -ErrorAction Stop).Source
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcher + '"'
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.WindowStyle = 7
$shortcut.Description = 'Starts the local Rift Music Overlay bridge.'
$shortcut.Save()

Write-Output "Rift music bridge will start at sign-in: $shortcutPath"
