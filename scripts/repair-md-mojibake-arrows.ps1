<#
.SYNOPSIS
Repairs mojibake arrow and dash sequences in Markdown files.

.DESCRIPTION
Recursively scans Markdown files under a target directory and replaces common
UTF-8-decoded-as-ANSI mojibake arrow and dash sequences with ASCII equivalents.

Existing files are modified in place only when replacements are found. Use
-WhatIf to preview which files would be updated.

.PARAMETER RootDir
Root directory to scan for Markdown files.

.EXAMPLE
.\repair-md-mojibake-arrows.ps1 `
  -RootDir "D:\ObsidianVault\Notes" `
  -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$RootDir
)

function New-Text {
    param (
        [Parameter(Mandatory = $true)]
        [int[]]$CodePoints
    )

    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

$replacements = [ordered]@{}
$replacements[(New-Text @(0x00E2, 0x2020, 0x2019))] = "->"
$replacements[(New-Text @(0x00E2, 0x2020, 0x0092))] = "->"
$replacements[(New-Text @(0x00E2, 0x2020, 0x0090))] = "<-"
$replacements[(New-Text @(0x00E2, 0x2020, 0x0094))] = "<->"
$replacements[(New-Text @(0x00E2, 0x20AC, 0x009D))] = "-"
$replacements[(New-Text @(0x00E2, 0x20AC, 0x201D))] = "-"
$replacements[(New-Text @(0x00E2, 0x20AC, 0x0153))] = "-"
$replacements[(New-Text @(0x00E2, 0x20AC, 0x009C))] = "-"
$replacements[(New-Text @(0x00E2, 0x20AC, 0x02DC))] = "'"
$replacements[(New-Text @(0x00E2, 0x20AC, 0x2122))] = "'"

$filesScanned = 0
$filesChanged = 0
$filesWithReplacements = 0
$replacementCounts = @{}

foreach ($key in $replacements.Keys) {
    $replacementCounts[$key] = 0
}

Get-ChildItem -Path $RootDir -Recurse -File -Filter "*.md" | ForEach-Object {
    $filesScanned++
    $path = $_.FullName
    $content = Get-Content -Raw -LiteralPath $path

    if ([string]::IsNullOrEmpty($content)) {
        return
    }

    $updated = $content
    $fileReplacementCount = 0

    foreach ($badText in $replacements.Keys) {
        $count = ([regex]::Matches($updated, [regex]::Escape($badText))).Count

        if ($count -gt 0) {
            $updated = $updated.Replace($badText, $replacements[$badText])
            $replacementCounts[$badText] += $count
            $fileReplacementCount += $count
        }
    }

    if ($fileReplacementCount -eq 0) {
        return
    }

    $filesWithReplacements++

    if ($PSCmdlet.ShouldProcess($path, "Repair $fileReplacementCount mojibake arrow sequence(s)")) {
        Set-Content -LiteralPath $path -Value $updated -Encoding UTF8
        $filesChanged++
    }
}

Write-Host "Files scanned      : $filesScanned"
Write-Host "Files with changes : $filesWithReplacements"
Write-Host "Files changed      : $filesChanged"
Write-Host "Replacement counts :"

foreach ($badText in $replacements.Keys) {
    if ($replacementCounts[$badText] -gt 0) {
        Write-Host "  $badText -> $($replacements[$badText]) : $($replacementCounts[$badText])"
    }
}
