<#
.SYNOPSIS
Splits a large Markdown/text content dump into individual Markdown notes.

.DESCRIPTION
Reads a content file containing numbered Markdown sections separated by
horizontal rules, then writes each section to a corresponding slug-named
Markdown file.

The script ignores introductory text before the first numbered section and
ignores everything from a line containing "Sources:" onward.

Existing files are skipped unless -Overwrite is supplied.

.PARAMETER ContentFile
Path to the large .txt or .md content file.

.PARAMETER SlugFile
Path to a .csv or .txt file containing slugs. CSV files must have a 'slug'
column. TXT files should contain one slug per line and may optionally start
with a 'slug' header.

.PARAMETER OutputDir
Directory where Markdown notes will be written.

.PARAMETER GroupSlug
Optional child folder under OutputDir where Markdown notes will be written,
such as 540-data-loading-options.

.PARAMETER Overwrite
Replace existing Markdown files.

.EXAMPLE
.\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\ObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -WhatIf

.EXAMPLE
.\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\ObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -Overwrite
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$ContentFile,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$SlugFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir,

    [string]$GroupSlug,

    [switch]$Overwrite
)

function Get-SlugsFromInputFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    if ($extension -eq ".csv") {
        return Import-Csv $Path | ForEach-Object { $_.slug } | Where-Object {
            $_ -and $_.Trim()
        } | ForEach-Object {
            $_.Trim()
        }
    }

    if ($extension -eq ".txt") {
        $lines = Get-Content $Path | Where-Object {
            $_ -and $_.Trim()
        } | ForEach-Object {
            $_.Trim()
        }

        if ($lines.Count -gt 0 -and $lines[0].ToLowerInvariant() -eq "slug") {
            return $lines | Select-Object -Skip 1
        }

        return $lines
    }

    throw "Unsupported slug file extension '$extension'. Use .csv or .txt."
}

function Convert-SectionToNoteContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Section
    )

    $section = $Section.Trim()
    $section = $section -replace "^\s*##\s+\d+\.\s+(.+)\r?\n", "# `$1`n"
    return $section.Trim() + [Environment]::NewLine
}

$content = Get-Content -Raw $ContentFile

if ([string]::IsNullOrWhiteSpace($content)) {
    throw "Content file is empty: $ContentFile"
}

$sourcesMatch = [regex]::Match($content, "(?im)^Sources:\s*$")
if ($sourcesMatch.Success) {
    $content = $content.Substring(0, $sourcesMatch.Index)
}

$firstSectionMatch = [regex]::Match($content, "(?m)^##\s+\d+\.\s+.+$")
if (-not $firstSectionMatch.Success) {
    throw "No numbered sections found. Expected headings like '## 1. Title'."
}

$content = $content.Substring($firstSectionMatch.Index)

$sections = [regex]::Split($content, "(?m)^\s*---\s*$") | Where-Object {
    $_.Trim() -match "^##\s+\d+\.\s+"
} | ForEach-Object {
    $_.Trim()
}

$slugs = @(Get-SlugsFromInputFile -Path $SlugFile)
$sections = @($sections)

if ($sections.Count -ne $slugs.Count) {
    throw "Section count ($($sections.Count)) does not match slug count ($($slugs.Count)). No files were written."
}

$targetDir = if ($GroupSlug) {
    Join-Path $OutputDir $GroupSlug
}
else {
    $OutputDir
}

if (-not (Test-Path $targetDir)) {
    if ($PSCmdlet.ShouldProcess($targetDir, "Create output directory")) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
}

$created = 0
$updated = 0
$skippedExisting = 0

for ($i = 0; $i -lt $sections.Count; $i++) {
    $slug = $slugs[$i]
    $filePath = Join-Path $targetDir ($slug + ".md")
    $noteContent = Convert-SectionToNoteContent -Section $sections[$i]

    if ((Test-Path $filePath) -and -not $Overwrite) {
        $skippedExisting++
        continue
    }

    $action = if (Test-Path $filePath) { "Overwrite Markdown note" } else { "Create Markdown note" }

    if ($PSCmdlet.ShouldProcess($filePath, $action)) {
        Set-Content -Path $filePath -Value $noteContent -Encoding UTF8

        if ($action -eq "Overwrite Markdown note") {
            $updated++
        }
        else {
            $created++
        }
    }
}

Write-Host "Sections           : $($sections.Count)"
Write-Host "Slugs              : $($slugs.Count)"
Write-Host "Target directory   : $targetDir"
Write-Host "Created            : $created"
Write-Host "Updated            : $updated"
Write-Host "Skipped (existing) : $skippedExisting"
