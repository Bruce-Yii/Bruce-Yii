<#
.SYNOPSIS
    Runtime test for scripts/update-activity.py after the OSS-ACTIVITY markers were removed.

.DESCRIPTION
    YU-143 deleted the markers from README.md, which is the input contract
    scripts/update-activity.py depends on. Reasoning about what the script would do is not
    enough, so this test actually runs it, with Python, against a real marker-less README
    and asserts the three properties the removal depends on:

      1. the script exits 0, so the workflow step does not fail;
      2. it leaves README.md byte-for-byte untouched, so the profile cannot be corrupted;
      3. it says why it did nothing, so a manual run is informative rather than silent.

    It also runs the marker-present case to prove the guard is specifically about absent
    markers and not a script that has simply stopped working.

    Exits non-zero on any failure.

.EXAMPLE
    pwsh -File Test-ProfileV24ActivityUpdater.ps1
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext'
)

$ErrorActionPreference = 'Stop'

$python = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $python) { throw 'python is required to run this runtime test.' }

$sourceRoot = $RepositoryRoot
$workRoot = Join-Path ([IO.Path]::GetTempPath()) ("yu143-updater-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $workRoot | Out-Null

function Invoke-Updater {
    param([string]$Root, [hashtable]$EnvVars = @{})

    $saved = @{}
    foreach ($key in $EnvVars.Keys) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $EnvVars[$key], 'Process')
    }
    try {
        $output = & $python.Source (Join-Path $Root 'scripts\update-activity.py') 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = ($output | Out-String)
        }
    }
    finally {
        foreach ($key in $EnvVars.Keys) {
            [Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process')
        }
    }
}

try {
    # Case 1: the real, current repository state. Markers are gone.
    $before = [IO.File]::ReadAllBytes((Join-Path $sourceRoot 'README.md'))
    $result = Invoke-Updater -Root $sourceRoot
    $after = [IO.File]::ReadAllBytes((Join-Path $sourceRoot 'README.md'))

    if ($result.ExitCode -ne 0) {
        throw "update-activity.py exited $($result.ExitCode) with markers absent. The workflow step would fail.`n$($result.Output)"
    }
    if (-not [Linq.Enumerable]::SequenceEqual($before, $after)) {
        throw 'update-activity.py modified README.md even though the markers are absent.'
    }
    if ($result.Output -notmatch 'markers missing, refusing to rewrite') {
        throw "Expected the script to report that markers are missing, got:`n$($result.Output)"
    }
    Write-Output 'markers absent -> exit 0, README untouched, reason reported'

    # Case 2: a copy with the markers restored. Proves the guard is specifically about the
    # missing markers, and that the script still functions if the timeline ever returns.
    $withMarkers = Join-Path $workRoot 'repo'
    New-Item -ItemType Directory -Path (Join-Path $withMarkers 'scripts') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'scripts\update-activity.py') -Destination (Join-Path $withMarkers 'scripts\update-activity.py')

    $readme = @(
        '# Test profile',
        '',
        '<!-- OSS-ACTIVITY:START -->',
        '- 2026-01-01 — `example/repo#1` merged — original entry',
        '<!-- OSS-ACTIVITY:END -->',
        ''
    ) -join "`n"

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $utf8NoBom.GetBytes($readme) | Set-Content -LiteralPath (Join-Path $withMarkers 'README.md') -AsByteStream -NoNewline

    # No token, so the script must fall back to its curated list rather than call the API.
    $result2 = Invoke-Updater -Root $withMarkers -EnvVars @{ GITHUB_TOKEN = '' }
    if ($result2.ExitCode -ne 0) {
        throw "update-activity.py exited $($result2.ExitCode) with markers present.`n$($result2.Output)"
    }
    $updated = $utf8NoBom.GetString([IO.File]::ReadAllBytes((Join-Path $withMarkers 'README.md')))
    if ($updated -notmatch 'langgenius/dify#42171') {
        throw 'With markers present the script did not refresh the block, so the guard has broken normal behaviour.'
    }
    Write-Output 'markers present -> exit 0, block still refreshes (guard is marker-specific)'
}
finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output 'YU-143 activity updater runtime verification passed.'
