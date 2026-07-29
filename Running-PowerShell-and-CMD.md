# Running PowerShell Scripts and CMD Files

## Overview

This project was created using **PowerShell (.ps1)** and tested in **GitHub Codespaces**, which runs on Linux.

Because Linux does not support Windows Command Prompt (`.cmd`) files, the PowerShell scripts are run using `pwsh`.

When using Windows in the future, there are two ways to run the scripts.

---

# Option 1: Use a CMD File to Launch the PowerShell Script (Recommended)

This is the easiest and most common method.

## Step 1

Keep your PowerShell script.

Example:

```
08-IpConfigurationReport.ps1
```

## Step 2

Create a new file with the same name but a `.cmd` extension.

Example:

```
08-IpConfigurationReport.cmd
```

## Step 3

Add the following code to the `.cmd` file.

```cmd
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp008-IpConfigurationReport.ps1"
pause
```

## Step 4

Save the file.

Now, when you double-click the `.cmd` file on a Windows computer, it will automatically run the PowerShell script.

---

# Option 2: Rewrite the Script as a Batch (.cmd) Script

If a project or instructor specifically requires a **CMD (Batch)** script, the PowerShell code must be rewritten using batch commands.

PowerShell and Batch are different scripting languages, so a `.ps1` file cannot simply be renamed to `.cmd`.

This option is only necessary if a true batch script is required.

---

# Running the Script in GitHub Codespaces

GitHub Codespaces uses Linux, so `.cmd` files cannot be run.

Instead, open the terminal and use:

```powershell
pwsh ./08-IpConfigurationReport.ps1
```

---

# Running the Script on Windows

If using PowerShell directly:

```powershell
.\08-IpConfigurationReport.ps1
```

If using the CMD launcher:

1. Locate the `.cmd` file.
2. Double-click it.
3. The `.cmd` file will start PowerShell.
4. The PowerShell script will execute.
5. The report file will be created in the same folder.

---

# Notes

- `.ps1` = PowerShell Script
- `.cmd` = Windows Batch Script
- GitHub Codespaces supports `.ps1` but not `.cmd`.
- A `.cmd` launcher is a convenient way to run a PowerShell script on Windows.

---

# Summary

| Environment | How to Run |
|-------------|------------|
| GitHub Codespaces (Linux) | `pwsh ./ScriptName.ps1` |
| Windows PowerShell | `.\ScriptName.ps1` |
| Windows CMD | Double-click the `.cmd` launcher |
