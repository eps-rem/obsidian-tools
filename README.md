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
