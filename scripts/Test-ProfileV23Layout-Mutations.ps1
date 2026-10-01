<#
.SYNOPSIS
    Adversarial self-test for Test-ProfileV23Layout.ps1 (YU-131).

.DESCRIPTION
    A gate that only ever reports green proves nothing. This harness applies the specific
    mutations that previously slipped through the layout validator and asserts that each
    one is now rejected. Every mutation is written to a temporary copy, so the real
    README is never touched.

    If a mutation is accepted, the layout gate is not doing its job and this script exits
    non-zero.

.EXAMPLE
    pwsh -File Test-ProfileV23Layout-Mutations.ps1
#>
[CmdletBinding()]
param(
    [string]$ValidatorPath = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext\scripts\Test-ProfileV23Layout.ps1',
    [string]$RepositoryRoot = 'D:\12412\opencode工作区\projects\oss-contributor-portfolio\github-profile-vnext'
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$sourcePath = Join-Path $RepositoryRoot 'README.md'
$original = $utf8NoBom.GetString([IO.File]::ReadAllBytes($sourcePath))

# name => [description, transform]
$mutations = [ordered]@{
    'class-attribute-hides-broken-title' = {
        param($t) $t.Replace('<b>Agent OSS</b>', '<b class="t">Agent<br/>OSS</b>') }
    'class-attribute-hides-broken-subtitle' = {
        param($t) $t.Replace('<sub>Runtime · RAG · context integrity</sub>', '<sub class="x">Runtime<br/>context</sub>') }
    'blank-line-between-rows' = {
        param($t) $t.Replace("  </tr>`r`n  <tr>", "  </tr>`r`n`r`n  <tr>") }
    'oversized-icon' = {
        param($t) $t.Replace('width="52" height="52" alt="Laya logo"', 'width="400" height="400" alt="Laya logo"') }
    'icon-column-below-icon-plus-padding' = {
        param($t) $t.Replace('<td width="84" align="center" valign="top">', '<td width="70" align="center" valign="top">') }
    'width-attribute-moved-to-text-cell' = {
        param($t) $t.Replace('<td width="84" align="center" valign="top">', '<td align="center" valign="top">').Replace('<td valign="top">', '<td width="84" valign="top">') }
    'card-retitled-while-its-content-stays' = {
        param($t) $t.Replace('<b>Laya</b>', '<b>Qwen × ModelScope</b>') }
    'percentage-column-width' = {
        param($t) $t.Replace('<td width="84" align="center" valign="top">', '<td width="25%" align="center" valign="top">') }
    'third-text-column-regression' = {
        param($t) $t.Replace("    <td valign=`"top`">`r`n      <b>Laya</b>", "    <td valign=`"top`">stolen</td>`r`n    <td valign=`"top`">`r`n      <b>Laya</b>") }
    'cta-link-unwrapped' = {
        param($t) $t.Replace('<a href="https://github.com/NandhaKishorM/laya/pulls?q=is%3Apr+author%3ABruce-Yii"><b>View work →</b></a>', '<b>View work →</b>') }
    'icon-provenance-url-swapped' = {
        param($t) $t.Replace('970dc8c5f63d7b886a68409493f37d569424f933', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') }
}

$tempDir = Join-Path ([IO.Path]::GetTempPath()) ("yu131-mut-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tempDir | Out-Null

$survived = @()
try {
    # Sanity: the unmutated file must pass, otherwise every result below is meaningless.
    $cleanPath = Join-Path $tempDir 'README.md'
    $utf8NoBom.GetBytes($original) | Set-Content -LiteralPath $cleanPath -AsByteStream -NoNewline
    & $ValidatorPath -RepositoryRoot $RepositoryRoot -ActualReadme $cleanPath | Out-Null
    Write-Output 'control: unmutated README accepted (expected)'

    foreach ($entry in $mutations.GetEnumerator()) {
        $name = $entry.Key
        $mutated = & $entry.Value $original
        if ($mutated -ceq $original) {
            throw "Mutation '$name' did not change the file, so it cannot test anything."
        }
        $path = Join-Path $tempDir 'README.md'
        $utf8NoBom.GetBytes($mutated) | Set-Content -LiteralPath $path -AsByteStream -NoNewline
        $rejected = $false
        try {
            & $ValidatorPath -RepositoryRoot $RepositoryRoot -ActualReadme $path | Out-Null
        }
        catch {
            $rejected = $true
        }
        if ($rejected) {
            Write-Output "rejected: $name"
        }
        else {
            $survived += $name
            Write-Output "SURVIVED: $name"
        }
    }
}
finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($survived.Count -gt 0) {
    throw "Layout gate accepted $($survived.Count) mutation(s): $($survived -join ', ')"
}

Write-Output "All $($mutations.Count) mutations rejected."
