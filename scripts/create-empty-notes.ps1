<#
.SYNOPSIS
Creates empty Markdown (.md) files from a CSV of slugs.

.DESCRIPTION
Reads a CSV file containing a column named 'slug' and creates empty
Markdown files in the specified output directory. Existing files are never
overwritten.

Unique slugs create a single Markdown file. Duplicate slugs create a grouped
folder with an index.md note and one lettered child note per duplicate row.

.PARAMETER InputFile
Path to a CSV file with a 'slug' column (no .md extension).

.PARAMETER OutputDir
Target directory where notes will be created.

.PARAMETER WhatIf
Shows what would happen without creating any files.

.EXAMPLE
.\create-empty-notes.ps1 `
  -InputFile .\data\Obsidian_Slug_Note_Data.csv `
  -OutputDir "D:\ObsidianVault\Notes"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir
)

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$created = 0
$wouldCreate = 0
$skippedExisting = 0
$skippedEmpty = 0
$skippedInvalidGroup = 0

$slugs = Import-Csv $InputFile | ForEach-Object {
    if (-not $_.slug) {
        $skippedEmpty++
        return
    }

    $slug = $_.slug.Trim()
    if (-not $slug) {
        $skippedEmpty++
        return
    }

    $slug
}

$slugGroups = $slugs | Group-Object

foreach ($slugGroup in $slugGroups) {
    $slug = $slugGroup.Name
    $count = $slugGroup.Count

    if ($count -eq 1) {
        $filePath = Join-Path $OutputDir ($slug + ".md")

        if (Test-Path $filePath) {
            $skippedExisting++
            continue
        }

        $wouldCreate++

        if ($PSCmdlet.ShouldProcess($filePath, "Create empty markdown file")) {
            New-Item -ItemType File -Path $filePath | Out-Null
            $created++
        }

        continue
    }

    if ($count -gt 26) {
        Write-Warning "Skipping duplicate slug group with more than 26 rows: $slug"
        $skippedInvalidGroup += $count
        continue
    }

    $groupDir = Join-Path $OutputDir $slug

    if (-not (Test-Path $groupDir)) {
        $wouldCreate++

        if ($PSCmdlet.ShouldProcess($groupDir, "Create duplicate slug group folder")) {
            New-Item -ItemType Directory -Path $groupDir -Force | Out-Null
            $created++
        }
    }
    else {
        $skippedExisting++
    }

    $indexPath = Join-Path $groupDir "index.md"
    if (-not (Test-Path $indexPath)) {
        $wouldCreate++

        if ($PSCmdlet.ShouldProcess($indexPath, "Create duplicate slug group index note")) {
            Set-Content -Path $indexPath -Value ("# " + $slug + [Environment]::NewLine) -Encoding UTF8
            $created++
        }
    }
    else {
        $skippedExisting++
    }

    for ($i = 0; $i -lt $count; $i++) {
        $suffix = [char]([int][char]'a' + $i)
        $childSlug = $slug -replace "^(\d+)", "`$1$suffix"
        $filePath = Join-Path $groupDir ($childSlug + ".md")

        if (Test-Path $filePath) {
            $skippedExisting++
            continue
        }

        $wouldCreate++

        if ($PSCmdlet.ShouldProcess($filePath, "Create duplicate slug child markdown file")) {
            New-Item -ItemType File -Path $filePath | Out-Null
            $created++
        }
    }
}

Write-Host "Would create       : $wouldCreate"
Write-Host "Created            : $created"
Write-Host "Skipped (existing) : $skippedExisting"
Write-Host "Skipped (empty)    : $skippedEmpty"
Write-Host "Skipped (invalid)  : $skippedInvalidGroup"
