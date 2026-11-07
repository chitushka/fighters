$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputDir = Join-Path $projectRoot 'test-results'
New-Item -ItemType Directory -Force $outputDir | Out-Null
foreach ($relative in @('Играть.cmd', 'build\Играть.cmd')) {
    $launcherPath = Join-Path $projectRoot $relative
    $bytes = [IO.File]::ReadAllBytes($launcherPath)
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 10 -and ($i -eq 0 -or $bytes[$i - 1] -ne 13)) {
            throw "Batch file has LF instead of CRLF: $relative"
        }
    }
    $tag = if ($relative.StartsWith('build')) { 'build' } else { 'root' }
    $logPath = Join-Path $outputDir "launcher-$tag.log"
    $stdoutPath = Join-Path $outputDir "launcher-$tag-stdout.txt"
    $stderrPath = Join-Path $outputDir "launcher-$tag-stderr.txt"
    $started = Get-Date
    $arguments = '/d /c ""{0}" --headless --log-file "{1}" -- --smoke"' -f $launcherPath, $logPath
    $proc = Start-Process -FilePath $env:ComSpec -ArgumentList $arguments -WorkingDirectory $env:TEMP -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    if ($proc.ExitCode -ne 0) { throw "Launcher failed: $relative" }
    $deadline = (Get-Date).AddSeconds(20)
    $passed = $false
    while ((Get-Date) -lt $deadline) {
        if ((Test-Path -LiteralPath $logPath) -and (Get-Item -LiteralPath $logPath).LastWriteTime -ge $started) {
            $log = [IO.File]::ReadAllText($logPath)
            if ($log.Contains('SMOKE OK:')) { $passed = $true; break }
            if ($log.Contains('ERROR:')) { throw "Game reported an error: $log" }
        }
        Start-Sleep -Milliseconds 200
    }
    if (-not $passed) { throw "No successful game startup through $relative" }
    if ((Get-Item -LiteralPath $stderrPath).Length -gt 0) { throw ([IO.File]::ReadAllText($stderrPath)) }
    Write-Output "PASS: $relative starts packaged game from another working directory"
}
