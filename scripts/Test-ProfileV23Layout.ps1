<#
.SYNOPSIS
    Layout validator for Bruce-Yii/Bruce-Yii GitHub Profile v2.3 (YU-131).

.DESCRIPTION
    YU-131 changes the *structure* of the Featured collaborations section, so unlike the
    v2.2 copy-only gate this test cannot assert byte equality with the whole baseline.
    Instead it proves the change stayed inside that one section and is renderer-safe:

      * everything before the section and everything from <details> onward is
        byte-identical to the frozen baseline, which transitively locks the hero,
        holograms, OSS Constellation, evidence table, activity block and streak/snake;
      * the section is ONE table holding three card rows of exactly two cells, so
        GitHub never has to fit three text columns side by side, and the rows stay
        aligned instead of each table shrinking to its own content width;
      * no blank line appears inside the card table, because CommonMark ends a raw HTML
        block at a blank line and the table would stop rendering as one grid;
      * no percentage column widths and no <br/> inside a title or subtitle, both of
        which caused the reported mobile breakage, and both checked in a way that stays
        effective if a class or other attribute is later added to the element;
      * the icon column carries a pixel width attribute sized to fit the icon plus
        horizontal padding, because the presentational attribute is the only width
        control that survives GitHub's sanitizer;
      * every card row's full visible text is bound to its own row in order, so a card
        cannot be retitled or re-evidenced while another card's content stays put;
      * the URL multiset and the icon alt sequence are carried over unchanged, so no
        link, icon or icon provenance can drift during the restructure.

    Usage:
        pwsh -File Test-ProfileV23Layout.ps1
        pwsh -File Test-ProfileV23Layout.ps1 -BaselineRef <sha> -ActualReadme <path>

.NOTES
    Baseline a014fdcc97bfb7efe93542b1a005f27d333eface is the released v2.2 baseline,
    also frozen on-remote as branch profile-freeze-20260926-v2.2.

    The prefix lock is deliberate for YU-131, not an accident. It exists to prove this
    change touched one section only. Note that OSS Constellation directly above still
    uses eight `width="25%"` cells and manual <br/> inside its <b> titles, so it has the
    same mobile weakness this task fixed elsewhere. YU-131 explicitly forbade touching
    it, so it is tracked as separate follow-up work; widening this validator's scope
    would silently drop the confinement guarantee.

    Geometry was measured on the live GitHub renderer, not inferred. Section height and
    worst-case line counts at 1118 / 390 / 360 / 320 px, plus the renderer constraints
    that forced this structure, are recorded in scripts/Measure-Yu131CardLayout.json.
    Short version: at 390px the section went from 598px with a 16-line worst column and
    two-line CTAs to 518px with every title and CTA on one line, and at 320px the table
    stopped overflowing horizontally (baseline scrollWidth 309 vs clientWidth 254).
    Re-measure after any structural edit; do not trust these numbers to still hold.
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ActualReadme,
    [string]$BaselineRef = 'a014fdcc97bfb7efe93542b1a005f27d333eface'
)

$ErrorActionPreference = 'Stop'

if (-not $ActualReadme) {
    $ActualReadme = Join-Path $RepositoryRoot 'README.md'
}

function Get-ReadmeText {
    param([string]$Path)
    return [IO.File]::ReadAllText($Path).Replace("`r`n", "`n").TrimEnd("`r", "`n")
}

function Get-SectionParts {
    param([string]$Text)
    $heading = '## Featured collaborations'
    $headingIndex = $Text.IndexOf($heading)
    if ($headingIndex -lt 0) { throw 'Featured collaborations heading not found.' }
    $detailsIndex = $Text.IndexOf('<details>')
    if ($detailsIndex -lt 0) { throw 'Evidence <details> block not found.' }
    return [pscustomobject]@{
        Prefix  = $Text.Substring(0, $headingIndex)
        Section = $Text.Substring($headingIndex, $detailsIndex - $headingIndex)
        Suffix  = $Text.Substring($detailsIndex)
    }
}

$baselineLines = & git -C $RepositoryRoot show "${BaselineRef}:README.md"
if ($LASTEXITCODE -ne 0) { throw "Unable to read baseline README at $BaselineRef" }
$baseline = (($baselineLines -join "`n").TrimEnd("`r", "`n"))
$actual = Get-ReadmeText -Path $ActualReadme

$baseParts = Get-SectionParts -Text $baseline
$newParts = Get-SectionParts -Text $actual

# 1. The edit is confined to the one section.
if ($newParts.Prefix -cne $baseParts.Prefix) {
    throw 'Content before "Featured collaborations" changed. Hero, holograms or OSS Constellation must not be touched.'
}
if ($newParts.Suffix -cne $baseParts.Suffix) {
    throw 'Content from <details> onward changed. Evidence table, activity block or streak/snake must not be touched.'
}

$section = $newParts.Section

# 2. One card table holding exactly three single-row, two-column card rows.
#    A single table is required, not three separate ones: GitHub's markdown stylesheet
#    forces `table { display: block; width: max-content }` and strips inline style, so
#    standalone tables each shrink to their own content width and render ragged on
#    desktop. Rows in one table share a width and stay aligned.
$tableCount = [regex]::Matches($section, '<table').Count
if ($tableCount -ne 1) {
    throw "Featured collaborations must use exactly 1 table, found $tableCount"
}
$cardTable = [regex]::Match($section, '(?s)<table.*?</table>')

# CommonMark ends a raw HTML block at a blank line. A blank line between two card rows
# leaves every tag count, URL, alt and required phrase unchanged, so nothing else in this
# gate would notice, but GitHub would stop rendering the cards as one grid.
if ($cardTable.Value -match "(?m)^\s*$") {
    throw 'The card table contains a blank line; CommonMark would end the HTML block there and break the render.'
}

$rows = [regex]::Matches($cardTable.Value, '(?s)<tr>.*?</tr>')
if ($rows.Count -ne 3) {
    throw "Featured collaborations must hold exactly 3 card rows, found $($rows.Count)"
}
$expectedRowText = @(
    'Laya Product contracts · adoption · review 5 merged PRs · staged adoption · cross-PR review View work →',
    'Qwen × ModelScope Agent UX · multimodal eval · speech reliability QwenPaw product UX · EvalScope multimodal eval · FunASR Nano timestamps Explore work →',
    'Agent OSS Runtime · RAG · context integrity OpenClaw ×4 · Dify ×3 · Cherry ×4 · RAGFlow ×4 All PRs →'
)

$rowIndex = 0
foreach ($row in $rows) {
    $rowIndex++
    $cellMatches = [regex]::Matches($row.Value, '(?s)<td\b[^>]*>.*?</td>')
    if ($cellMatches.Count -ne 2) { throw "Card row $rowIndex must hold exactly 2 cells, found $($cellMatches.Count)" }

    # The icon column is sized by the HTML `width` attribute, and by nothing else.
    # GitHub strips inline `style`, so `style="width:..."` in the source is dead markup;
    # only the presentational attribute survives. Measured on the live renderer:
    # attr "84" -> computed 84px with border-box sizing, while `table-layout` in the
    # same stripped style attribute computes to `auto`, proving it never took effect.
    $iconCellHtml = $cellMatches[0].Value
    $iconCellWidthAttr = [regex]::Match($iconCellHtml, '^<td\b[^>]*\bwidth="(\d+)"')
    if (-not $iconCellWidthAttr.Success) {
        throw "Card row $rowIndex icon cell must carry a pixel width attribute on the first cell."
    }
    $iconCellWidth = [int]$iconCellWidthAttr.Groups[1].Value

    $iconWidthAttr = [regex]::Match($iconCellHtml, '<img\b[^>]*\bwidth="(\d+)"')
    if (-not $iconWidthAttr.Success) {
        throw "Card row $rowIndex must declare an explicit icon width so the column can be sized against it."
    }
    $iconWidth = [int]$iconWidthAttr.Groups[1].Value

    # GitHub renders markdown table cells with up to 16px horizontal padding per side.
    # A column narrower than icon + padding is exactly what pushes scrollWidth past
    # clientWidth at 320px, so the floor is derived rather than set to a round number.
    $minimumCellWidth = $iconWidth + 32
    if ($iconCellWidth -lt $minimumCellWidth) {
        throw "Card row $rowIndex icon column is $iconCellWidth px but its icon needs at least $minimumCellWidth px."
    }
    if ($iconCellWidth -gt 110) {
        throw "Card row $rowIndex icon column is $iconCellWidth px, which would squeeze the text column on narrow screens."
    }

    # Bind every card's visible text to its own row, in order. Without this a card can
    # be retitled or re-evidenced while another card's content stays in place, because
    # the URL multiset and the alt sequence are both order-agnostic.
    $textCellHtml = $cellMatches[1].Value
    $visibleText = ([regex]::Replace($textCellHtml, '<[^>]*>', ' ') -replace '\s+', ' ').Trim()
    if ($visibleText -cne $expectedRowText[$rowIndex - 1]) {
        throw "Card row $rowIndex text drifted.`n  expected: $($expectedRowText[$rowIndex - 1])`n  actual:   $visibleText"
    }
}

# 3. Renderer constraints that caused the reported breakage.
if ($section -match '<t[dh][^>]*width="\d+%"') {
    throw 'Percentage column widths reintroduced; GitHub will squeeze them side by side on mobile.'
}
# Attribute tolerant on purpose: `<b>` and `<sub>` must still be caught after a future
# edit adds a class or other attribute, which a bare `<b>` pattern would silently skip.
foreach ($match in [regex]::Matches($section, '(?s)<sub\b[^>]*>(.*?)</sub>')) {
    if ($match.Groups[1].Value -match '<br') {
        throw "Subtitle contains a manual line break: $($match.Groups[1].Value)"
    }
}
foreach ($match in [regex]::Matches($section, '(?s)<b\b[^>]*>(.*?)</b>')) {
    if ($match.Groups[1].Value -match '<br') {
        throw "Title contains a manual line break: $($match.Groups[1].Value)"
    }
}

# 4. No link, icon or icon provenance drift.
$urlPattern = '(?:href|src)="([^"]+)"'
$baseUrls = @([regex]::Matches($baseParts.Section, $urlPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object)
$newUrls = @([regex]::Matches($section, $urlPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object)
$urlDelta = Compare-Object -ReferenceObject $baseUrls -DifferenceObject $newUrls
if ($urlDelta) {
    throw "Featured collaborations URL set drifted:`n$($urlDelta | Out-String)"
}

$altPattern = '<img[^>]*alt="([^"]*)"'
$baseAlts = @([regex]::Matches($baseParts.Section, $altPattern) | ForEach-Object { $_.Groups[1].Value })
$newAlts = @([regex]::Matches($section, $altPattern) | ForEach-Object { $_.Groups[1].Value })
if (($baseAlts -join '|') -cne ($newAlts -join '|')) {
    throw "Featured collaborations icon set drifted.`nbase: $($baseAlts -join ', ')`nnew:  $($newAlts -join ', ')"
}

# 5. Claims, counts and calls to action survive the restructure.
$required = @(
    'View work →',
    'Explore work →',
    'All PRs →',
    'Product contracts · adoption · review',
    'Agent UX · multimodal eval · speech reliability',
    'Runtime · RAG · context integrity',
    '5 merged PRs · staged adoption · cross-PR review',
    'QwenPaw product UX · EvalScope multimodal eval · FunASR Nano timestamps',
    'OpenClaw ×4 · Dify ×3 · Cherry ×4 · RAGFlow ×4'
)
foreach ($phrase in $required) {
    if (-not $section.Contains($phrase)) {
        throw "Required card content missing: $phrase"
    }
}

Write-Output 'YU-131 featured collaborations layout verification passed.'
