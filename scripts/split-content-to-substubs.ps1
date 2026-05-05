<#
.SYNOPSIS
Splits a Markdown content file into sub-stub Markdown notes.

.DESCRIPTION
Reads a Markdown content file where each section starts with the destination
sub-stub filename on its own line, followed by the Markdown content for that
note. Sections are separated by horizontal rules.

The marker line is used as the output filename. For example, a section starting
with "600a-task-routes" writes to "600a-task-routes.md", and a section starting
with "index" writes to "index.md".

Existing empty files are filled. Existing non-empty files are skipped unless
-Overwrite is supplied.

.PARAMETER ContentFile
Path to the Markdown content file.

.PARAMETER ParentDir
Parent directory where the implied group folder exists or should be created.
The group folder is derived from the first lettered sub-stub marker. For
example, 600a-task-routes implies a group folder named 600-task-routes.

.PARAMETER Overwrite
Replace existing non-empty Markdown files.

.EXAMPLE
.\split-content-to-substubs.ps1 `
  -ContentFile .\examples\sub-stub-data-example.md `
  -ParentDir "D:\YourObsidianVault\Notes\PrintFlow 4D Scheduling Configurations" `
  -WhatIf

.EXAMPLE
.\split-content-to-substubs.ps1 `
  -ContentFile .\examples\sub-stub-data-example.md `
  -ParentDir "D:\YourObsidianVault\Notes\PrintFlow 4D Scheduling Configurations" `
  -Overwrite
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$ContentFile,

    [Parameter(Mandatory = $true)]
    [string]$ParentDir,

    [switch]$Overwrite
)

function Get-ImpliedGroupSlug {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Sections
    )

    foreach ($section in $Sections) {
        if ($section.Marker -match "^(\d+)[a-zA-Z]-(.+)$") {
            return "$($Matches[1])-$($Matches[2])"
        }
    }

    throw "No lettered sub-stub marker found. Expected at least one marker like '600a-task-routes' so the group folder can be inferred."
}

function Convert-SectionToSubStub {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Section
    )

    $lines = @($Section -split "\r?\n")
    $firstContentLine = -1

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (-not [string]::IsNullOrWhiteSpace($lines[$i])) {
            $firstContentLine = $i
            break
        }
    }

    if ($firstContentLine -lt 0) {
        return $null
    }

    $marker = $lines[$firstContentLine].Trim()

    if ($marker -notmatch "^(index|\d+[a-zA-Z]-[-a-zA-Z0-9]+)$") {
        throw "Invalid sub-stub marker '$marker'. Expected 'index' or a lettered sub-stub filename like '600a-task-routes'."
    }

    $contentLines = @($lines | Select-Object -Skip ($firstContentLine + 1))
    $content = ($contentLines -join [Environment]::NewLine).Trim()

    if ([string]::IsNullOrWhiteSpace($content)) {
        throw "Sub-stub marker '$marker' has no Markdown content."
    }

    [pscustomobject]@{
        Marker = $marker
        Content = $content + [Environment]::NewLine
    }
}

$content = Get-Content -Raw $ContentFile

if ([string]::IsNullOrWhiteSpace($content)) {
    throw "Content file is empty: $ContentFile"
}

$sections = @(
    [regex]::Split($content, "(?m)^\s*---\s*$") |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { Convert-SectionToSubStub -Section $_ }
)

if ($sections.Count -eq 0) {
    throw "No sub-stub sections found."
}

$groupSlug = Get-ImpliedGroupSlug -Sections $sections

foreach ($section in $sections) {
    if ($section.Marker -eq "index") {
        continue
    }

    if ($section.Marker -match "^(\d+)[a-zA-Z]-(.+)$") {
        $sectionGroupSlug = "$($Matches[1])-$($Matches[2])"

        if ($sectionGroupSlug -ne $groupSlug) {
            throw "Sub-stub marker '$($section.Marker)' implies group '$sectionGroupSlug', but expected '$groupSlug'. No files were written."
        }
    }
}

$duplicateNames = @(
    $sections |
        Group-Object Marker |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object { $_.Name }
)

if ($duplicateNames.Count -gt 0) {
    throw "Duplicate sub-stub markers found: $($duplicateNames -join ', '). No files were written."
}

$resolvedTargetDir = Join-Path $ParentDir $groupSlug

if (-not (Test-Path $resolvedTargetDir)) {
    if ($PSCmdlet.ShouldProcess($resolvedTargetDir, "Create target directory")) {
        New-Item -ItemType Directory -Path $resolvedTargetDir -Force | Out-Null
    }
}

$created = 0
$filledEmpty = 0
$updated = 0
$skippedExisting = 0

foreach ($section in $sections) {
    $filePath = Join-Path $resolvedTargetDir ($section.Marker + ".md")
    $fileExists = Test-Path $filePath
    $isEmptyFile = $false

    if ($fileExists) {
        $item = Get-Item -LiteralPath $filePath
        $isEmptyFile = $item.Length -eq 0
    }

    if ($fileExists -and -not $isEmptyFile -and -not $Overwrite) {
        $skippedExisting++
        continue
    }

    $action = if (-not $fileExists) {
        "Create sub-stub Markdown note"
    }
    elseif ($isEmptyFile) {
        "Fill empty sub-stub Markdown note"
    }
    else {
        "Overwrite sub-stub Markdown note"
    }

    if ($PSCmdlet.ShouldProcess($filePath, $action)) {
        Set-Content -Path $filePath -Value $section.Content -Encoding UTF8

        switch ($action) {
            "Create sub-stub Markdown note" { $created++ }
            "Fill empty sub-stub Markdown note" { $filledEmpty++ }
            "Overwrite sub-stub Markdown note" { $updated++ }
        }
    }
}

Write-Host "Sections           : $($sections.Count)"
Write-Host "Group folder       : $groupSlug"
Write-Host "Target directory   : $resolvedTargetDir"
Write-Host "Created            : $created"
Write-Host "Filled empty       : $filledEmpty"
Write-Host "Updated            : $updated"
Write-Host "Skipped (non-empty): $skippedExisting"
