# Obsidian Tools

Utility scripts for performing bulk, repeatable operations against an Obsidian vault.

This repository is intentionally kept **separate from the Obsidian vault** itself.  
Scripts live here; generated notes live in the vault and are **not tracked by Git**.

***

## create-empty-notes.ps1

Creates empty Markdown (`.md`) note files from a CSV file containing document *slugs*.

### Purpose

*   Bulk‑create Obsidian notes from spreadsheet data
*   One note per slug
*   Safe to re‑run
*   **Never overwrites existing files**

***

## create-subslug-folders.ps1

Creates Obsidian folders from a CSV or text file containing *sub-slugs*.

### Purpose

*   Split an existing numbered note/folder into lettered child folders
*   One folder per sub-slug
*   Safe to re-run
*   **Never modifies existing folders**

### Input File Requirements

The input file may be either:

*   A CSV with a header column named `slug`
*   A TXT file with one slug per line

A TXT file may optionally include `slug` as the first line.

### Example Input

```text
slug
540a-ignore-planned-task-setup-duration
540b-ignore-jobs-with-no-form
540c-reconsider-task-choice-at-end-of-shut
540d-drag-drop-between-preferred-sites-allowed
```

The numeric prefix is treated as the root slug. In this example, the root slug is `540`.

All non-empty rows must use the same numeric root. Rows with a different root are skipped as invalid.

### Dry Run

```powershell
.\scripts\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\YourObsidianVault\Notes\540-original-folder-name" `
  -WhatIf
```

### Create the Folders

```powershell
.\scripts\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\YourObsidianVault\Notes\540-original-folder-name"
```

### Behavior Details

*   Creates sub-slug folders under the specified parent directory
*   Skips folders that already exist
*   Skips blank rows
*   Skips invalid rows
*   Skips rows whose numeric root does not match the first valid slug
*   Supports PowerShell `-WhatIf`

This nested structure is usually compatible with static-site or HTML publishing tools because the folder names remain stable, URL-safe slugs. The parent folder also gives site generators a natural hierarchy for navigation.

***

## split-content-to-notes.ps1

Splits a large Markdown or text content dump into individual Obsidian Markdown notes.

### Purpose

*   Convert one large generated content block into many slug-named notes
*   Pair numbered content sections to a slug file by order
*   Ignore source links and trailing reference material
*   Safe by default
*   Supports `-WhatIf`

### Input File Requirements

This script uses two input files:

*   `ContentFile` -> a `.txt` or `.md` file containing numbered Markdown sections
*   `SlugFile` -> a `.csv` or `.txt` file containing one slug per note

The content file should contain sections like:

```markdown
## 1. Ignore Planned Task Setup Duration

## Description

...

---

## 2. Ignore Jobs with No Form
```

The script ignores:

*   Introductory text before the first numbered heading
*   Horizontal rules outside real numbered sections
*   Everything from a line containing `Sources:` onward

The slug file may be:

*   A CSV with a `slug` column
*   A TXT file with one slug per line

TXT files may optionally include `slug` as the first line.

The number of numbered content sections must exactly match the number of slugs. If the counts differ, the script stops without writing files.

### Dry Run

```powershell
.\scripts\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\YourObsidianVault\Notes\540-original-folder-name" `
  -WhatIf
```

### Create Missing Notes

```powershell
.\scripts\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\YourObsidianVault\Notes\540-original-folder-name"
```

### Overwrite Existing Notes

```powershell
.\scripts\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\YourObsidianVault\Notes\540-original-folder-name" `
  -Overwrite
```

### Behavior Details

*   Converts each numbered section heading from `## 1. Title` to `# Title`
*   Preserves the remaining section headings and content
*   Creates one `.md` file per slug
*   Skips existing files unless `-Overwrite` is supplied
*   Stops without writing if section count and slug count do not match
*   Supports PowerShell `-WhatIf`

***

## Input File Requirements

The input file **must be a CSV** with a header column named `slug`.

### Example CSV

```csv
slug
010-plant
020-schedule-setup-mode
030-default-switchover
```

**Rules:**

*   One slug per row
*   Do **not** include `.md`
*   Duplicate slugs are allowed (duplicates are skipped safely)
*   Extra columns are ignored

***

## Repository Structure

```text
obsidian-tools/
├── scripts/
│   └── create-empty-notes.ps1
├── data/
│   └── Obsidian_Slug_Note_Data.csv
├── README.md
└── .gitignore
```

*   `scripts/` → PowerShell utilities (tracked in Git)
*   `data/` → Input files (real data may be git‑ignored if needed)
*   Output (`.md` files) goes into the Obsidian vault, **not this repo**

***

## Usage

Run all commands from the **root of the repository**.

### Dry Run (Recommended)

Shows what would be created without creating files:

```powershell
.\scripts\create-empty-notes.ps1 `
  -InputFile .\data\Obsidian_Slug_Note_Data.csv `
  -OutputDir "D:\YourObsidianVault\Notes" `
  -WhatIf
```

***

### Create the Notes

```powershell
.\scripts\create-empty-notes.ps1 `
  -InputFile .\data\Obsidian_Slug_Note_Data.csv `
  -OutputDir "D:\YourObsidianVault\Notes"
```

***

## Behavior Details

*   ✅ Creates empty `.md` files only
*   ✅ Skips files that already exist
*   ✅ Safe to re‑run multiple times
*   ✅ Handles duplicate slugs gracefully
*   ❌ Never modifies or overwrites existing content

At completion, the script reports:

*   Number of files created
*   Number skipped due to existing files
*   Number skipped due to missing or blank slugs

***

## PowerShell Execution Policy (Windows)

If script execution is blocked, enable user‑level script execution:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

This allows locally created and Git‑cloned scripts while remaining secure.

***

## Notes & Design Intent

*   This repo is intended for **one‑off or occasional automation**
*   Scripts should be:
    *   Parameterized
    *   Idempotent
    *   Safe against accidental re‑runs
*   Generated data should not be committed unless explicitly intended

***

## Future Enhancements (Optional)

This repo is intentionally minimal, but could be extended to include:

*   Frontmatter templates
*   Slug normalization
*   Validation or duplicate‑report output
*   Additional Obsidian maintenance scripts

***
