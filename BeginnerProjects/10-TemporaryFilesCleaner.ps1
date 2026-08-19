<#
    Temporary Files Cleaner
    -----------------------
    This script finds and deletes files located in the operating system's
    temporary directory.

    Features:
    - Cross-platform (Windows, Linux, macOS)
    - Counts deleted files
    - Calculates reclaimed disk space
    - Handles errors gracefully
    - Displays a summary at the end

    Requires:
    PowerShell 7+
#>

# -----------------------------
# Get the operating system's temporary directory
# -----------------------------

# [System.IO.Path]::GetTempPath() automatically returns the correct
# temporary folder for the current operating system.
$tempFolder = [System.IO.Path]::GetTempPath()

Write-Host ""
Write-Host "========================================="
Write-Host " Temporary Files Cleaner"
Write-Host "========================================="
Write-Host "Temporary Folder:"
Write-Host $tempFolder
Write-Host ""

# Verify that the folder exists before continuing.
if (-not (Test-Path $tempFolder)) {
    Write-Host "Temporary folder not found."
    exit
}

# -----------------------------
# Initialize statistics
# -----------------------------

$deletedFiles = 0
$reclaimedBytes = 0

# -----------------------------
# Get every file in the temp folder
# -----------------------------

# -Recurse searches subfolders.
# -File ensures only files are returned.
# ErrorAction prevents inaccessible folders from stopping the script.
$files = Get-ChildItem `
    -Path $tempFolder `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

Write-Host "Found $($files.Count) files."
Write-Host ""

# -----------------------------
# Delete each file
# -----------------------------

foreach ($file in $files) {

    try {

        # Save the file size before deletion.
        $reclaimedBytes += $file.Length

        # Delete the file.
        Remove-Item $file.FullName -Force -ErrorAction Stop

        $deletedFiles++

    }
    catch {

        # Some files may be locked by the operating system.
        # We simply display a message and continue.
        Write-Host "Skipped: $($file.Name)"
    }
}

# -----------------------------
# Convert bytes into MB
# -----------------------------

$reclaimedMB = [Math]::Round($reclaimedBytes / 1MB, 2)

# -----------------------------
# Display summary
# -----------------------------

Write-Host ""
Write-Host "========================================="
Write-Host " Cleaning Complete"
Write-Host "========================================="
Write-Host "Files deleted : $deletedFiles"
Write-Host "Space reclaimed: $reclaimedMB MB"
Write-Host ""