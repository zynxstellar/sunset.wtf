param(
    [ValidateRange(1025, 65535)]
    [int]$Port = 47821,
    [switch]$Once
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$managerType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType=WindowsRuntime]
$propertiesType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media.Control, ContentType=WindowsRuntime]
$streamType = [Windows.Storage.Streams.IRandomAccessStreamWithContentType, Windows.Storage.Streams, ContentType=WindowsRuntime]
$randomStreamType = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 } |
    Select-Object -First 1
$getInput = $randomStreamType.GetMethod('GetInputStreamAt')
$script:coverBytes = $null
$script:coverType = 'image/jpeg'
$script:coverKey = ''

function Await-WinRT($operation, [type]$resultType) {
    $task = $asTask.MakeGenericMethod($resultType).Invoke($null, @($operation))
    return $task.GetAwaiter().GetResult()
}

function Read-Cover($thumbnail) {
    if (-not $thumbnail) { return $null }
    $source = Await-WinRT ($thumbnail.OpenReadAsync()) $streamType
    $input = $getInput.Invoke($source, @([uint64]0))
    $stream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($input)
    $memory = [System.IO.MemoryStream]::new()
    try {
        $stream.CopyTo($memory)
        if ($memory.Length -gt 2MB) { return $null }
        return $memory.ToArray()
    } finally {
        $stream.Dispose()
        $memory.Dispose()
    }
}

function Get-NowPlaying {
    try {
        $manager = Await-WinRT ($managerType::RequestAsync()) $managerType
        $sessions = @($manager.GetSessions())
        $session = $manager.GetCurrentSession()
        if (-not $session -or $session.GetPlaybackInfo().PlaybackStatus.ToString() -ne 'Playing') {
            $session = $sessions | Where-Object {
                $_.GetPlaybackInfo().PlaybackStatus.ToString() -eq 'Playing'
            } | Select-Object -First 1
        }
        if (-not $session) {
            $session = $sessions | Where-Object {
                $_.SourceAppUserModelId -match 'Spotify'
            } | Select-Object -First 1
        }
        if ($session) {
            $media = Await-WinRT ($session.TryGetMediaPropertiesAsync()) $propertiesType
            $timeline = $session.GetTimelineProperties()
            $source = [string]$session.SourceAppUserModelId
            $title = [string]$media.Title
            $artist = [string]$media.Artist
            $duration = [Math]::Max(0, $timeline.EndTime.TotalSeconds - $timeline.StartTime.TotalSeconds)
            $position = [Math]::Max(0, $timeline.Position.TotalSeconds - $timeline.StartTime.TotalSeconds)
            $playing = $session.GetPlaybackInfo().PlaybackStatus.ToString() -eq 'Playing'
            if ($playing -and $timeline.LastUpdatedTime) {
                $position += [Math]::Max(0, ([DateTimeOffset]::UtcNow - $timeline.LastUpdatedTime).TotalSeconds)
            }
            if ($duration -gt 0) { $position = [Math]::Min($position, $duration) }
            $key = "$source|$title|$artist"
            if ($script:coverKey -ne $key) {
                $script:coverKey = $key
                $script:coverBytes = $null
                try { $script:coverBytes = Read-Cover $media.Thumbnail } catch { }
                if ($script:coverBytes -and $script:coverBytes.Length -ge 4 -and
                    $script:coverBytes[0] -eq 137 -and $script:coverBytes[1] -eq 80) {
                    $script:coverType = 'image/png'
                } else {
                    $script:coverType = 'image/jpeg'
                }
            }
            return @{
                source = $source
                title = $title.Substring(0, [Math]::Min(240, $title.Length))
                artist = $artist.Substring(0, [Math]::Min(120, $artist.Length))
                album = [string]$media.AlbumTitle
                position = [Math]::Round($position, 1)
                duration = [Math]::Round($duration, 1)
                playing = $playing
                artwork_key = if ($script:coverBytes) { $key } else { '' }
                available = -not [string]::IsNullOrWhiteSpace($title)
            }
        }
    } catch { }
    $title = Get-Process -Name Spotify -ErrorAction SilentlyContinue |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle) } |
        Select-Object -ExpandProperty MainWindowTitle -First 1
    if ($title) { $title = $title.Trim() }
    $hasTrack = $title -and $title -notmatch '^Spotify(?: Free| Premium)?$'
    return @{ source = 'Spotify'; title = if ($hasTrack) { $title } else { '' };
        artist = ''; album = ''; position = 0; duration = 0; playing = [bool]$hasTrack;
        artwork_key = ''; available = [bool]$hasTrack }
}

if ($Once) {
    Get-NowPlaying | ConvertTo-Json -Compress
    return
}

$listener = [System.Net.Sockets.TcpListener]::new(
    [System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 2000
            $client.SendTimeout = 2000
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new(
                $stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
            $requestLine = $reader.ReadLine()
            if (-not $requestLine) { continue }
            while ($true) {
                $header = $reader.ReadLine()
                if ($null -eq $header -or $header -eq '') { break }
            }

            $isTrack = $requestLine -match '^GET /now-playing(?:\?[^ ]*)? HTTP/1\.[01]$'
            $isCover = $requestLine -match '^GET /cover(?:\?[^ ]*)? HTTP/1\.[01]$'
            if ($isTrack) {
                $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes(
                    (Get-NowPlaying | ConvertTo-Json -Compress))
                $contentType = 'application/json; charset=utf-8'
                $status = '200 OK'
            } elseif ($isCover -and $script:coverBytes) {
                $bodyBytes = $script:coverBytes
                $contentType = $script:coverType
                $status = '200 OK'
            } else {
                $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"not found"}')
                $contentType = 'application/json; charset=utf-8'
                $status = '404 Not Found'
            }
            $headers = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($bodyBytes.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($bodyBytes, 0, $bodyBytes.Length)
            $stream.Flush()
        } catch {
            # A disconnected local client should not stop the bridge.
        } finally {
            $client.Dispose()
        }
    }
} finally {
    $listener.Stop()
}
