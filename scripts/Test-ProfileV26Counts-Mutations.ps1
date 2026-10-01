<#
.SYNOPSIS
    Adversarial self-test for Test-ProfileV26Counts.ps1 (v2.6).

.DESCRIPTION
    Applies the changes v2.6 explicitly did *not* authorise and asserts each is
    rejected, so the gate is shown to constrain the release rather than describe
    it. A validator that only ever passes is indistinguishable from no validator.

    The mutations are weighted toward what this particular release could plausibly
    get wrong rather than toward generic vandalism. A count refresh gets re-applied
    by hand, so several cases are half-applied or inconsistently-applied refreshes
    where every remaining substring still reads correctly. Two cases target the new
    evidence class specifically: moving one of Bruce-Yii's own merged PRs into the
    reviewed list, and deleting the line break that keeps the Laya cell two lines
    wide. One case replays the width regression that was measured and reverted
    during this release.

    README mutations are written to a single scratch file inside the project's own
    temp directory and removed with a plain non-recursive delete, so nothing here
    needs a recursive remove and nothing lands outside the workspace. The real
    repository is never touched.

.EXAMPLE
    pwsh -File Test-ProfileV26Counts-Mutations.ps1
#>
[CmdletBinding()]
param(
    [string]$ValidatorPath = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext\scripts\Test-ProfileV26Counts.ps1',
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ScratchDirectory = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\temp'
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$source = Join-Path $RepositoryRoot 'README.md'
$readme = $utf8NoBom.GetString([IO.File]::ReadAllBytes($source))

if (-not (Test-Path -LiteralPath $ScratchDirectory)) {
    New-Item -ItemType Directory -Path $ScratchDirectory | Out-Null
}
$temp = Join-Path $ScratchDirectory ("v26-mutation-" + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.md')

$layaReviewLink = '[#712](https://github.com/NandhaKishorM/laya/pull/712)'

$mutations = [ordered]@{
    # --- Constellation must survive a count-only release -----------------------
    'constellation-reduced-to-three-columns' = { param($t) $t.Replace('<td width="25%" align="center" valign="middle">', '<td width="33%" align="center" valign="middle">') }
    'constellation-cell-repointed-to-another-project' = {
        # Silent grid drift: a constellation cell quietly retargeted at a different
        # upstream. Newline-independent on purpose, because the working tree is
        # CRLF (core.autocrlf) while the validator compares against an LF baseline.
        param($t)
        $t.Replace(
            'https://github.com/infiniflow/ragflow/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged',
            'https://github.com/openclaw/openclaw/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged'
        )
    }
    'reserved-line-removed-from-laya' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya</b></sub>') }
    'reserved-line-missing-on-dify' = { param($t) $t.Replace('<sub><b>Dify<br/><br/></b></sub>', '<sub><b>Dify</b></sub>') }
    'reserved-line-added-to-a-two-line-label' = { param($t) $t.Replace('<sub><b>Qwen<br/>Paw</b></sub>', '<sub><b>Qwen<br/>Paw<br/><br/></b></sub>') }
    'nbsp-spacer-reintroduced' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya</b><br/>&nbsp;</sub>') }
    'collapsing-single-break-substituted' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya<br/></b></sub>') }
    'constellation-icon-url-repinned' = { param($t) $t.Replace('970dc8c5f63d7b886a68409493f37d569424f933', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') }
    'constellation-dark-mode-source-dropped' = { param($t) $t -replace '<source media="\(prefers-color-scheme: dark\)" srcset="[^"]*" />', '' }
    'hologram-dropped' = { param($t) $t.Replace('assets/hologram-2.gif', 'assets/hologram-1.gif') }
    'featured-icon-cell-left-top-aligned' = { param($t) $t.Replace('<td width="84" align="center" valign="middle">', '<td width="84" align="center" valign="top">') }

    # --- Half-applied count refreshes: every surviving line still reads right ---
    'badge-left-at-14' = { param($t) $t.Replace('External_repos-15-2ea44f', 'External_repos-14-2ea44f') }
    'merged-pr-badge-dropped' = { param($t) $t -replace '\s*<img alt="Merged upstream PRs"[^>]*>', '' }
    'laya-card-count-regressed' = { param($t) $t.Replace('21 merged PRs · 60 PRs reviewed · staged adoption', '5 merged PRs · staged adoption · cross-PR review') }
    'laya-card-review-count-dropped' = { param($t) $t.Replace('21 merged PRs · 60 PRs reviewed · staged adoption', '21 merged PRs · staged adoption') }
    'agent-oss-cherry-regressed' = { param($t) $t.Replace('OpenClaw ×5 · Dify ×4 · Cherry ×5 · RAGFlow ×4', 'OpenClaw ×5 · Dify ×4 · Cherry ×4 · RAGFlow ×4') }
    'agent-oss-partial-refresh' = { param($t) $t.Replace('OpenClaw ×5 · Dify ×4 · Cherry ×5 · RAGFlow ×4', 'OpenClaw ×4 · Dify ×3 · Cherry ×4 · RAGFlow ×4') }
    'dify-evidence-count-not-bumped' = { param($t) $t.Replace('[4 merged PRs](https://github.com/langgenius/dify/pulls', '[3 merged PRs](https://github.com/langgenius/dify/pulls') }
    'cherry-refresh-leaked-into-ragflow' = {
        # The unanchored refresh bug: "[4 merged PRs]" appears in both the Cherry
        # Studio and RAGFlow rows, so a Replace that is not anchored on the repo
        # URL bumps the wrong project and the profile shows RAGFlow at 5.
        param($t)
        $cherryReverted = $t.Replace('[5 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls', '[4 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls')
        $cherryReverted.Replace('[4 merged PRs](https://github.com/infiniflow/ragflow/pulls', '[5 merged PRs](https://github.com/infiniflow/ragflow/pulls')
    }
    'evalscope-third-link-dropped' = { param($t) $t.Replace(' · [#1768](https://github.com/modelscope/evalscope/pull/1768)', '') }
    'qwenpaw-open-count-dropped' = { param($t) $t.Replace(' · [5 open](https://github.com/agentscope-ai/QwenPaw/pulls?q=is%3Apr+author%3ABruce-Yii)', '') }
    'footprint-left-at-14-repos' = { param($t) $t.Replace('61 merged PRs across 15 external upstream repositories', 'contributions across 14 external upstream repositories') }
    'footprint-review-claim-dropped' = { param($t) $t.Replace('61 merged PRs across 15 external upstream repositories, plus 60 PRs reviewed on Laya alone.', '61 merged PRs across 15 external upstream repositories.') }

    # --- The new evidence class specifically ----------------------------------
    'reviewed-link-removed' = { param($t) $t.Replace('[60 reviewed](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+reviewed-by%3ABruce-Yii) · ', '') }
    'laya-cell-split-removed' = { param($t) $t.Replace('<br/>[60 reviewed]', ' [60 reviewed]') }
    'own-merged-pr-moved-into-reviewed-line' = {
        # #523 is one of Bruce-Yii's own merged PRs. Promoting it to review
        # evidence is the exact failure the reviewed/merged split exists to catch.
        param($t)
        $t.Replace($layaReviewLink, '[#523](https://github.com/NandhaKishorM/laya/pull/523)')
    }
    'review-sample-repointed-to-another-repo' = {
        param($t)
        $t.Replace('[#696](https://github.com/NandhaKishorM/laya/pull/696)', '[#696](https://github.com/modelscope/evalscope/pull/696)')
    }
    'review-sample-renumbered' = { param($t) $t.Replace('[#698](https://github.com/NandhaKishorM/laya/pull/698)', '[#699](https://github.com/NandhaKishorM/laya/pull/698)') }

    # --- The width regression that was measured and reverted -------------------
    'aggregate-row-given-individual-links' = {
        param($t)
        $t.Replace(
            '[5 merged PRs](https://github.com/openclaw/openclaw/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged)',
            '[5 merged PRs](https://github.com/openclaw/openclaw/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged) · [#141569](https://github.com/openclaw/openclaw/pull/141569) · [#144579](https://github.com/openclaw/openclaw/pull/144579)'
        )
    }
}

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
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
}

if ($survived.Count -gt 0) { throw "Gate accepted $($survived.Count) unauthorised mutation(s): $($survived -join ', ')" }
Write-Output "All $($mutations.Count) unauthorised mutations rejected."
