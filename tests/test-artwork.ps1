$ErrorActionPreference = 'Stop'
$bridgePath = Join-Path $PSScriptRoot '..\tools\spotify-bridge.ps1'
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $bridgePath, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
foreach ($name in @('Read-Cover', 'Update-Cover')) {
    $definition = $ast.Find({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }.GetNewClosure(), $true)
    if (-not $definition) { throw "Missing $name" }
    Invoke-Expression $definition.Extent.Text
}
function Assert($condition, $message) { if (-not $condition) { throw $message } }

# Exercise the real stream-reading implementation with a WinRT memory stream.
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$randomStreamType = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]
$getInput = $randomStreamType.GetMethod('GetInputStreamAt')
$streamType = $randomStreamType
function Await-WinRT($operation, [type]$resultType) { return $operation }
$bytes = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
$randomType = [Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]
$writerType = [Windows.Storage.Streams.DataWriter, Windows.Storage.Streams, ContentType=WindowsRuntime]
$random = $randomType::new()
$writer = $writerType::new($random)
$writer.WriteBytes($bytes)
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 } |
    Select-Object -First 1
$null = $asTask.MakeGenericMethod([uint32]).Invoke($null, @($writer.StoreAsync())).GetAwaiter().GetResult()
$thumbnail = [pscustomobject]@{ Stream = $random }
$thumbnail | Add-Member -MemberType ScriptMethod -Name OpenReadAsync -Value { return $this.Stream }
$read = Read-Cover $thumbnail
Assert ($read -is [byte[]]) 'Read-Cover enumerated the byte array'
Assert ($read.Length -eq $bytes.Length -and $read[0] -eq 137) 'Read-Cover changed image bytes'
$writer.Dispose()
$random.Dispose()

# Simulate titles arriving before artwork, changed bytes on the same title,
# temporary read failures, and a new track with no thumbnail.
$script:reads = 0
$script:nextBytes = $null
$script:throwRead = $false
function Read-Cover($thumbnail) {
    $script:reads++
    if ($script:throwRead) { throw 'temporary stream failure' }
    return ,$script:nextBytes
}
$script:coverTrack = ''
$script:coverKey = ''
$script:coverBytes = $null
$script:coverNextRead = [DateTimeOffset]::MinValue
Update-Cover 'song-a' $null
Assert ($script:coverKey -eq '') 'Missing artwork should use the placeholder'
$script:nextBytes = $bytes
$script:coverNextRead = [DateTimeOffset]::MinValue
Update-Cover 'song-a' $null
Assert ($script:coverKey -ne '' -and $script:coverType -eq 'image/png') 'Late artwork was not retried'
$firstKey = $script:coverKey
$reads = $script:reads
Update-Cover 'song-a' $null
Assert ($script:reads -eq $reads) 'Successful artwork reads are not throttled'
$script:nextBytes = [byte[]](137, 80, 78, 71, 99)
$script:coverNextRead = [DateTimeOffset]::MinValue
Update-Cover 'song-a' $null
Assert ($script:coverKey -ne $firstKey) 'Changed artwork needs a different content key'
$currentKey = $script:coverKey
$script:throwRead = $true
$script:coverNextRead = [DateTimeOffset]::MinValue
Update-Cover 'song-a' $null
Assert ($script:coverKey -eq $currentKey) 'A transient failure lost a valid cover'
Update-Cover 'song-b' $null
Assert ($script:coverKey -eq '' -and $null -eq $script:coverBytes) 'A new track retained old artwork'
$encoded = [Uri]::EscapeDataString('source|title with spaces|artist|hash')
Assert ([Uri]::UnescapeDataString($encoded) -eq 'source|title with spaces|artist|hash') 'Artwork request key round trip failed'
Write-Output 'PASS artwork: byte stream, late thumbnail, refresh, throttling, transient failure, track change'
