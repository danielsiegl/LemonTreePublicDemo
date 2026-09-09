# LemonTree.Connect Codebeamer Automation Sample

This sample runs the LemonTree Connect **Codebeamer** integration on Windows using PowerShell.
It is the PowerShell equivalent of the GitLab CI flow of the `lemontree-jama-devops` sample,
with two differences: it uses the Codebeamer connector instead of Jama, and it runs natively on
Windows instead of a prebuilt Linux Docker image.

The sample model is [LT.Connect Codebeamer Demo.qeax](<./LT.Connect Codebeamer Demo.qeax>), which
is the default for every script.

## Prerequisites

- Windows with PowerShell 5.1 (or PowerShell 7)
- Network access to `nexus.lieberlieber.com` and your Codebeamer server
- A `.secrets` file (see below)

## The `.secrets` file

Credentials and license information are **not** stored in this repository. Instead, this folder
needs a local `.secrets` file (it is ignored by git and must never be committed).

It must contain:

| Key | Description |
| --- | --- |
| `CodebeamerServer` | URL of the Codebeamer server, e.g. `https://codebeamer.example.com/cb/` |
| `CodebeamerUser` | User name used to log in to Codebeamer |
| `CodebeamerPassword` | Password of that user |
| `LieberLieberRLM` | LieberLieber RLM license string |

Format: one `Key=Value` pair per line; lines starting with `#` are comments. Because the license
must be a single line, spaces in the license string may be written as `|` — the scripts convert
them back to spaces when writing the license file.

```ini
# .secrets
CodebeamerServer=https://codebeamer.example.com/cb/
CodebeamerUser=demo.user
CodebeamerPassword=your-password
LieberLieberRLM=your-lieberlieber-rlm-license-string
```

Verify the file at any time:

```powershell
.\Check-Secrets.ps1
```

It exits with `0` on success and `1` if the file is missing or incomplete.

## Running the full flow

```powershell
.\Invoke-CodebeamerIntegration.ps1
```

This performs the same steps the GitLab pipeline does:

1. Verify the `.secrets` file.
2. Install the required tools into `.tools` (see below).
3. Write the LemonTree license file to `.tmp\lta.lic`.
4. Read every package configured for import (`direction = ToEa`) from the model, write one
   mapping XML per package and persist `projectId` / `trackerId` into
   `.tmp\packagemappings\codebeamer-import-metadata.json`.
5. Copy the model and run `LemonTree.Connect.Codebeamer.Automation Import` into the copy.
6. Diff the original model against the imported copy and write a diff report and a
   LemonTree session file.

Useful options:

```powershell
.\Invoke-CodebeamerIntegration.ps1 -UpdateTools   # force re-download of the binaries
.\Invoke-CodebeamerIntegration.ps1 -SkipDiff      # import only, no post-import diff
.\Invoke-CodebeamerIntegration.ps1 -ModelPath "other.qeax"
```

## Tools

The binaries are **only downloaded when they are missing**. Pass `-UpdateTools` to force a
re-download of everything.

```powershell
.\buildscripts\Install-Tools.ps1
.\buildscripts\Install-Tools.ps1 -UpdateTools
```

| Tool | Source |
| --- | --- |
| `LemonTree.Automation` | [LemonTree.Automation.Zip_Deploy.zip](https://nexus.lieberlieber.com/repository/lemontree-release/LemonTree.Automation/LemonTree.Automation.Zip_Deploy.zip) |
| `LemonTree.Connect.Codebeamer.Automation` | [LemonTree.Connect.Automation.Codebeamer.Windows_latest.zip](https://nexus.lieberlieber.com/repository/lemontree-release/LemonTree.Automation/LemonTree.Connect.Automation.Codebeamer.Windows_latest.zip) |
| `sqlite3` | [sqlite.org](https://www.sqlite.org/) — used to read the connector configuration out of the `.qeax` model |

They are installed into `.tools\` which is git-ignored.

## Scripts

| Script | Purpose |
| --- | --- |
| [Invoke-CodebeamerIntegration.ps1](./Invoke-CodebeamerIntegration.ps1) | Main entry point running the full flow |
| [Check-Secrets.ps1](./Check-Secrets.ps1) | Validates the `.secrets` file |
| [buildscripts/Install-Tools.ps1](./buildscripts/Install-Tools.ps1) | Downloads the binaries (only when missing, or with `-UpdateTools`) |
| [buildscripts/New-LemonTreeLicense.ps1](./buildscripts/New-LemonTreeLicense.ps1) | Writes the license file (UTF-8 without BOM) |
| [buildscripts/Export-LemonTreePackageMappings.ps1](./buildscripts/Export-LemonTreePackageMappings.ps1) | Exports mapping XMLs and Codebeamer metadata from the model |
| [buildscripts/Get-LemonTreeImportPackageGuids.ps1](./buildscripts/Get-LemonTreeImportPackageGuids.ps1) | Lists packages configured for import |
| [buildscripts/Invoke-EAqeaxSqliteQuery.ps1](./buildscripts/Invoke-EAqeaxSqliteQuery.ps1) | Runs a SQL query against a `.qeax` model |
| [buildscripts/Invoke-LemonTreeConnectCodebeamerImport.ps1](./buildscripts/Invoke-LemonTreeConnectCodebeamerImport.ps1) | Runs the Codebeamer import per package |
| [buildscripts/Invoke-LemonTreeDiff.ps1](./buildscripts/Invoke-LemonTreeDiff.ps1) | Creates the diff report and session file |
| [buildscripts/Common.ps1](./buildscripts/Common.ps1) | Shared helper functions |

## Where to find the results

Everything the flow produces is written to the git-ignored **`.tmp\`** folder next to this
README (override it with `-WorkingDirectory`):

| File | What it contains |
| --- | --- |
| `.tmp\packagemappings\codebeamer-import-metadata.json` | **The main result.** Package metadata (`Guid`, `PackageName`, `ProjectId`, `TrackerId`) plus a `LastImport` entry per package with exit code, duration, full tool output and a created/updated/deleted summary |
| `.tmp\packagemappings\packagemapping_<GUID>.xml` | The mapping definition that was read out of the model, one file per imported package |
| `.tmp\copy_<model>.qeax` | The model copy the import wrote into — the original model is never modified |
| `.tmp\codebeamer-changes-count.txt` | One line, e.g. `Found 6 different elements.` |
| `.tmp\DiffReport-codebeamer.xml` | Full XML diff between the original model and the imported copy |
| `.tmp\session-codebeamer.ltsfs` | LemonTree session file — open it in LemonTree to review the imported changes visually |
| `.tmp\lta.lic` | The generated license file (contains your license — never commit it) |

In addition, `LemonTree.Connect.Codebeamer.Automation` writes its own log files to the
git-ignored `logs\` folder.

Quick ways to inspect the outcome:

```powershell
# How many elements did the import change?
Get-Content .\.tmp\codebeamer-changes-count.txt

# Created / updated / deleted items per package
(Get-Content .\.tmp\packagemappings\codebeamer-import-metadata.json -Raw | ConvertFrom-Json) |
    Select-Object PackageName, TrackerId, @{n = 'Summary'; e = { $_.LastImport.Summary } }

# List all generated artifacts
Get-ChildItem .\.tmp -Recurse -File
```
