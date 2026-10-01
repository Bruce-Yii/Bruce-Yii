<#
.SYNOPSIS
    Adversarial self-test for Test-ProfileV24Content.ps1 (YU-143).

.DESCRIPTION
    A gate that only ever reports green proves nothing. This harness applies mutations
    that YU-143 explicitly did *not* authorise and asserts each one is rejected, so the
    validator is shown to actually constrain the change rather than merely describe it.

    README mutations are written to a temporary copy. Workflow and updater mutations are
    written to temporary copies too and passed in through -WorkflowPath / -UpdaterPath, so
    the real repository is never modified.

.EXAMPLE
    pwsh -File Test-ProfileV24Content-Mutations.ps1
#>
[CmdletBinding()]
param(
    [string]$ValidatorPath = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext\scripts\Test-ProfileV24Content.ps1',
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext'
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$readmeSource = Join-Path $RepositoryRoot 'README.md'
$workflowSource = Join-Path $RepositoryRoot '.github\workflows\profile-activity.yml'
$updaterSource = Join-Path $RepositoryRoot 'scripts\update-activity.py'

$readmeText = $utf8NoBom.GetString([IO.File]::ReadAllBytes($readmeSource))
$workflowText = $utf8NoBom.GetString([IO.File]::ReadAllBytes($workflowSource))
$updaterText = $utf8NoBom.GetString([IO.File]::ReadAllBytes($updaterSource))

# name => @{ target = 'readme'|'workflow'|'updater'; description; transform }
$mutations = [ordered]@{
    'laya-icon-resized' = @{ target = 'readme'; description = 'Laya icon 52 -> 48'; transform = { param($t) $t.Replace('970dc8c5f63d7b886a68409493f37d569424f933/assets/logo-mark.svg" width="52" height="52"', '970dc8c5f63d7b886a68409493f37d569424f933/assets/logo-mark.svg" width="48" height="48"') } }
    'qwen-icon-resized' = @{ target = 'readme'; description = 'Qwen icon 52 -> 48'; transform = { param($t) $t.Replace('3822ec7173d17cf37c8a02f51d3ed5628079e86e/scripts/pack/assets/icon.svg" width="52" height="52"', '3822ec7173d17cf37c8a02f51d3ed5628079e86e/scripts/pack/assets/icon.svg" width="48" height="48"') } }
    'agent-icons-left-at-old-size' = @{ target = 'readme'; description = 'Agent OSS back to 20px'; transform = { param($t) $t.Replace('u/252820863?v=4" width="24" height="24"', 'u/252820863?v=4" width="20" height="20"') } }
    'agent-icons-oversized-past-cliff' = @{ target = 'readme'; description = 'Agent OSS at 28px, which collapses the 2x2'; transform = { param($t) $t.Replace('u/252820863?v=4" width="24" height="24"', 'u/252820863?v=4" width="28" height="28"') } }
    'ragflow-aspect-ratio-broken' = @{ target = 'readme'; description = 'RAGFlow 23 -> 24 width'; transform = { param($t) $t.Replace('313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="23" height="24"', '313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="24" height="24"') } }
    'one-agent-icon-dropped' = @{ target = 'readme'; description = 'Dify icon removed'; transform = { param($t) $t -replace '<a href="https://github\.com/langgenius/dify/pulls\?q=is%3Apr\+author%3ABruce-Yii\+is%3Amerged"><img[^>]*/></a>', '' } }
    'icon-cell-widened' = @{ target = 'readme'; description = 'icon cell 84 -> 120'; transform = { param($t) $t.Replace('<td width="84" align="center" valign="top">', '<td width="120" align="center" valign="top">') } }
    'activity-timeline-re-added' = @{ target = 'readme'; description = 'activity entry reinserted'; transform = { param($t) $t.Replace('## Contributions', "## Recent OSS activity`r`n`r`n<!-- OSS-ACTIVITY:START -->`r`n- 2026-09-25 — `x/y#1` merged — nope`r`n<!-- OSS-ACTIVITY:END -->`r`n`r`n## Contributions") } }
    'constellation-grid-disturbed' = @{ target = 'readme'; description = 'constellation cell 25% -> 20%'; transform = { param($t) $t.Replace('<td width="25%" align="center" valign="middle">', '<td width="20%" align="center" valign="middle">') } }
    'footprint-copy-altered' = @{ target = 'readme'; description = 'footprint line reworded'; transform = { param($t) $t.Replace('contributions across 14 external upstream repositories', 'contributions across 15 external upstream repositories') } }
    'hologram-dropped' = @{ target = 'readme'; description = 'second hologram removed'; transform = { param($t) $t.Replace('assets/hologram-2.gif', 'assets/hologram-1.gif') } }
    'snake-asset-dropped' = @{ target = 'readme'; description = 'snake reference removed'; transform = { param($t) $t.Replace('dist/github-snake.svg', 'dist/github-snake-dark.svg') } }
    'schedule-restored' = @{ target = 'workflow'; description = 'weekly schedule re-enabled'; transform = { param($t) $t.Replace('  workflow_dispatch:', "  schedule:`r`n    - cron: `"0 1 * * 1`"`r`n  workflow_dispatch:") } }
    'schedule-restored-quoted-key' = @{ target = 'workflow'; description = 'schedule re-enabled with a quoted key'; transform = { param($t) $t.Replace('  workflow_dispatch:', "  `"schedule`":`r`n    - cron: `"0 1 * * 1`"`r`n  workflow_dispatch:") } }
    'schedule-restored-flow-style' = @{ target = 'workflow'; description = 'schedule re-enabled in YAML flow style'; transform = { param($t) $t.Replace("  # The OSS-ACTIVITY markers were removed from README.md in v2.4, so this job has`r`n  # nothing left to refresh. Manual runs only; re-enable the schedule if the`r`n  # activity timeline is ever brought back.`r`n  workflow_dispatch:", '  workflow_dispatch: null' + "`r`n" + 'unused: {schedule: [{cron: "0 1 * * 1"}]}') } }
    'manual-trigger-removed' = @{ target = 'workflow'; description = 'workflow_dispatch removed'; transform = { param($t) $t.Replace('  workflow_dispatch:', '  # disabled entirely') } }
    'updater-guard-removed' = @{ target = 'updater'; description = 'marker guard deleted from update-activity.py'; transform = { param($t) $t.Replace('markers missing, refusing to rewrite', 'proceeding anyway') } }
}

$tempDir = Join-Path ([IO.Path]::GetTempPath()) ("yu143-mut-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tempDir | Out-Null

$readmeTemp = Join-Path $tempDir 'README.md'
$workflowTemp = Join-Path $tempDir 'profile-activity.yml'
$updaterTemp = Join-Path $tempDir 'update-activity.py'

$survived = @()
try {
    $utf8NoBom.GetBytes($readmeText) | Set-Content -LiteralPath $readmeTemp -AsByteStream -NoNewline
    $utf8NoBom.GetBytes($workflowText) | Set-Content -LiteralPath $workflowTemp -AsByteStream -NoNewline
    $utf8NoBom.GetBytes($updaterText) | Set-Content -LiteralPath $updaterTemp -AsByteStream -NoNewline

    & $ValidatorPath -RepositoryRoot $RepositoryRoot -ActualReadme $readmeTemp -WorkflowPath $workflowTemp -UpdaterPath $updaterTemp | Out-Null
    Write-Output 'control: unmutated files accepted (expected)'

    foreach ($entry in $mutations.GetEnumerator()) {
        $name = $entry.Key
        $spec = $entry.Value
        $source = switch ($spec.target) { 'readme' { $readmeText } 'workflow' { $workflowText } 'updater' { $updaterText } }

        $mutated = & $spec.transform $source
        if ($mutated -ceq $source) {
            throw "Mutation '$name' did not change anything, so it cannot test anything."
        }

        switch ($spec.target) {
            'readme' { $utf8NoBom.GetBytes($mutated) | Set-Content -LiteralPath $readmeTemp -AsByteStream -NoNewline }
            'workflow' { $utf8NoBom.GetBytes($mutated) | Set-Content -LiteralPath $workflowTemp -AsByteStream -NoNewline }
            'updater' { $utf8NoBom.GetBytes($mutated) | Set-Content -LiteralPath $updaterTemp -AsByteStream -NoNewline }
        }

        $rejected = $false
        $reason = ''
        try {
            & $ValidatorPath -RepositoryRoot $RepositoryRoot -ActualReadme $readmeTemp -WorkflowPath $workflowTemp -UpdaterPath $updaterTemp | Out-Null
        }
        catch {
            $rejected = $true
            $reason = $_.Exception.Message
        }

        if ($rejected) {
            Write-Output "rejected: $name ($($spec.description))"
        }
        else {
            $survived += $name
            Write-Output "SURVIVED: $name ($($spec.description))"
        }
    }
}
finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($survived.Count -gt 0) {
    throw "Content gate accepted $($survived.Count) unauthorised mutation(s): $($survived -join ', ')"
}

Write-Output "All $($mutations.Count) unauthorised mutations rejected."
