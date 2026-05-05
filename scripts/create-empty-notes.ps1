<#
.SYNOPSIS
Creates empty Markdown (.md) files from a CSV of slugs.

.DESCRIPTION
Reads a CSV file containing a column named 'slug' and creates empty
Markdown files in the specified output directory. Existing files
are never overwritten.

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
$skippedExisting = 0
$skippedEmpty = 0

Import-Csv $InputFile | ForEach-Object {

    if (-not $_.slug) {
        $skippedEmpty++
        return
    }

    $slug = $_.slug.Trim()
    if (-not $slug) {
        $skippedEmpty++
        return
    }

    $filePath = Join-Path $OutputDir ($slug + ".md")

    # ✅ Never overwrite existing files
    if (Test-Path $filePath) {
        $skippedExisting++
        return
    }

    if ($PSCmdlet.ShouldProcess($filePath, "Create empty markdown file")) {
        New-Item -ItemType File -Path $filePath | Out-Null
        $created++
    }
}

Write-Host "Created            : $created"
Write-Host "Skipped (existing) : $skippedExisting"
Write-Host "Skipped (empty)    : $skippedEmpty"