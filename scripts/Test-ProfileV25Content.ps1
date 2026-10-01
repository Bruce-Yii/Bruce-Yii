<#
.SYNOPSIS
    Content validator for Bruce-Yii/Bruce-Yii GitHub Profile v2.5 (YU-151).

.DESCRIPTION
    YU-151 makes three alignment and sizing adjustments to the released v2.4 layout:
    normalise the OSS Constellation baseline, vertically centre the Featured
    collaborations icon cells, and nudge the Agent OSS icons from 24px to 25px.

    As with the v2.3 and v2.4 gates, the core is a full-text equality check: the approved
    target is rebuilt from the frozen v2.4 baseline by applying exactly the permitted edits
    and the working-tree README must equal it line for line. Line endings are normalised
    CRLF -> LF and trailing newlines trimmed, so this is logical-line equality. That one
    comparison transitively proves the hero, badges, holograms, card copy, counts, the
    evidence block, footprint, How I contribute, Active tracks, Contributions, streak,
    snake, every link and every icon provenance URL are untouched.

    The rest asserts what equality cannot express: the grid is still 4x2, the reserved
    label line is on the four single-line labels and only those, all eleven cells that
    should be vertically centred actually are, and the Agent OSS icons are 25px with
    RAGFlow still non-square.

.DESCRIPTION
    Why the Constellation fix is a reserved label line rather than a height attribute.
    GitHub's sanitizer strips inline style, and its stylesheet forces every markdown table
    to display:block, which makes row height content-driven, so a height attribute can
    only ever act as a minimum and can never pull the taller cells down to meet the
    shorter ones. Measured on the live renderer, a nested per-cell two-row table with
    height="60" and height="38" left the icon misalignment at 10-14px, completely unchanged.
    That kills the whole family of fixed-height fixes, not just the nested-table one. The
    only thing that survives sanitization is equalising the content itself, which means
    reserving a real second line so the label's line count stops moving the icon.

    The spacer is a doubled break, <br/><br/>, and only that. Three candidates were each
    measured on a fresh render rather than reasoned about, because two of them look
    equivalent in source and are not equivalent in the browser:
      * <br/>&nbsp; reserves the line, but the non-breaking space sits inside the link and
        renders as a visible blue dash under Laya, FunASR, Dify and Cherry;
      * a single bare trailing <br/> reserves nothing at all, because the browser collapses
        a break at the end of a block, which put the icon spread straight back to 12px;
      * <br/><br/> reserves exactly one empty line, because only the final break collapses.
    A zero-width space (&#8203;) after a single break measures identically to <br/><br/> and
    was the previous choice, but it puts an invisible character in the label text, so
    copying "Laya" yields Laya + U+200B. The doubled break adds no characters at all.
    What the measurements are, so they can be re-checked. "Icon offset" is the icon's
    distance from the top of its own cell; "spread" is max minus min across the four cells
    of a grid row. Same metric, same session, 390px viewport:

        v2.4 baseline   row 1 offsets 17, 7, 7, 17  spread 10   cell height 100
        v2.5 head       row 1 offsets 7, 7, 7, 7    spread  0   cell height 107

    Two honest caveats on those numbers, both measured rather than assumed:
      * The cell height grows 100 -> 107. The reserved line is not zero-height, so the row
        grows; the growth is identical for <br/><br/> and for the zero-width-space variant,
        which is what rules out a glyph or fallback-font metrics explanation.
      * At 320px the head shows offsets 10, 10, 7, 7, a 3px spread. That is not a label
        problem: the browser clamps image heights unevenly there (33, 34, 36, 40), and the
        offset tracks the image height exactly, so the icon *centres* land within 1px of
        each other. Both spacers reproduce the same figures.

.EXAMPLE
    pwsh -File Test-ProfileV25Content.ps1
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ActualReadme,
    [string]$BaselineRef = '49e150cdc6297b6e02344cf40fe3bd6e1a1f0912'
)

$ErrorActionPreference = 'Stop'

if (-not $ActualReadme) {
    $ActualReadme = Join-Path $RepositoryRoot 'README.md'
}

$baselineLines = & git -C $RepositoryRoot show "${BaselineRef}:README.md"
if ($LASTEXITCODE -ne 0) { throw "Unable to read baseline README at $BaselineRef" }
$baseline = (($baselineLines -join "`n").TrimEnd("`r", "`n"))
$actual = ([IO.File]::ReadAllText($ActualReadme).Replace("`r`n", "`n").TrimEnd("`r", "`n"))

# --- Change 1: reserve a uniform label line on the four single-line labels -------
# Laya, FunASR, Dify and Cherry are one line today while QwenPaw, EvalScope, OpenClaw and
# RAGFlow are two. With the cells vertically centred that height difference is what pushes
# their icons up. The four short labels gain a reserved empty line so all eight labels
# occupy 35px. No label text changes.
$reservedLabels = @('Laya', 'FunASR', 'Dify', 'Cherry')

# --- Change 2: vertically centre the three Featured icon cells ------------------
# Was valign="top", which left each icon pinned above taller text blocks.
$iconCellOld = '<td width="84" align="center" valign="top">'
$iconCellNew = '<td width="84" align="center" valign="middle">'

# --- Change 3: Agent OSS icons 24px -> 25px -------------------------------------
# 25px, not 26px. Measured sweep in the live DOM with a 57px icon-cell content box and a
# stable 4px inter-icon gap: 24px needs 52px, 25px needs 54px, 26px needs 56px (1px of
# slack), 27px collapses the 2x2 into three lines. YU-151 asked for 25px first and 25px
# carries 3px of slack against a silent layout cliff.
$iconEdits = @(
    @('u/252820863?v=4" width="24" height="24"', 'u/252820863?v=4" width="25" height="25"'),
    @('u/127165244?v=4" width="24" height="24"', 'u/127165244?v=4" width="25" height="25"'),
    @('09d4ea5e2f6756a31377a388446d66253f87cd1b/build/icons/128x128.png" width="24" height="24"', '09d4ea5e2f6756a31377a388446d66253f87cd1b/build/icons/128x128.png" width="25" height="25"'),
    # RAGFlow's source mark is 32x34, a 16:17 ratio, so 24x25 keeps the same shape the
    # released 23x24 had rather than forcing a square. GitHub rewrites width/height into
    # an aspect-ratio, so a square 25x25 would visibly squash it.
    @('313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="23" height="24"', '313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="24" height="25"')
)

$expected = $baseline

foreach ($label in $reservedLabels) {
    $old = "<sub><b>$label</b></sub>"
    $new = "<sub><b>$label<br/><br/></b></sub>"
    $count = [regex]::Matches($expected, [regex]::Escape($old)).Count
    if ($count -ne 1) { throw "Reserved-label edit must match the baseline exactly once for $label, matched $count" }
    $expected = $expected.Replace($old, $new)
}

$cellCount = [regex]::Matches($expected, [regex]::Escape($iconCellOld)).Count
if ($cellCount -ne 3) { throw "Expected exactly 3 Featured icon cells to re-align, found $cellCount" }
$expected = $expected.Replace($iconCellOld, $iconCellNew)

foreach ($edit in $iconEdits) {
    $old = $edit[0]
    $new = $edit[1]
    $count = [regex]::Matches($expected, [regex]::Escape($old)).Count
    if ($count -ne 1) { throw "Icon edit must match the baseline exactly once, matched $count`: $old" }
    $expected = $expected.Replace($old, $new)
}

if ($actual -cne $expected) {
    throw 'README does not match the approved YU-151 target. Only the Constellation label reservation, the three icon-cell alignments and the four Agent OSS icon sizes may differ from v2.4.'
}

# --- Constellation must still be a 4x2 grid with all eight marks ----------------
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

# The eight cells stay vertically centred; that is what turns equal label heights into
# equal icon baselines.
$constellationCells = [regex]::Matches($constellation.Groups[1].Value, '<td\b[^>]*valign="([^"]*)"')
if ($constellationCells.Count -ne 8) { throw "Expected 8 Constellation cells with a valign, found $($constellationCells.Count)" }
foreach ($cell in $constellationCells) {
    if ($cell.Groups[1].Value -ne 'middle') { throw "Constellation cells must stay valign=middle, found $($cell.Groups[1].Value)" }
}

# Exactly the four short labels carry the reserved line; the four already-split labels
# must not gain a third line.
$reserved = [regex]::Matches($constellation.Groups[1].Value, '<sub><b>([^<]*)<br/><br/></b></sub>')
if ($reserved.Count -ne 4) { throw "Expected exactly 4 reserved label lines, found $($reserved.Count)" }
$reservedNames = @($reserved | ForEach-Object { $_.Groups[1].Value })
foreach ($label in $reservedLabels) {
    if ($reservedNames -notcontains $label) { throw "Reserved label line missing on $label" }
}
# The spacer must stay a bare doubled break. A non-breaking space inside the link renders
# as a visible dash, a single trailing break collapses and reserves nothing, and a
# zero-width space puts an invisible character in the label text.
foreach ($bad in @('&nbsp;', '&#8203;', '8203')) {
    if ($constellation.Groups[1].Value.Contains($bad)) {
        throw "Constellation labels must not contain '$bad'; only <br/><br/> reserves the line."
    }
}
foreach ($label in @('Qwen<br/>Paw', 'Eval<br/>Scope', 'Open<br/>Claw', 'RAG<br/>Flow')) {
    $pattern = "<sub><b>$([regex]::Escape($label))</b></sub>"
    if (-not $constellation.Groups[1].Value.Contains($pattern)) { throw "Two-line label must be left alone: $label" }
}

# --- Featured collaborations icon cells are centred, Laya and Qwen icons untouched --
$featuredCells = [regex]::Matches($actual, '<td width="84" align="center" valign="([^"]*)"')
if ($featuredCells.Count -ne 3) { throw "Expected 3 Featured icon cells, found $($featuredCells.Count)" }
foreach ($cell in $featuredCells) {
    if ($cell.Groups[1].Value -ne 'middle') { throw "Featured icon cells must be valign=middle, found $($cell.Groups[1].Value)" }
}
foreach ($pinned in @(
    '970dc8c5f63d7b886a68409493f37d569424f933/assets/logo-mark.svg" width="52" height="52"',
    '3822ec7173d17cf37c8a02f51d3ed5628079e86e/scripts/pack/assets/icon.svg" width="52" height="52"'
)) {
    if (-not $actual.Contains($pinned)) { throw "Laya or Qwen icon size must stay 52x52: $pinned" }
}

# --- Agent OSS icons are 25px, RAGFlow still non-square --------------------------
$cardTable = [regex]::Match($actual, '(?s)<table width="100%">.*?</table>')
$agentRow = [regex]::Match($cardTable.Value, '(?s)<td width="84"[^>]*>(?:(?!</tr>).)*?OpenClaw official GitHub avatar.*?</tr>')
if (-not $agentRow.Success) { throw 'Could not locate the Agent OSS card row.' }
$agentImages = [regex]::Matches($agentRow.Value, '<img\b[^>]*>')
if ($agentImages.Count -ne 4) { throw "Agent OSS must keep exactly 4 icons, found $($agentImages.Count)" }
$expectedAgentSizes = @{ 'OpenClaw official GitHub avatar' = '25'; 'Dify official GitHub avatar' = '25'; 'Cherry Studio logo' = '25'; 'RAGFlow logo' = '24' }
foreach ($img in $agentImages) {
    $tag = $img.Value
    $alt = [regex]::Match($tag, 'alt="([^"]*)"').Groups[1].Value
    $width = [regex]::Match($tag, '\bwidth="(\d+)"').Groups[1].Value
    $height = [regex]::Match($tag, '\bheight="(\d+)"').Groups[1].Value
    if (-not $expectedAgentSizes.ContainsKey($alt)) { throw "Unexpected Agent OSS icon: $alt" }
    if ($width -ne $expectedAgentSizes[$alt]) { throw "$alt width is $width, expected $($expectedAgentSizes[$alt])" }
    if ($height -ne '25') { throw "$alt height is $height, expected 25" }
}

# The 2x2 fit is enforced by the per-icon width/height checks above plus the full-text
# equality, not by arithmetic on literals here. Measured in the live DOM: the icon cell has
# a 57px content box and the two icons on a line are separated by a rendered 4px gap, so
# 2 x 25 + 4 = 54px fits with 3px to spare, 2 x 26 + 4 = 56px leaves 1px, and 2 x 27 + 4 =
# 58px collapses the cluster to three lines. YU-151 asked for 25px first and capped the
# choice at 26px with 27px forbidden.

# --- Everything the issue said to leave alone -----------------------------------
$required = @(
    '## OSS Constellation', '## Featured collaborations', '## How I contribute',
    '## Active tracks', '## Contributions', 'Selected upstream impact — PR evidence',
    'Current footprint:', 'View work →', 'Explore work →', 'All PRs →',
    '5 merged PRs', 'OpenClaw ×4', 'Dify ×3', 'Cherry ×4', 'RAGFlow ×4',
    'assets/hologram-1.gif', 'assets/hologram-2.gif', 'dist/streak.svg', 'dist/github-snake.svg'
)
foreach ($phrase in $required) {
    if (-not $actual.Contains($phrase)) { throw "Required section, copy or asset missing: $phrase" }
}
foreach ($forbidden in @('## Recent OSS activity', 'OSS-ACTIVITY', 'Upstream-39_merged_PRs', '39 merged PRs')) {
    if ($actual.Contains($forbidden)) { throw "Removed content must stay removed: $forbidden" }
}

Write-Output 'YU-151 content verification passed.'
