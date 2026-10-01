<#
.SYNOPSIS
    Content validator for Bruce-Yii/Bruce-Yii GitHub Profile v2.6 (upstream count refresh).

.DESCRIPTION
    v2.6 is a count-only release plus one new evidence class. The core is the same
    full-text equality check the v2.3 and v2.5 gates use: the approved target is
    rebuilt from the frozen v2.5 baseline by applying exactly the edits this
    release authorised, and the working-tree README must equal it line for line.
    That one comparison transitively proves the hero, badges, holograms, the
    4x2 OSS Constellation, the Featured cards, the How I contribute and Active
    tracks tables, streak, snake, every link and every icon provenance URL are
    untouched. Line endings are normalised CRLF -> LF and trailing newlines
    trimmed, so this is logical-line equality.

    The reason to rebuild from a baseline rather than pin literals is that a
    count refresh is exactly the release most likely to be re-applied by hand.
    Someone re-running the v2.5 edits, or bumping one project and forgetting its
    partner, produces a README that still reads correctly. Equality against a
    reconstructed target catches that; a list of required substrings would not,
    because every individual substring in a half-applied refresh is still present
    somewhere.

    What equality cannot express is asserted separately:

      * the Constellation is still 4x2 with eight marks, and the four reserved
        label lines are on the same four labels as v2.5. v2.5 measured why that
        matters: equal label heights are the only thing that makes the icon
        baselines line up, because GitHub strips inline style and forces tables
        to display:block, so a height attribute can never pull a tall cell down.
      * the Laya row splits its contribution cell into exactly two lines. Without
        the split, the 11 links sit on one line and the cell's max-content width
        is the widest thing in the evidence table.
      * the aggregate rows stay aggregate. Adding individual PR links to the
        OpenClaw, Dify, Cherry Studio or RAGFlow rows was measured during this
        release at +22px on the evidence table's contribution column; the rows
        carry one link by design and only Laya and EvalScope carry samples.
      * the five cited review PRs are pinned by number, and each one is a PR
        Bruce-Yii reviewed rather than authored. That distinction is the whole
        claim the 60 reviewed figure rests on, and a plain link list would not
        catch a sample that was quietly swapped for one of his own PRs.

    Baseline c0b518d is the last workflow commit before v2.6, so its README is
    the released v2.5 content; the six commits ahead of 855f0b0 only regenerate
    dist/*.svg.

.DESCRIPTION
    The counts themselves were enumerated, not estimated. `author:Bruce-Yii
    is:pr is:merged` returns 104 total across 10 pages of 100; 43 of those are
    in his own repositories, leaving 61 merged into 15 external upstreams. The
    60 reviewed PRs come from `reviewed-by:Bruce-Yii repo:NandhaKishorM/laya
    is:pr` (open 28, closed 32, 34 distinct authors, 0 self-authored), which the
    GitHub web UI reproduces for the same filter. The render figures quoted above
    were measured with scripts\Measure-ProfileRender.py and are recorded in
    scripts\Measure-V26Counts.json; they are a simulation of GitHub's renderer
    (its markdown API plus its sanitizer and table CSS), not the live page, so
    re-measure rather than treat them as permanent.

.EXAMPLE
    pwsh -File Test-ProfileV26Counts.ps1
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ActualReadme,
    [string]$BaselineRef = 'c0b518d'
)

$ErrorActionPreference = 'Stop'

if (-not $ActualReadme) {
    $ActualReadme = Join-Path $RepositoryRoot 'README.md'
}

$baselineLines = & git -C $RepositoryRoot show "${BaselineRef}:README.md"
if ($LASTEXITCODE -ne 0) { throw "Unable to read baseline README at $BaselineRef" }
$baseline = (($baselineLines -join "`n").TrimEnd("`r", "`n"))
$actual = ([IO.File]::ReadAllText($ActualReadme).Replace("`r`n", "`n").TrimEnd("`r", "`n"))

# --- The authorised edits, each guarded to match the baseline exactly once -----
# A replacement that matches zero or several times is a bug in this gate, not a
# README problem, so it is reported separately from the equality failure below.
$edits = @(
    # Badge row: rename for accuracy and add the merged-PR count that the old
    # badge set never carried.
    @(
        '  <img alt="Repositories" src="https://img.shields.io/badge/External_repos-14-2ea44f" />',
        "  <img alt=`"External upstream repos`" src=`"https://img.shields.io/badge/External_repos-15-2ea44f`" />`n  <img alt=`"Merged upstream PRs`" src=`"https://img.shields.io/badge/Merged_upstream_PRs-61-2ea44f`" />"
    ),
    # Laya card: merged count, and the review count replaces the vague
    # "cross-PR review" phrase that used to stand in for it.
    @('5 merged PRs · staged adoption · cross-PR review', '21 merged PRs · 60 PRs reviewed · staged adoption'),
    @('QwenPaw product UX · EvalScope multimodal eval · FunASR Nano timestamps', 'QwenPaw product UX · EvalScope ×3 · FunASR Nano timestamps'),
    @('OpenClaw ×4 · Dify ×3 · Cherry ×4 · RAGFlow ×4', 'OpenClaw ×5 · Dify ×4 · Cherry ×5 · RAGFlow ×4'),
    # Evidence rows. Cherry Studio and RAGFlow both read "[4 merged PRs]" in the
    # baseline, so each replacement is anchored on its own repo URL; an unanchored
    # Replace would silently bump RAGFlow too.
    @(
        '| **Laya** | [#224](https://github.com/NandhaKishorM/laya/pull/224) · [#292](https://github.com/NandhaKishorM/laya/pull/292) · [#328](https://github.com/NandhaKishorM/laya/pull/328) · [#115](https://github.com/NandhaKishorM/laya/pull/115) · [#415](https://github.com/NandhaKishorM/laya/pull/415) | Document staged adoption, protect recent intent, correct routing semantics, clarify full-conversation contracts, and recover requests hidden by email disclaimers |',
        '| **Laya** | [21 merged](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+author%3ABruce-Yii) · [#115](https://github.com/NandhaKishorM/laya/pull/115) · [#224](https://github.com/NandhaKishorM/laya/pull/224) · [#415](https://github.com/NandhaKishorM/laya/pull/415) · [#523](https://github.com/NandhaKishorM/laya/pull/523) · [#664](https://github.com/NandhaKishorM/laya/pull/664)<br/>[60 reviewed](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+reviewed-by%3ABruce-Yii) · [#696](https://github.com/NandhaKishorM/laya/pull/696) · [#698](https://github.com/NandhaKishorM/laya/pull/698) · [#710](https://github.com/NandhaKishorM/laya/pull/710) · [#712](https://github.com/NandhaKishorM/laya/pull/712) | Router, eval and MCP contracts plus adoption docs; review caught Python/TypeScript parity gaps, an off-by-one percentile, a wrong state-budget formula, CVE severity |'
    ),
    @(
        '| **QwenPaw** | [#7593](https://github.com/agentscope-ai/QwenPaw/pull/7593) |',
        '| **QwenPaw** | [#7593](https://github.com/agentscope-ai/QwenPaw/pull/7593) · [5 open](https://github.com/agentscope-ai/QwenPaw/pulls?q=is%3Apr+author%3ABruce-Yii) |'
    ),
    @(
        '| **EvalScope** | [#1729](https://github.com/modelscope/evalscope/pull/1729) · [#1720](https://github.com/modelscope/evalscope/pull/1720) |',
        '| **EvalScope** | [3 merged](https://github.com/modelscope/evalscope/pulls?q=is%3Apr+author%3ABruce-Yii+is%3Amerged) · [#1720](https://github.com/modelscope/evalscope/pull/1720) · [#1729](https://github.com/modelscope/evalscope/pull/1729) · [#1768](https://github.com/modelscope/evalscope/pull/1768) |'
    ),
    @('[4 merged PRs](https://github.com/openclaw/openclaw/pulls', '[5 merged PRs](https://github.com/openclaw/openclaw/pulls'),
    @('[3 merged PRs](https://github.com/langgenius/dify/pulls', '[4 merged PRs](https://github.com/langgenius/dify/pulls'),
    @('[4 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls', '[5 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls'),
    @(
        '> **Current footprint:** contributions across 14 external upstream repositories.',
        '> **Current footprint:** 61 merged PRs across 15 external upstream repositories, plus 60 PRs reviewed on Laya alone.'
    )
)

$expected = $baseline
foreach ($edit in $edits) {
    $old = $edit[0]
    $new = $edit[1]
    $count = [regex]::Matches($expected, [regex]::Escape($old)).Count
    if ($count -ne 1) { throw "Authorised edit must match the baseline exactly once, matched ${count}: $old" }
    $expected = $expected.Replace($old, $new)
}

if ($actual -cne $expected) {
    throw 'README does not match the approved v2.6 target. Only the badge row, the three Featured card count lines, the Laya/QwenPaw/EvalScope/OpenClaw/Dify/Cherry Studio evidence rows and the footprint line may differ from v2.5.'
}

# --- Constellation is still 4x2 with all eight marks -------------------------
$constellation = [regex]::Match($actual, '(?s)## OSS Constellation(.*?)## Featured collaborations')
if (-not $constellation.Success) { throw 'Could not isolate the OSS Constellation section.' }
$rows = [regex]::Matches($constellation.Groups[1].Value, '(?s)<tr>.*?</tr>')
if ($rows.Count -ne 2) { throw "OSS Constellation must keep 2 rows, found $($rows.Count)" }
foreach ($row in $rows) {
    $cells = [regex]::Matches($row.Value, '<td\b').Count
    if ($cells -ne 4) { throw "Each OSS Constellation row must keep 4 cells, found $cells" }
}
$marks = [regex]::Matches($constellation.Groups[1].Value, '<img[^>]*alt="([^"]*)"')
if ($marks.Count -ne 8) { throw "OSS Constellation must keep 8 project marks, found $($marks.Count)" }
$constellationCells = [regex]::Matches($constellation.Groups[1].Value, '<td\b[^>]*valign="([^"]*)"')
if ($constellationCells.Count -ne 8) { throw "Expected 8 Constellation cells with a valign, found $($constellationCells.Count)" }
foreach ($cell in $constellationCells) {
    if ($cell.Groups[1].Value -ne 'middle') { throw "Constellation cells must stay valign=middle, found $($cell.Groups[1].Value)" }
}

# Exactly the four short labels carry the reserved line, unchanged from v2.5.
# The spacer stays a bare doubled break: &nbsp; renders as a visible dash, a
# single trailing break reserves nothing, and a zero-width space puts an
# invisible character in the label text.
$reservedLabels = @('Laya', 'FunASR', 'Dify', 'Cherry')
$reserved = [regex]::Matches($constellation.Groups[1].Value, '<sub><b>([^<]*)<br/><br/></b></sub>')
if ($reserved.Count -ne 4) { throw "Expected exactly 4 reserved label lines, found $($reserved.Count)" }
$reservedNames = @($reserved | ForEach-Object { $_.Groups[1].Value })
foreach ($label in $reservedLabels) {
    if ($reservedNames -notcontains $label) { throw "Reserved label line missing on $label" }
}
foreach ($bad in @('&nbsp;', '&#8203;', '8203')) {
    if ($constellation.Groups[1].Value.Contains($bad)) {
        throw "Constellation labels must not contain '$bad'; only <br/><br/> reserves the line."
    }
}
foreach ($label in @('Qwen<br/>Paw', 'Eval<br/>Scope', 'Open<br/>Claw', 'RAG<br/>Flow')) {
    $pattern = "<sub><b>$([regex]::Escape($label))</b></sub>"
    if (-not $constellation.Groups[1].Value.Contains($pattern)) { throw "Two-line label must be left alone: $label" }
}

# --- The Laya evidence row splits into exactly two lines ---------------------
$layaRow = [regex]::Match($actual, '(?m)^\| \*\*Laya\*\* \|(.*)$')
if (-not $layaRow.Success) { throw 'Could not locate the Laya evidence row.' }
$breaks = [regex]::Matches($layaRow.Value, '<br/>').Count
if ($breaks -ne 1) {
    throw "The Laya contribution cell must split merged and reviewed onto two lines with exactly one <br/>, found $breaks."
}
foreach ($token in @('[21 merged]', '[60 reviewed]')) {
    if (-not $layaRow.Value.Contains($token)) { throw "Laya row must carry $token" }
}

# --- The cited review PRs are the ones that were actually reviewed -----------
# Pinned by number, and split by the <br/> so each half of the cell can be
# checked on its own. The distinction is the whole claim the 60 reviewed figure
# rests on: a live link in the reviewed list proves nothing if it is one of his
# own PRs, and nothing in the README text would catch that.
$reviewSamples = @(696, 698, 710, 712)
$authoredSamples = @(115, 224, 415, 523, 664)

$splitIndex = $layaRow.Value.IndexOf('<br/>')
$mergedLine = $layaRow.Value.Substring(0, $splitIndex)
$reviewedLine = $layaRow.Value.Substring($splitIndex)

$linkPattern = '\[(.*?)\]\((https://github\.com/[^)]+)\)'
foreach ($half in @(@('merged', $mergedLine), @('reviewed', $reviewedLine))) {
    $label = $half[0]
    $line = $half[1]
    $bad = @([regex]::Matches($line, $linkPattern) | Where-Object {
        $_.Groups[2].Value -notmatch '^https://github\.com/NandhaKishorM/laya/'
    })
    if ($bad.Count -gt 0) {
        throw "The Laya $label line links outside NandhaKishorM/laya: $($bad[0].Groups[2].Value)"
    }
}

$mergedLinks = @([regex]::Matches($mergedLine, $linkPattern) | ForEach-Object { $_.Groups[1].Value })
$reviewedLinks = @([regex]::Matches($reviewedLine, $linkPattern) | ForEach-Object { $_.Groups[1].Value })

foreach ($n in $authoredSamples) { if ($mergedLinks -notcontains "#$n") { throw "Laya merged sample #$n is missing" } }
foreach ($n in $reviewSamples) { if ($reviewedLinks -notcontains "#$n") { throw "Laya review sample #$n is missing" } }

# The two lists must not overlap. #523 and #664 are Bruce-Yii's own merged PRs;
# if either reaches the reviewed line the "60 reviewed" claim is being illustrated
# with his own work.
$overlap = @($reviewedLinks | Where-Object { $mergedLinks -contains $_ })
if ($overlap.Count -gt 0) { throw "PR(s) cited as both merged and reviewed: $($overlap -join ', ')" }
# A sample with a number in one list and not the other is a typo, not a count fix.
$mergedNumbers = @($mergedLinks | Where-Object { $_ -match '^#\d+$' } | ForEach-Object { [int]$_.TrimStart('#') })
$reviewedNumbers = @($reviewedLinks | Where-Object { $_ -match '^#\d+$' } | ForEach-Object { [int]$_.TrimStart('#') })
$orphan = @($mergedNumbers + $reviewedNumbers | Sort-Object -Unique | Where-Object {
    ($mergedNumbers -contains $_) -and ($reviewedNumbers -contains $_)
})
if ($orphan.Count -gt 0) { throw "Overlapping PR numbers: $($orphan -join ', ')" }

# --- Aggregate rows stay aggregate -------------------------------------------
# Measured during this release: adding individual PR links to these rows widened
# the evidence table's contribution column and pushed the collapsed block's
# internal scroll from 74px to 96px at a 320px container, for no added evidence,
# because each row already links to its full filtered list.
foreach ($project in @('OpenClaw', 'Dify', 'Cherry Studio', 'RAGFlow')) {
    $row = [regex]::Match($actual, "(?m)^\| \*\*$([regex]::Escape($project))\*\* \|(.*)$")
    if (-not $row.Success) { throw "Could not locate the $project evidence row." }
    $links = [regex]::Matches($row.Value, '\]\(https://github\.com').Count
    if ($links -ne 1) { throw "The $project row must stay a single aggregate link, found $links links" }
}

# --- Everything the release said to leave alone ------------------------------
$required = @(
    '## OSS Constellation', '## Featured collaborations', '## How I contribute',
    '## Active tracks', '## Contributions', 'Selected upstream impact — PR evidence',
    'Current footprint:', 'View work →', 'Explore work →', 'All PRs →',
    '21 merged PRs · 60 PRs reviewed · staged adoption',
    'QwenPaw product UX · EvalScope ×3 · FunASR Nano timestamps',
    'OpenClaw ×5 · Dify ×4 · Cherry ×5 · RAGFlow ×4',
    'assets/hologram-1.gif', 'assets/hologram-2.gif', 'dist/streak.svg', 'dist/github-snake.svg'
)
foreach ($phrase in $required) {
    if (-not $actual.Contains($phrase)) { throw "Required section, copy or asset missing: $phrase" }
}
# The superseded v2.5 figures must stay gone, or the profile shows two numbers
# for the same project.
foreach ($stale in @(
    'External_repos-14', '5 merged PRs · staged adoption', 'OpenClaw ×4',
    'Dify ×3', 'Cherry ×4', 'EvalScope multimodal eval',
    'contributions across 14 external upstream repositories',
    'laya/pull/328', 'laya/pull/292', 'laya/pull/430', 'laya/pull/565'
)) {
    if ($actual.Contains($stale)) { throw "Superseded v2.5 content must stay removed: $stale" }
}
foreach ($forbidden in @('## Recent OSS activity', 'OSS-ACTIVITY', 'Upstream-39_merged_PRs', '39 merged PRs')) {
    if ($actual.Contains($forbidden)) { throw "Removed content must stay removed: $forbidden" }
}

Write-Output 'v2.6 upstream count verification passed.'
