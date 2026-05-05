<#
.SYNOPSIS
Creates sub-slug folders or Markdown notes from a list of slugs.

.DESCRIPTION
Reads slugs from a CSV file with a 'slug' column or a text file with one slug
per line. Each slug must start with a numeric root followed by a letter, such
as 540a-ignore-planned-task-setup-duration.

All non-empty slugs must share the same numeric root. Existing folders are
never modified. Existing Markdown notes are never overwritten.

.PARAMETER InputFile
Path to a .csv or .txt file containing sub-slugs.

.PARAMETER ParentDir
Target parent directory where sub-slug folders or Markdown notes will be created.

.PARAMETER AsMarkdownFiles
Create empty .md files instead of directories.

.PARAMETER GroupSlug
Optional parent folder slug to create under ParentDir when -AsMarkdownFiles is
used, such as 540-data-loading-options.

.PARAMETER CreateIndex
Create an index.md note in the target folder when -AsMarkdownFiles is used.

.EXAMPLE
.\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\ObsidianVault\Notes\540-original-folder-name" `
  -WhatIf

.EXAMPLE
.\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\ObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -CreateIndex `
  -AsMarkdownFiles `
  -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$ParentDir,

    [switch]$AsMarkdownFiles,

    [string]$GroupSlug,

    [switch]$CreateIndex
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

$targetDir = if ($AsMarkdownFiles -and $GroupSlug) {
    Join-Path $ParentDir $GroupSlug
}
else {
    $ParentDir
}

if (-not (Test-Path $targetDir)) {
    if ($PSCmdlet.ShouldProcess($targetDir, "Create target directory")) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
}

$created = 0
$wouldCreate = 0
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

    $targetPath = if ($AsMarkdownFiles) {
        Join-Path $targetDir ($slug + ".md")
    }
    else {
        Join-Path $targetDir $slug
    }

    if (Test-Path $targetPath) {
        $skippedExisting++
        return
    }

    $action = if ($AsMarkdownFiles) { "Create empty Markdown note" } else { "Create sub-slug folder" }
    $itemType = if ($AsMarkdownFiles) { "File" } else { "Directory" }

    $wouldCreate++

    if ($PSCmdlet.ShouldProcess($targetPath, $action)) {
        New-Item -ItemType $itemType -Path $targetPath | Out-Null
        $created++
    }
}

if ($AsMarkdownFiles -and $CreateIndex) {
    $indexPath = Join-Path $targetDir "index.md"

    if (Test-Path $indexPath) {
        $skippedExisting++
    }
    else {
        $wouldCreate++

        $title = if ($GroupSlug) { $GroupSlug } else { $rootSlug }
        $indexContent = "# $title" + [Environment]::NewLine + [Environment]::NewLine

        foreach ($slug in Get-SlugsFromInputFile -Path $InputFile) {
            if (-not $slug) {
                continue
            }

            $slug = $slug.Trim()
            if (-not $slug -or $slug -notmatch "^(\d+)[a-zA-Z]-[-a-zA-Z0-9]+$") {
                continue
            }

            $linkText = $slug -replace "^\d+[a-zA-Z]-", ""
            $linkText = ($linkText -split "-") | ForEach-Object {
                if ($_.Length -gt 0) {
                    $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
                }
            }
            $linkText = $linkText -join " "

            $indexContent += "- [$linkText]($slug.md)" + [Environment]::NewLine
        }

        if ($PSCmdlet.ShouldProcess($indexPath, "Create index Markdown note")) {
            Set-Content -Path $indexPath -Value $indexContent -Encoding UTF8
            $created++
        }
    }
}

Write-Host "Root slug          : $rootSlug"
Write-Host "Mode               : $(if ($AsMarkdownFiles) { "Markdown files" } else { "Folders" })"
Write-Host "Target directory   : $targetDir"
Write-Host "Would create       : $wouldCreate"
Write-Host "Created            : $created"
Write-Host "Skipped (existing) : $skippedExisting"
Write-Host "Skipped (empty)    : $skippedEmpty"
Write-Host "Skipped (invalid)  : $skippedInvalid"
