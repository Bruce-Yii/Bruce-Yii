<#
.SYNOPSIS
    Content validator for Bruce-Yii/Bruce-Yii GitHub Profile v2.4 (YU-143).

.DESCRIPTION
    YU-143 makes two small edits on top of the accepted v2.3 layout: enlarge the four
    Agent OSS icons, and delete the Recent OSS activity timeline. Everything else must
    survive untouched.

    The core of this gate is a full-text equality check. It reconstructs the approved
    target README from the frozen v2.3 baseline by applying exactly the permitted edits,
    then asserts the working-tree README equals that target line for line. Line endings are
    normalised CRLF -> LF and trailing newlines are trimmed before comparing, so this is
    logical-line equality rather than raw byte equality; the repository has no
    .gitattributes pinning an EOL policy, and core.autocrlf makes the committed blobs LF
    while the working tree is CRLF.

    That single comparison is what proves the hero, the three badges, both holograms, the
    4x2 OSS Constellation, the Laya and Qwen cards and their icon sizes, the evidence
    details block, the footprint line, How I contribute, Active tracks, Contributions,
    streak, snake, and every icon provenance URL are all untouched. Any drift anywhere fails.

    It then adds the checks full-text equality cannot express on its own: the activity
    timeline and its automation markers are gone, the enlarged icons are the size that
    was actually measured to keep the 2x2 arrangement, and the weekly activity updater
    no longer schedules itself.

    The runtime behaviour of scripts/update-activity.py once the markers are gone is
    verified separately and empirically by Test-ProfileV24ActivityUpdater.ps1. That
    runtime gate is not optional decoration: the marker-guard check in this file is a
    substring match, so a guard that has been short-circuited while leaving its message
    string behind would satisfy this file. Only the runtime test catches that, which is
    why the three scripts are meant to be run together.

.EXAMPLE
    pwsh -File Test-ProfileV24Content.ps1
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext',
    [string]$ActualReadme,
    [string]$BaselineRef = '947e19f1fc73c5224c9964402470cf97e62dd95c',
    [string]$WorkflowPath,
    [string]$UpdaterPath
)

$ErrorActionPreference = 'Stop'

if (-not $ActualReadme) {
    $ActualReadme = Join-Path $RepositoryRoot 'README.md'
}
if (-not $WorkflowPath) {
    $WorkflowPath = Join-Path $RepositoryRoot '.github\workflows\profile-activity.yml'
}
if (-not $UpdaterPath) {
    $UpdaterPath = Join-Path $RepositoryRoot 'scripts\update-activity.py'
}

$baselineLines = & git -C $RepositoryRoot show "${BaselineRef}:README.md"
if ($LASTEXITCODE -ne 0) { throw "Unable to read baseline README at $BaselineRef" }
$baseline = (($baselineLines -join "`n").TrimEnd("`r", "`n"))
$actual = ([IO.File]::ReadAllText($ActualReadme).Replace("`r`n", "`n").TrimEnd("`r", "`n"))

# --- 1. Enlarge the four Agent OSS icons -------------------------------------
# 24px, not 26px. Measured on the live renderer at both 390px and 320px: the icon cell is
# a fixed 84px with 13px horizontal padding per side, giving a 57px content box, and the
# rendered gap between the two icons on a line is a stable 4px. Sweeping the size in the
# rendered DOM gives the whole picture, where "rows" is how many lines the 2x2 occupies:
#
#   size   width needed   rows
#   24px   52px of 57px   2     <- chosen, 5px of slack
#   25px   54px of 57px   2            3px of slack
#   26px   56px of 57px   2            1px of slack
#   27px   exceeds 57px   3     <- collapses, so the cliff is 27px, not 28px
#   28px   exceeds 57px   4
#
# The 84px cell is a preferred width under table-layout:auto, not a guaranteed one, so the
# question is not "how close is 26px to the cliff" but "how much can the cell shrink before
# the 2x2 breaks": 24px tolerates the cell narrowing to 79px, 26px only to 83px. Buying 5x
# the tolerance for 2px of icon size is the better trade, and YU-143 explicitly allowed
# 24px if 26px looked crowded. If someone later wants more, 25px is the defensible ceiling.
$iconEdits = @(
    @('u/252820863?v=4" width="20" height="20"', 'u/252820863?v=4" width="24" height="24"'),
    @('u/127165244?v=4" width="20" height="20"', 'u/127165244?v=4" width="24" height="24"'),
    @('09d4ea5e2f6756a31377a388446d66253f87cd1b/build/icons/128x128.png" width="20" height="20"', '09d4ea5e2f6756a31377a388446d66253f87cd1b/build/icons/128x128.png" width="24" height="24"'),
    # RAGFlow's mark is not square, so its width tracks height to preserve aspect ratio,
    # exactly as the 19x20 in v2.3 did.
    @('313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="19" height="20"', '313ca90f6abd7682fe8523e16fd67b3653a3fa84/web/public/logo.svg" width="23" height="24"')
)

# --- 2. Delete the Recent OSS activity timeline ------------------------------
$activityBlock = @'
## Recent OSS activity

<!-- OSS-ACTIVITY:START -->
- 2026-09-25 — `NandhaKishorM/laya#415` merged — docs: add staged adoption guide
- 2026-09-25 — `CherryHQ/cherry-studio#21031` merged — fix(composer): prefer text for rich Excel clipboard pastes
- 2026-09-25 — `modelscope/FunASR#3703` merged — fix(nano): correct punctuation timestamps across VAD merges
- 2026-09-24 — `NandhaKishorM/laya#328` merged — docs(langchain): document full-conversation state extraction
- 2026-09-24 — `NandhaKishorM/laya#292` merged — fix(router): blank/whitespace explicit lang falls through to detection
<!-- OSS-ACTIVITY:END -->

> This activity block updates automatically; the rest of the profile is curated by hand.


'@

$expected = $baseline

foreach ($edit in $iconEdits) {
    $old = $edit[0]
    $new = $edit[1]
    $count = [regex]::Matches($expected, [regex]::Escape($old)).Count
    if ($count -ne 1) { throw "Icon edit must match the baseline exactly once, matched $count`: $old" }
    $expected = $expected.Replace($old, $new)
}

$activityCount = [regex]::Matches($expected, [regex]::Escape($activityBlock)).Count
if ($activityCount -ne 1) { throw "Activity block must be present in the baseline exactly once, matched $activityCount" }
$expected = $expected.Replace($activityBlock, '')

if ($actual -cne $expected) {
    throw 'README does not match the approved YU-143 target. Only the four Agent OSS icon sizes and the activity timeline may differ from v2.3.'
}

# --- 3. Explicit statements the byte comparison alone does not make ----------
$removed = @(
    '## Recent OSS activity',
    '<!-- OSS-ACTIVITY:START -->',
    '<!-- OSS-ACTIVITY:END -->',
    'This activity block updates automatically',
    'OSS-ACTIVITY'
)
foreach ($phrase in $removed) {
    if ($actual.Contains($phrase)) { throw "Activity timeline content still present: $phrase" }
}

# The section headings that must survive, so a future edit cannot quietly drop one.
$required = @(
    '## OSS Constellation',
    '## Featured collaborations',
    '## How I contribute',
    '## Active tracks',
    '## Contributions',
    'Selected upstream impact — PR evidence',
    'Current footprint:',
    'assets/hologram-1.gif',
    'assets/hologram-2.gif',
    'dist/streak.svg',
    'dist/github-snake.svg',
    '<div align="center">'
)
foreach ($phrase in $required) {
    if (-not $actual.Contains($phrase)) { throw "Required section or asset missing: $phrase" }
}

# OSS Constellation must still be 4 columns x 2 rows with all eight project marks.
$constellation = [regex]::Match($actual, '(?s)## OSS Constellation(.*?)## Featured collaborations')
if (-not $constellation.Success) { throw 'Could not isolate the OSS Constellation section.' }
$constellationRows = [regex]::Matches($constellation.Groups[1].Value, '(?s)<tr>.*?</tr>')
if ($constellationRows.Count -ne 2) { throw "OSS Constellation must keep 2 rows, found $($constellationRows.Count)" }
foreach ($row in $constellationRows) {
    $cells = [regex]::Matches($row.Value, '<td\b').Count
    if ($cells -ne 4) { throw "Each OSS Constellation row must keep 4 cells, found $cells" }
}
$constellationIcons = [regex]::Matches($constellation.Groups[1].Value, '<img[^>]*alt="([^"]*)"')
if ($constellationIcons.Count -ne 8) { throw "OSS Constellation must keep 8 project marks, found $($constellationIcons.Count)" }

# Laya and Qwen card icons must keep their v2.3 size; only Agent OSS was in scope.
foreach ($pinned in @(
    '970dc8c5f63d7b886a68409493f37d569424f933/assets/logo-mark.svg" width="52" height="52"',
    '3822ec7173d17cf37c8a02f51d3ed5628079e86e/scripts/pack/assets/icon.svg" width="52" height="52"'
)) {
    if (-not $actual.Contains($pinned)) { throw "Laya or Qwen icon size must stay 52x52: $pinned" }
}

# The Agent OSS icon cell width is unchanged, and the cluster is still 2x2.
if (-not $actual.Contains('<td width="84" align="center" valign="top">')) {
    throw 'The 84px icon cell must be preserved.'
}
$cardTable = [regex]::Match($actual, '(?s)<table width="100%">.*?</table>')
$agentRow = [regex]::Match($cardTable.Value, '(?s)<td width="84"[^>]*>(?:(?!</tr>).)*?OpenClaw official GitHub avatar.*?</tr>')
if (-not $agentRow.Success) { throw 'Could not locate the Agent OSS card row.' }
$agentImages = [regex]::Matches($agentRow.Value, '<img\b[^>]*>')
if ($agentImages.Count -ne 4) { throw "Agent OSS must keep exactly 4 icons, found $($agentImages.Count)" }
$expectedAgentSizes = @{ 'OpenClaw official GitHub avatar' = '24'; 'Dify official GitHub avatar' = '24'; 'Cherry Studio logo' = '24'; 'RAGFlow logo' = '23' }
foreach ($img in $agentImages) {
    $tag = $img.Value
    $altMatch = [regex]::Match($tag, 'alt="([^"]*)"')
    $widthMatch = [regex]::Match($tag, '\bwidth="(\d+)"')
    $heightMatch = [regex]::Match($tag, '\bheight="(\d+)"')
    if (-not $altMatch.Success -or -not $widthMatch.Success -or -not $heightMatch.Success) {
        throw "Agent OSS icon tag is missing alt, width or height: $tag"
    }
    $alt = $altMatch.Groups[1].Value
    $width = $widthMatch.Groups[1].Value
    $height = $heightMatch.Groups[1].Value
    if (-not $expectedAgentSizes.ContainsKey($alt)) { throw "Unexpected Agent OSS icon: $alt" }
    if ($width -ne $expectedAgentSizes[$alt]) { throw "$alt width is $width, expected $($expectedAgentSizes[$alt])" }
    if ($height -ne '24') { throw "$alt height is $height, expected 24" }
}

# --- 4. The activity updater must stop scheduling itself --------------------
if (-not (Test-Path -LiteralPath $WorkflowPath)) { throw 'profile-activity.yml is missing.' }
$workflow = [IO.File]::ReadAllText($WorkflowPath)

# Comment lines are stripped first: the explanatory comment added in v2.4 mentions the word
# "schedule", and a naive search would flag its own documentation.
$workflowCode = (($workflow -split "`r?`n") | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"

# The key pattern tolerates quoting and YAML flow style, because a plain `^\s*schedule:`
# misses all of these, any of which is a real weekly trigger:
#   "schedule":            (quoted key)
#   'schedule':            (single-quoted key)
#   on: {..., schedule: [...]}   (flow mapping)
# ConvertFrom-Yaml is not available in this PowerShell build, so this is a tightened
# textual check rather than a parse; the mutation harness covers all three spellings.
if ($workflowCode -match '(?m)["'']?\bschedule["'']?\s*:') {
    throw 'profile-activity.yml still declares a schedule trigger; the timeline it updates no longer exists.'
}
if ($workflowCode -notmatch '(?m)["'']?\bworkflow_dispatch["'']?\s*:') {
    throw 'profile-activity.yml should keep workflow_dispatch so the updater can be re-run deliberately.'
}

if (-not (Test-Path -LiteralPath $UpdaterPath)) { throw 'update-activity.py is missing.' }
$script = [IO.File]::ReadAllText($UpdaterPath)
if ($script -notmatch 'markers missing, refusing to rewrite') {
    throw 'update-activity.py lost its marker guard; it must stay a safe no-op when the markers are absent.'
}

Write-Output 'YU-143 content verification passed.'
