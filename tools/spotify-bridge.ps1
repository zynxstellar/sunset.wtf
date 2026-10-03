param(
    [ValidateRange(1025, 65535)]
    [int]$Port = 47821,
    [switch]$Once
)

$ErrorActionPreference = 'Stop'

function Get-NowPlaying {
    $title = Get-Process -Name Spotify -ErrorAction SilentlyContinue |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle) } |
        Select-Object -ExpandProperty MainWindowTitle -First 1

    if ($title) {
        $title = $title.Trim()
    }

    $hasTrack = $title -and $title -notmatch '^Spotify(?: Free| Premium)?$'
    return @{
        source = 'Spotify'
        title = if ($hasTrack) { $title.Substring(0, [Math]::Min(240, $title.Length)) } else { '' }
        available = [bool]$hasTrack
    }
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

            $valid = $requestLine -match '^GET /now-playing(?:\?[^ ]*)? HTTP/1\.[01]$'
            $body = if ($valid) {
                Get-NowPlaying | ConvertTo-Json -Compress
            } else {
                '{"error":"not found"}'
            }
            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $status = if ($valid) { '200 OK' } else { '404 Not Found' }
            $headers = "HTTP/1.1 $status`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($bodyBytes.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
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
