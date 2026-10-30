<#
.SYNOPSIS
    Adversarial self-test for Test-ProfileV27Counts.ps1 (v2.7).

.DESCRIPTION
    Applies the changes v2.7 explicitly did *not* authorise and asserts each is
    rejected, so the gate is shown to constrain the release rather than describe
    it. A validator that only ever passes is indistinguishable from no validator.

    Two clusters, weighted toward what this release could plausibly get wrong.

    The card cluster is not hypothetical: the first paste of the ghfind snippet
    into this profile carried `< img`, GitHub escaped it into visible text, and
    dark-mode viewers saw nothing wrong because the `<source>` still matched.
    That exact paste is replayed here, along with the neighbouring failures the
    same snippet invites — a dropped dark-mode source, a fallback pinned to the
    wrong theme, an alt text carrying a score that will go stale, a link
    repointed at another account.

    The count cluster is a refresh applied by hand, so several cases are
    half-applied or inconsistently-applied refreshes where every remaining
    substring still reads correctly. One case bumps a project v2.7 did not
    change (Dify stays at 4), one is an off-by-one on the headline figure, and
    one replays the unanchored-Replace bug: openclaw and cherry both read
    "[5 merged PRs]" in the v2.6 baseline, and ragflow read "[4 merged PRs]"
    alongside cherry, so a refresh that is not anchored on the repo URL moves
    the wrong project's number.

    README mutations are written to a single scratch file inside the project's
    own temp directory and removed with a plain non-recursive delete, so nothing
    here needs a recursive remove and nothing lands outside the workspace. The
    real repository is never touched.

.EXAMPLE
    pwsh -File Test-ProfileV27Counts-Mutations.ps1
#>
[CmdletBinding()]
param(
    [string]$ValidatorPath = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext\scripts\Test-ProfileV27Counts.ps1',
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
$temp = Join-Path $ScratchDirectory ("v27-mutation-" + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.md')

$layaReviewLink = '[#712](https://github.com/NandhaKishorM/laya/pull/712)'

$mutations = [ordered]@{
    # --- The card: the exact paste that shipped broken ------------------------
    'card-fallback-tag-spaced' = { param($t) $t.Replace('<img src="https://ghfind.com/api/card/mini/bruce-yii?theme=light"', '< img src="https://ghfind.com/api/card/mini/bruce-yii?theme=light"') }
    'card-anchor-closing-tag-spaced' = { param($t) $t.Replace('</picture></a>', '</picture></a >') }
    'card-block-dropped' = {
        param($t)
        $t -replace '(?s)\r?\n<p>\r?\n  <a href="https://ghfind\.com/u/bruce-yii[^"]*"><picture>.*?</picture></a>\r?\n</p>', ''
    }
    'card-dark-source-dropped' = {
        param($t)
        $t -replace '\s*<source media="\(prefers-color-scheme: dark\)" srcset="https://ghfind\.com/[^"]*" />', ''
    }
    'card-fallback-pinned-to-dark' = { param($t) $t.Replace('mini/bruce-yii?theme=light" alt="ghfind profile score card"', 'mini/bruce-yii?theme=dark" alt="ghfind profile score card"') }
    'card-alt-carries-a-score' = { param($t) $t.Replace('alt="ghfind profile score card"', 'alt="ghfind score card: Lv.84, top 9.6%"') }
    'card-repointed-to-another-account' = { param($t) $t.Replace('https://ghfind.com/api/card/mini/bruce-yii', 'https://ghfind.com/api/card/mini/someone-else') }
    'card-width-match-changed' = { param($t) $t.Replace('alt="ghfind profile score card" width="440"', 'alt="ghfind profile score card" width="420"') }

    # --- Counts: half-applied and inconsistently-applied refreshes -------------
    'merged-badge-left-at-61' = { param($t) $t.Replace('Merged_upstream_PRs-87-2ea44f', 'Merged_upstream_PRs-61-2ea44f') }
    'repo-badge-left-at-15' = { param($t) $t.Replace('External_repos-17-2ea44f', 'External_repos-15-2ea44f') }
    'footprint-off-by-one' = { param($t) $t.Replace('87 merged PRs across 17 external upstream repositories', '86 merged PRs across 17 external upstream repositories') }
    'laya-card-count-left-at-21' = { param($t) $t.Replace('40 merged PRs · 85 PRs reviewed · staged adoption', '21 merged PRs · 60 PRs reviewed · staged adoption') }
    'laya-card-review-count-dropped' = { param($t) $t.Replace('40 merged PRs · 85 PRs reviewed · staged adoption', '40 merged PRs · staged adoption') }
    'agent-oss-openclaw-left-at-5' = { param($t) $t.Replace('OpenClaw ×6 · Dify ×4 · Cherry ×6 · RAGFlow ×6', 'OpenClaw ×5 · Dify ×4 · Cherry ×6 · RAGFlow ×6') }
    'agent-oss-partial-refresh' = { param($t) $t.Replace('OpenClaw ×6 · Dify ×4 · Cherry ×6 · RAGFlow ×6', 'OpenClaw ×5 · Dify ×4 · Cherry ×5 · RAGFlow ×4') }
    'dify-bumped-without-being-asked' = { param($t) $t.Replace('[4 merged PRs](https://github.com/langgenius/dify/pulls', '[5 merged PRs](https://github.com/langgenius/dify/pulls') }
    'ragflow-evidence-left-at-4' = { param($t) $t.Replace('[6 merged PRs](https://github.com/infiniflow/ragflow/pulls', '[4 merged PRs](https://github.com/infiniflow/ragflow/pulls') }
    'refresh-leaked-into-wrong-project' = {
        # Unanchored-Replace bug: cherry and ragflow carried different numbers in
        # the baseline, but a refresh keyed only on the label moves whichever row
        # the replacement lands on first.
        param($t)
        $t.Replace('[6 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls', '[5 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls')
    }
    'laya-merged-count-not-refreshed' = { param($t) $t.Replace('[40 merged](https://github.com/NandhaKishorM/laya/pulls', '[21 merged](https://github.com/NandhaKishorM/laya/pulls') }
    'laya-review-count-not-refreshed' = { param($t) $t.Replace('[85 reviewed](https://github.com/NandhaKishorM/laya/pulls', '[60 reviewed](https://github.com/NandhaKishorM/laya/pulls') }

    # --- Constellation must survive a card-plus-count release -----------------
    'constellation-reduced-to-three-columns' = { param($t) $t.Replace('<td width="25%" align="center" valign="middle">', '<td width="33%" align="center" valign="middle">') }
    'reserved-line-removed-from-laya' = { param($t) $t.Replace('<sub><b>Laya<br/><br/></b></sub>', '<sub><b>Laya</b></sub>') }
    'constellation-cell-repointed-to-another-project' = {
        param($t)
        $t.Replace(
            'https://github.com/infiniflow/ragflow/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged',
            'https://github.com/openclaw/openclaw/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged'
        )
    }
    'hologram-dropped' = { param($t) $t.Replace('assets/hologram-2.gif', 'assets/hologram-1.gif') }

    # --- The merged/reviewed split --------------------------------------------
    'laya-cell-split-removed' = { param($t) $t.Replace('<br/>[85 reviewed]', ' [85 reviewed]') }
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
    'aggregate-row-given-individual-links' = {
        param($t)
        $t.Replace(
            '[6 merged PRs](https://github.com/openclaw/openclaw/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged)',
            '[6 merged PRs](https://github.com/openclaw/openclaw/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged) · [#141569](https://github.com/openclaw/openclaw/pull/141569)'
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
