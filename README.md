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

Creates Obsidian folders or empty Markdown notes from a CSV or text file containing *sub-slugs*.

### Purpose

*   Split an existing numbered note/folder into lettered child folders or notes
*   One folder or Markdown note per sub-slug
*   Safe to re-run
*   **Never modifies existing folders or overwrites existing notes**

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

### Dry Run: Create Folders

```powershell
.\scripts\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\YourObsidianVault\Notes\540-original-folder-name" `
  -WhatIf
```

### Create Folders

```powershell
.\scripts\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\YourObsidianVault\Notes\540-original-folder-name"
```

### Dry Run: Create Markdown Notes

```powershell
.\scripts\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\YourObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -CreateIndex `
  -AsMarkdownFiles `
  -WhatIf
```

### Create Markdown Notes

```powershell
.\scripts\create-subslug-folders.ps1 `
  -InputFile .\data\540-subslugs.txt `
  -ParentDir "D:\YourObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -CreateIndex `
  -AsMarkdownFiles
```

### Behavior Details

*   Creates sub-slug folders under the specified parent directory by default
*   Creates empty `.md` files instead when `-AsMarkdownFiles` is supplied
*   Creates files under `ParentDir\GroupSlug` when `-GroupSlug` is supplied
*   Creates an `index.md` parent note when `-CreateIndex` is supplied
*   Skips folders or files that already exist
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
  -OutputDir "D:\YourObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -WhatIf
```

### Create Missing Notes

```powershell
.\scripts\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\YourObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options"
```

### Overwrite Existing Notes

```powershell
.\scripts\split-content-to-notes.ps1 `
  -ContentFile .\data\540-content.txt `
  -SlugFile .\data\540-subslugs.txt `
  -OutputDir "D:\YourObsidianVault\Notes" `
  -GroupSlug "540-data-loading-options" `
  -Overwrite
```

### Behavior Details

*   Converts each numbered section heading from `## 1. Title` to `# Title`
*   Preserves the remaining section headings and content
*   Creates one `.md` file per slug
*   Writes files under `OutputDir\GroupSlug` when `-GroupSlug` is supplied
*   Skips existing files unless `-Overwrite` is supplied
*   Stops without writing if section count and slug count do not match
*   Supports PowerShell `-WhatIf`

***

## split-content-to-substubs.ps1

Splits a Markdown content file into existing sub-stub notes inside a grouped note folder.

### Purpose

*   Convert one generated write-up into multiple sub-stub notes
*   Use the first line of each section as the destination filename
*   Infer the grouped folder from a lettered marker such as `600a-task-routes`
*   Fill existing empty sub-stub notes
*   Safe by default
*   Supports `-WhatIf`

### Input File Requirements

The content file should contain sections separated by horizontal rules. Each section must start with the destination filename without `.md`:

```markdown
600a-task-routes
# Task Routes

...

---

600b-task-routes
# Task Routes

...

---

index
## Summary

...
```

Valid marker lines are:

*   `index`
*   A lettered sub-stub slug like `600a-task-routes`

The group folder slug itself, such as `600-task-routes`, is not valid as a section marker. Use the exact lettered filename, such as `600b-task-routes`, so mistakes are caught before files are written.

### Dry Run

```powershell
.\scripts\split-content-to-substubs.ps1 `
  -ContentFile .\examples\sub-stub-data-example.md `
  -ParentDir "D:\YourObsidianVault\Notes\PrintFlow 4D Scheduling Configurations" `
  -WhatIf
```

### Fill Empty Sub-Stubs

```powershell
.\scripts\split-content-to-substubs.ps1 `
  -ContentFile .\examples\sub-stub-data-example.md `
  -ParentDir "D:\YourObsidianVault\Notes\PrintFlow 4D Scheduling Configurations"
```

### Overwrite Existing Sub-Stubs

```powershell
.\scripts\split-content-to-substubs.ps1 `
  -ContentFile .\examples\sub-stub-data-example.md `
  -ParentDir "D:\YourObsidianVault\Notes\PrintFlow 4D Scheduling Configurations" `
  -Overwrite
```

### Behavior Details

*   Removes the marker line from the written Markdown file
*   Preserves the remaining Markdown content
*   Creates or uses the implied group folder, such as `600-task-routes`
*   Writes `index` to `index.md`
*   Writes `600a-task-routes` to `600a-task-routes.md`
*   Creates the target folder if needed
*   Fills existing empty files
*   Skips existing non-empty files unless `-Overwrite` is supplied
*   Stops without writing if duplicate markers are found
*   Supports PowerShell `-WhatIf`

***

## repair-md-mojibake-arrows.ps1

Repairs mojibake arrow and dash sequences in Markdown files.

### Purpose

*   Recursively scan an Obsidian folder for Markdown files
*   Replace common mojibake arrows and dashes with ASCII-safe text
*   Use `->`, `<-`, `-`, and related plain-text equivalents
*   Support `-WhatIf`

### Example

```powershell
.\scripts\repair-md-mojibake-arrows.ps1 `
  -RootDir "D:\YourObsidianVault\Notes" `
  -WhatIf
```

### Create the Repairs

```powershell
.\scripts\repair-md-mojibake-arrows.ps1 `
  -RootDir "D:\YourObsidianVault\Notes"
```

### Behavior Details

The script currently replaces common mojibake forms of:

*   Right arrows -> `->`
*   Left arrows -> `<-`
*   Left-right arrows -> `<->`
*   Em/en dashes -> `-`
*   Smart apostrophes -> `'`

It only scans `.md` files and only writes files where replacements are found.

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
*   ✅ Handles duplicate slugs as grouped notes
*   ❌ Never modifies or overwrites existing content

Duplicate slugs are handled automatically. A slug that appears once creates:

```text
020-schedule-setup-mode.md
```

A slug that appears multiple times creates:

```text
020-schedule-setup-mode/
├── index.md
├── 020a-schedule-setup-mode.md
├── 020b-schedule-setup-mode.md
└── 020c-schedule-setup-mode.md
```

At completion, the script reports:

*   Number of files created
*   Number skipped due to existing files
*   Number skipped due to missing or blank slugs
*   Number skipped due to invalid duplicate groups

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
