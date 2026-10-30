<#
.SYNOPSIS
    Guard for profile README v2.7: refreshed upstream counts plus the ghfind card.

.DESCRIPTION
    v2.7 does two things to the profile and nothing else:

      1. Re-enumerates every number on the page. `author:Bruce-Yii is:pr
         is:merged` now returns 220 across three pages: 133 in his own
         repositories, 87 in 17 external upstreams. Laya accounts for 40 of the
         87 merged and 85 reviewed PRs (`reviewed-by:Bruce-Yii
         repo:NandhaKishorM/laya is:pr`, 0 self-authored). Per-project merged
         counts were re-queried per repository rather than counted off the
         aggregate: Laya 40, OpenClaw 6, Cherry Studio 6, RAGFlow 6, Dify 4,
         EvalScope 3, FunASR 1, QwenPaw 1 (+5 open).
      2. Embeds the ghfind mini score card under the header badges as a
         `<picture>` block, so a viewer in either GitHub theme gets the matching
         card variant.

    The card is the reason this generation exists at all beyond a count bump.
    The snippet ghfind's share block produces is hand-written HTML, and the
    first paste of it into this profile carried `< img` (a space after the
    angle bracket). GitHub's sanitiser does not repair that: it escapes the
    whole line into visible text, and because the `<source>` element still
    matches in dark mode the breakage is invisible to anyone viewing dark. Only
    a light-mode visitor saw raw markup. So the gate pins the block's exact
    shape, including that the fallback `<img>` is a real tag.

    Equality against the frozen baseline is the primary check, as in every
    generation before this one: a count refresh applied by hand can leave every
    individual substring correct while the page as a whole is half-refreshed,
    and a per-string assertion cannot see that.

    What equality cannot express is asserted separately, unchanged from v2.6
    unless noted:

      * the Constellation is still 4x2 with eight marks and the same four
        reserved label lines (v2.5 measured why: GitHub strips inline style, so
        only equal label heights keep the icon baselines aligned);
      * the Laya evidence row still splits merged and reviewed onto two lines;
      * the aggregate rows stay aggregate, and the five cited review PRs are
        still PRs he reviewed rather than authored;
      * the ghfind card appears exactly once, inside the header block, with a
        well-formed fallback image and both theme variants (v2.7 only).

.DESCRIPTION
    Baseline c0b518d is retained by v2.6. This generation freezes 4074f94 — the
    last workflow commit that still carries v2.6 content, not a branch tip,
    because the streak/snake workflows keep committing dist/*.svg on top of it.

.EXAMPLE
    pwsh -File Test-ProfileV27Counts.ps1
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ActualReadme,
    [string]$BaselineRef = '4074f94'
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
$card = @(
    '',
    '<p>',
    '  <a href="https://ghfind.com/u/bruce-yii?ref=badge"><picture>',
    '    <source media="(prefers-color-scheme: dark)" srcset="https://ghfind.com/api/card/mini/bruce-yii?theme=dark" />',
    '    <img src="https://ghfind.com/api/card/mini/bruce-yii?theme=light" alt="ghfind profile score card" width="440" />',
    '  </picture></a>',
    '</p>'
) -join "`n"

$edits = @(
    # The card sits inside the header block, directly under the badge row, so it
    # inherits the centred layout and needs no alignment attributes of its own.
    @(
        "  <img alt=`"Focus`" src=`"https://img.shields.io/badge/Focus-Agent_%26_AI_Product-8A2BE2`" />`n</p>`n`n</div>",
        "  <img alt=`"Focus`" src=`"https://img.shields.io/badge/Focus-Agent_%26_AI_Product-8A2BE2`" />`n</p>`n${card}`n`n</div>"
    ),
    # Badge row: 15 external upstreams became 17, 61 merged became 87.
    @('External_repos-15-2ea44f', 'External_repos-17-2ea44f'),
    @('Merged_upstream_PRs-61-2ea44f', 'Merged_upstream_PRs-87-2ea44f'),
    # Laya carries the largest single jump, 21 merged / 60 reviewed to 40 / 85.
    @('21 merged PRs · 60 PRs reviewed · staged adoption', '40 merged PRs · 85 PRs reviewed · staged adoption'),
    # Agent OSS card line. Dify is unchanged at 4 and must stay 4.
    @('OpenClaw ×5 · Dify ×4 · Cherry ×5 · RAGFlow ×4', 'OpenClaw ×6 · Dify ×4 · Cherry ×6 · RAGFlow ×6'),
    @(
        '[21 merged](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+author%3ABruce-Yii)',
        '[40 merged](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+author%3ABruce-Yii)'
    ),
    @(
        '[60 reviewed](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+reviewed-by%3ABruce-Yii)',
        '[85 reviewed](https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+reviewed-by%3ABruce-Yii)'
    ),
    # Cherry Studio and OpenClaw both read "[5 merged PRs]" in the baseline, so
    # each replacement is anchored on its own repo URL; an unanchored Replace
    # would bump the wrong project.
    @(
        '[5 merged PRs](https://github.com/openclaw/openclaw/pulls',
        '[6 merged PRs](https://github.com/openclaw/openclaw/pulls'
    ),
    @(
        '[5 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls',
        '[6 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls'
    ),
    @(
        '[4 merged PRs](https://github.com/infiniflow/ragflow/pulls',
        '[6 merged PRs](https://github.com/infiniflow/ragflow/pulls'
    ),
    @(
        '> **Current footprint:** 61 merged PRs across 15 external upstream repositories, plus 60 PRs reviewed on Laya alone.',
        '> **Current footprint:** 87 merged PRs across 17 external upstream repositories, plus 85 PRs reviewed on Laya alone.'
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
    throw 'README does not match the approved v2.7 target. Only the header card block, the two header badges, the three Featured card count lines, the Laya/QwenPaw/EvalScope/OpenClaw/Dify/Cherry Studio/RAGFlow evidence rows and the footprint line may differ from v2.6.'
}

# --- The ghfind card is well formed and appears exactly once -----------------
# The failure this guards against was shipped once: `< img` is escaped by the
# sanitiser into visible text, and only a light-mode viewer ever saw it.
$cardBlocks = [regex]::Matches($actual, '(?s)<a href="https://ghfind\.com/u/bruce-yii[^"]*"><picture>.*?</picture></a>')
if ($cardBlocks.Count -ne 1) { throw "Expected exactly 1 ghfind card block, found $($cardBlocks.Count)" }
$cardBlock = $cardBlocks[0].Value
foreach ($bad in @('< img', '</a >', '< picture', '</picture >')) {
    if ($cardBlock.Contains($bad)) { throw "ghfind card block contains a malformed tag: $bad" }
}
$cardDark = [regex]::Match($cardBlock, '<source media="\(prefers-color-scheme: dark\)" srcset="https://ghfind\.com/api/card/mini/bruce-yii\?theme=dark" />')
if (-not $cardDark.Success) { throw 'ghfind card dark-mode <source> is missing or repointed.' }
$cardLight = [regex]::Match($cardBlock, '<img src="https://ghfind\.com/api/card/mini/bruce-yii\?theme=light" alt="[^"]+" width="440" />')
if (-not $cardLight.Success) { throw 'ghfind card light-mode fallback <img> is missing or malformed.' }
# The card's own figures are rendered server side, so any number in the alt text
# is a hardcoded copy that will go stale. The alt must stay generic.
$altText = [regex]::Match($cardBlock, '<img[^>]*alt="([^"]*)"').Groups[1].Value
if ($altText -match '\d') { throw "ghfind card alt text must not carry a stale figure: $altText" }
# Inside the header block, i.e. above the first section heading.
$firstHeading = $actual.IndexOf('## OSS Constellation')
if ($firstHeading -lt 0) { throw 'Could not locate the OSS Constellation heading.' }
if ($actual.IndexOf($cardBlock) -gt $firstHeading) { throw 'ghfind card must stay inside the header block, above OSS Constellation.' }

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
foreach ($token in @('[40 merged]', '[85 reviewed]')) {
    if (-not $layaRow.Value.Contains($token)) { throw "Laya row must carry $token" }
}

# --- The cited review PRs are the ones that were actually reviewed -----------
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
# if either reaches the reviewed line the "85 reviewed" claim is being illustrated
# with his own work.
$overlap = @($reviewedLinks | Where-Object { $mergedLinks -contains $_ })
if ($overlap.Count -gt 0) { throw "PR(s) cited as both merged and reviewed: $($overlap -join ', ')" }

# --- Aggregate rows stay aggregate -------------------------------------------
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
    '40 merged PRs · 85 PRs reviewed · staged adoption',
    'QwenPaw product UX · EvalScope ×3 · FunASR Nano timestamps',
    'OpenClaw ×6 · Dify ×4 · Cherry ×6 · RAGFlow ×6',
    'External_repos-17-2ea44f', 'Merged_upstream_PRs-87-2ea44f',
    'assets/hologram-1.gif', 'assets/hologram-2.gif', 'dist/streak.svg', 'dist/github-snake.svg'
)
foreach ($phrase in $required) {
    if (-not $actual.Contains($phrase)) { throw "Required section, copy or asset missing: $phrase" }
}
# The superseded figures must stay gone, or the profile shows two numbers for the
# same thing.
foreach ($stale in @(
    'External_repos-14', 'External_repos-15', 'Merged_upstream_PRs-61',
    '21 merged PRs · 60 PRs reviewed', '[21 merged]', '[60 reviewed]',
    'OpenClaw ×5', 'Cherry ×5',
    '[5 merged PRs](https://github.com/openclaw/openclaw/pulls',
    '[5 merged PRs](https://github.com/CherryHQ/cherry-studio/pulls',
    '[4 merged PRs](https://github.com/infiniflow/ragflow/pulls',
    '61 merged PRs across 15 external upstream repositories',
    '5 merged PRs · staged adoption', 'EvalScope multimodal eval',
    'contributions across 14 external upstream repositories',
    'laya/pull/328', 'laya/pull/292', 'laya/pull/430', 'laya/pull/565'
)) {
    if ($actual.Contains($stale)) { throw "Superseded content must stay removed: $stale" }
}
foreach ($forbidden in @('## Recent OSS activity', 'OSS-ACTIVITY', 'Upstream-39_merged_PRs', '39 merged PRs')) {
    if ($actual.Contains($forbidden)) { throw "Removed content must stay removed: $forbidden" }
}

Write-Output 'v2.7 upstream count verification passed.'
