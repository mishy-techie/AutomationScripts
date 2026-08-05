<#
    Folder Backup Tool
    ------------------
    This script creates a backup of a folder by copying all files
    and subfolders to a backup location.

    Features:
    - Cross-platform (Windows, Linux, macOS)
    - Copies folders recursively
    - Creates the backup folder if it does not exist
    - Displays progress messages
    - Shows a summary when finished

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

# Folder to back up.
# "." means the current working directory.
$sourceFolder = "."

# Destination where the backup will be stored.
$backupRoot = "./Backups"

# -------------------------------------------------------
# Verify the source folder exists
# -------------------------------------------------------

if (-not (Test-Path $sourceFolder)) {
    Write-Host "Source folder not found."
    exit
}

# -------------------------------------------------------
# Create the backup destination if it doesn't exist
# -------------------------------------------------------

if (-not (Test-Path $backupRoot)) {

    New-Item `
        -Path $backupRoot `
        -ItemType Directory | Out-Null

}

# -------------------------------------------------------
# Create a timestamp for the backup folder
# -------------------------------------------------------

# Example:
# Backup_2026-08-05_143000
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

# Extract the name of the source folder.
$folderName = Split-Path $sourceFolder -Leaf

# If backing up ".", use the current directory's name.
if ([string]::IsNullOrWhiteSpace($folderName)) {
    $folderName = (Get-Location).Path | Split-Path -Leaf
}

# Build the final backup folder path.
$backupFolder = Join-Path `
    -Path $backupRoot `
    -ChildPath "${folderName}_Backup_$timestamp"

# -------------------------------------------------------
# Copy the folder
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Folder Backup Tool"
Write-Host "==========================================="
Write-Host "Source      : $sourceFolder"
Write-Host "Destination : $backupFolder"
Write-Host ""

try {

    # Copy everything from the source folder.
    Copy-Item `
        -Path $sourceFolder `
        -Destination $backupFolder `
        -Recurse `
        -Force `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "Backup completed successfully."

}
catch {

    Write-Host ""
    Write-Host "Backup failed."
    Write-Host $_.Exception.Message
    exit

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

# Count all copied files.
$fileCount = (
    Get-ChildItem `
        -Path $backupFolder `
        -File `
        -Recurse
).Count

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Files copied : $fileCount"
Write-Host "Backup saved : $backupFolder"
Write-Host ""