<#
.SYNOPSIS
    Byte-exact copy-only validator for Bruce-Yii/Bruce-Yii GitHub Profile v2.2 (YU-130).

.DESCRIPTION
    Reconstructs the approved target README from a frozen baseline commit by applying an
    explicit list of single-occurrence copy replacements, then asserts the working-tree
    README matches that target byte for byte.

    The full-text equality check is what makes this a copy-only gate: it transitively
    proves that layout, HTML structure, icons, asset URLs, evidence links, activity
    entries and localized counts did not change, because any drift anywhere in the file
    breaks the equality.

    Usage (defaults target the workspace profile clone):
        pwsh -File Test-ProfileV22CopyOnly.ps1
        pwsh -File Test-ProfileV22CopyOnly.ps1 -BaselineRef <sha> -ActualReadme <path>

.NOTES
    Baseline 1976b79f6581166b78ba0b2a2cb7c63967023852 is the released v2.1 baseline,
    also frozen on-remote as branch profile-freeze-20260926-v2.1.

    This gate is pinned to the v2.2 release state. YU-131 (v2.3) intentionally restructured
    the Featured collaborations section, so this script no longer matches the live README.
    Use Test-ProfileV23Layout.ps1 to validate the current README; keep this one as the
    record of what the v2.2 copy-only change was allowed to touch.
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ActualReadme,
    [string]$BaselineRef = '1976b79f6581166b78ba0b2a2cb7c63967023852'
)

$ErrorActionPreference = 'Stop'

if (-not $ActualReadme) {
    $ActualReadme = Join-Path $RepositoryRoot 'README.md'
}

$baselineLines = & git -C $RepositoryRoot show "${BaselineRef}:README.md"
if ($LASTEXITCODE -ne 0) { throw "Unable to read baseline README at $BaselineRef" }
$baseline = (($baselineLines -join "`n").TrimEnd("`r", "`n"))
$actual = ([IO.File]::ReadAllText($ActualReadme).Replace("`r`n", "`n").TrimEnd("`r", "`n"))

# Each pair must match the baseline exactly once. Line-level deletion keeps the
# indentation and trailing newline so the hero badge paragraph stays well-formed.
$replacements = @(
    @(
        'I work across AI open-source projects on product behavior, integration contracts, developer workflows, and upstream implementation.',
        'I work across AI open-source projects on product behavior, integration contracts, developer workflows, and implementation work.'
    ),
    @(
        "  <img alt=`"Upstream`" src=`"https://img.shields.io/badge/Upstream-39_merged_PRs-blue`" />`n",
        ''
    ),
    @(
        '> **Current footprint:** 39 merged PRs across 14 external upstream repositories.',
        '> **Current footprint:** contributions across 14 external upstream repositories.'
    ),
    @(
        '> I optimize for useful upstream changes and maintainer trust, not PR volume.',
        '> I care about useful upstream changes and maintainer trust more than PR volume.'
    )
)

$expected = $baseline
foreach ($replacement in $replacements) {
    $old = $replacement[0]
    $new = $replacement[1]
    $occurrences = [regex]::Matches($expected, [regex]::Escape($old)).Count
    if ($occurrences -ne 1) {
        throw "Baseline replacement must match exactly once, matched $occurrences`: $old"
    }
    $expected = $expected.Replace($old, $new)
}

if ($actual -cne $expected) {
    throw 'README does not match the approved YU-130 copy-only target.'
}

# The global merged-PR volume metric is the whole point of YU-130 and must not return.
$forbidden = @(
    'Upstream-39_merged_PRs',
    '39 merged PRs',
    'I optimize for useful upstream changes'
)
foreach ($phrase in $forbidden) {
    if ($actual.Contains($phrase)) {
        throw "Removed global vanity metric or stale copy remains: $phrase"
    }
}

# Breadth badge and the localized per-repo proof stay.
$required = @(
    'contributions across 14 external upstream repositories',
    'I care about useful upstream changes and maintainer trust more than PR volume.',
    'External_repos-14-2ea44f',
    'Focus-Agent_%26_AI_Product-8A2BE2',
    'ghpvc/?username=Bruce-Yii',
    '5 merged PRs',
    'OpenClaw ×4',
    'Dify ×3',
    'Cherry ×4',
    'RAGFlow ×4',
    '<!-- OSS-ACTIVITY:START -->',
    '<!-- OSS-ACTIVITY:END -->',
    'assets/hologram-1.gif',
    'assets/hologram-2.gif'
)
foreach ($phrase in $required) {
    if (-not $actual.Contains($phrase)) {
        throw "Required copy or invariant missing: $phrase"
    }
}

# Three badges is the mobile-validated geometry. Measured at 390px the v2.1 four-badge
# row rendered on two lines (534px); a longer replacement badge forced three ragged
# lines (596px), so the badge was removed instead of reworded.
$heroBadgeBlock = [regex]::Match(
    $actual,
    '(?s)<p>\s*<img[^>]*alt="Profile views"[^>]*/>.*?</p>'
).Value
$heroBadgeCount = [regex]::Matches($heroBadgeBlock, '<img').Count
if ($heroBadgeCount -ne 3) {
    throw "Hero badge row must keep exactly 3 badges, found $heroBadgeCount"
}

Write-Output 'YU-130 copy-only verification passed.'
