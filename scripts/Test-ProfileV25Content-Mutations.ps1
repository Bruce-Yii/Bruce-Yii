<#
.SYNOPSIS
    Adversarial self-test for Test-ProfileV25Content.ps1 (YU-151).

.DESCRIPTION
    Applies the changes YU-151 explicitly did *not* authorise and asserts each is
    rejected, so the gate is shown to constrain the change rather than describe it.
    README mutations are written to a temporary copy; the real repository is untouched.

.EXAMPLE
    pwsh -File Test-ProfileV25Content-Mutations.ps1
#>
[CmdletBinding()]
param(
    [string]$ValidatorPath = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext\scripts\Test-ProfileV25Content.ps1',
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext'
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$source = Join-Path $RepositoryRoot 'README.md'
$readme = $utf8NoBom.GetString([IO.File]::ReadAllBytes($source))

$mutations = [ordered]@{
    'reserved-line-removed-from-laya' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya</b></sub>') }
    'reserved-line-missing-on-cherry' = { param($t) $t.Replace('<sub><b>Cherry<br/><br/></b></sub>', '<sub><b>Cherry</b></sub>') }
    'reserved-line-added-to-a-two-line-label' = { param($t) $t.Replace('<sub><b>Qwen<br/>Paw</b></sub>', '<sub><b>Qwen<br/>Paw<br/><br/></b></sub>') }
    'all-four-labels-stripped' = { param($t) ($t -replace '<sub><b>(Laya|FunASR|Dify|Cherry)<br/><br/></b></sub>', '<sub><b>$1</b></sub>') }
    'nbsp-spacer-reintroduced' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya</b><br/>&nbsp;</sub>') }
    'collapsing-single-break-substituted' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya<br/></b></sub>') }
    'zero-width-space-substituted' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya<br/>&#8203;</b></sub>') }
    'raw-zero-width-byte-substituted' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', "<sub><b>Laya<br/>$([char]0x200B)</b></sub>") }
    'icon-cell-left-top-aligned' = { param($t) $t.Replace('<td width="84" align="center" valign="middle">', '<td width="84" align="center" valign="top">') }
    'one-icon-cell-reverted' = {
        param($t)
        $needle = '<td width="84" align="center" valign="middle">'
        $replacement = '<td width="84" align="center" valign="top">'
        $i = $t.LastIndexOf($needle)
        if ($i -lt 0) { return $t }
        $t.Substring(0, $i) + $replacement + $t.Substring($i + $needle.Length)
    }
    'agent-icons-pushed-to-the-cliff' = { param($t) $t.Replace('u/252820863?v=4" width="25" height="25"', 'u/252820863?v=4" width="27" height="27"') }
    'agent-icons-back-to-24' = { param($t) $t.Replace('u/252820863?v=4" width="25" height="25"', 'u/252820863?v=4" width="24" height="24"') }
    'ragflow-forced-square' = { param($t) $t.Replace('313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="24" height="25"', '313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="25" height="25"') }
    'laya-icon-resized' = { param($t) $t.Replace('970dc8c5f63d7b886a68409493f37d569424f933/assets/logo-mark.svg" width="52" height="52"', '970dc8c5f63d7b886a68409493f37d569424f933/assets/logo-mark.svg" width="48" height="48"') }
    'constellation-reduced-to-three-columns' = { param($t) $t.Replace('<td width="25%" align="center" valign="middle">', '<td width="33%" align="center" valign="middle">') }
    'constellation-icon-url-repinned' = { param($t) $t.Replace('970dc8c5f63d7b886a68409493f37d569424f933', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') }
    'constellation-dark-mode-source-dropped' = { param($t) $t -replace '<source media="\(prefers-color-scheme: dark\)" srcset="[^"]*" />', '' }
    'card-copy-reworded' = { param($t) $t.Replace('OpenClaw ×4 · Dify ×3 · Cherry ×4 · RAGFlow ×4', 'OpenClaw ×4 · Dify ×3 · Cherry ×4') }
    'hologram-dropped' = { param($t) $t.Replace('assets/hologram-2.gif', 'assets/hologram-1.gif') }
    'activity-timeline-re-added' = { param($t) $t.Replace('## Contributions', "## Recent OSS activity`r`n`r`n<!-- OSS-ACTIVITY:START -->`r`n- 2026-09-25 — `x/y#1` merged — nope`r`n<!-- OSS-ACTIVITY:END -->`r`n`r`n## Contributions") }
}

$tempDir = Join-Path ([IO.Path]::GetTempPath()) ("yu151-mut-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tempDir | Out-Null
$temp = Join-Path $tempDir 'README.md'

$survived = @()
try {
    $utf8NoBom.GetBytes($readme) | Set-Content -LiteralPath $temp -AsByteStream -NoNewline
    & $ValidatorPath -RepositoryRoot $RepositoryRoot -ActualReadme $temp | Out-Null
    Write-Output 'control: unmutated README accepted (expected)'

    foreach ($entry in $mutations.GetEnumerator()) {
        $name = $entry.Key
        $mutated = & $entry.Value $readme
        if ($mutated -ceq $readme) { throw "Mutation '$name' changed nothing, so it cannot test anything." }
        $utf8NoBom.GetBytes($mutated) | Set-Content -LiteralPath $temp -AsByteStream -NoNewline

        $rejected = $false
        try { & $ValidatorPath -RepositoryRoot $RepositoryRoot -ActualReadme $temp | Out-Null }
        catch { $rejected = $true }

        if ($rejected) { Write-Output "rejected: $name" }
        else { $survived += $name; Write-Output "SURVIVED: $name" }
    }
}
finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($survived.Count -gt 0) { throw "Gate accepted $($survived.Count) unauthorised mutation(s): $($survived -join ', ')" }
Write-Output "All $($mutations.Count) unauthorised mutations rejected."
