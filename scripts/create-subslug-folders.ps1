<#
.SYNOPSIS
Creates sub-slug folders from a list of slugs.

.DESCRIPTION
Reads slugs from a CSV file with a 'slug' column or a text file with one slug
per line. Each slug must start with a numeric root followed by a letter, such
as 540a-ignore-planned-task-setup-duration.

All non-empty slugs must share the same numeric root. Existing folders are
never modified.

.PARAMETER InputFile
Path to a .csv or .txt file containing sub-slugs.

.PARAMETER ParentDir
Target parent directory where sub-slug folders will be created.

.EXAMPLE
.\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\ObsidianVault\Notes\540-original-folder-name" `
  -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$ParentDir
)

function Get-SlugsFromInputFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    if ($extension -eq ".csv") {
        return Import-Csv $Path | ForEach-Object { $_.slug }
    }

    if ($extension -eq ".txt") {
        $lines = Get-Content $Path

        if ($lines.Count -gt 0 -and $lines[0].Trim().ToLowerInvariant() -eq "slug") {
            return $lines | Select-Object -Skip 1
        }

        return $lines
    }

    throw "Unsupported input file extension '$extension'. Use .csv or .txt."
}

if (-not (Test-Path $ParentDir)) {
    if ($PSCmdlet.ShouldProcess($ParentDir, "Create parent directory")) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }
}

$created = 0
$skippedExisting = 0
$skippedEmpty = 0
$skippedInvalid = 0
$rootSlug = $null

Get-SlugsFromInputFile -Path $InputFile | ForEach-Object {
    if (-not $_) {
        $skippedEmpty++
        return
    }

    $slug = $_.Trim()
    if (-not $slug) {
        $skippedEmpty++
        return
    }

    if ($slug -notmatch "^(\d+)[a-zA-Z]-[-a-zA-Z0-9]+$") {
        Write-Warning "Skipping invalid sub-slug: $slug"
        $skippedInvalid++
        return
    }

    $currentRootSlug = $Matches[1]
    if (-not $rootSlug) {
        $rootSlug = $currentRootSlug
    }
    elseif ($currentRootSlug -ne $rootSlug) {
        Write-Warning "Skipping sub-slug with mismatched root '$currentRootSlug': $slug"
        $skippedInvalid++
        return
    }

    $folderPath = Join-Path $ParentDir $slug

    if (Test-Path $folderPath) {
        $skippedExisting++
        return
    }

    if ($PSCmdlet.ShouldProcess($folderPath, "Create sub-slug folder")) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
        $created++
    }
}

Write-Host "Root slug          : $rootSlug"
Write-Host "Created            : $created"
Write-Host "Skipped (existing) : $skippedExisting"
Write-Host "Skipped (empty)    : $skippedEmpty"
Write-Host "Skipped (invalid)  : $skippedInvalid"
