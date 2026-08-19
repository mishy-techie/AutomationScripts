<#
    Duplicate File Finder
    ---------------------
    This script searches a directory for duplicate files by
    comparing their SHA256 hash values.

    Features:
    - Cross-platform (Windows, Linux, macOS)
    - Traverses directories recursively
    - Uses SHA256 hashing
    - Groups duplicate files together
    - Displays a summary

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

# Directory to search.
# "." means the current working directory.
$searchDirectory = "."

Write-Host ""
Write-Host "==========================================="
Write-Host " Duplicate File Finder"
Write-Host "==========================================="
Write-Host "Searching: $searchDirectory"
Write-Host ""

# -------------------------------------------------------
# Verify the directory exists
# -------------------------------------------------------

if (-not (Test-Path $searchDirectory)) {
    Write-Host "Directory not found."
    exit
}

# -------------------------------------------------------
# Find all files
# -------------------------------------------------------

# Retrieve every file from the directory and its subdirectories.
$files = Get-ChildItem `
    -Path $searchDirectory `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

# This array will store information about each file
# and its corresponding hash.
$fileHashes = @()

# -------------------------------------------------------
# Calculate a hash for each file
# -------------------------------------------------------

foreach ($file in $files) {

    try {

        # Calculate the SHA256 hash.
        $hash = Get-FileHash `
            -Path $file.FullName `
            -Algorithm SHA256

        # Store the file path and hash together.
        $fileHashes += [PSCustomObject]@{
            File = $file.FullName
            Hash = $hash.Hash
        }

    }
    catch {

        # Some files may be inaccessible.
        Write-Host "Skipped: $($file.FullName)"
    }
}

# -------------------------------------------------------
# Group files by hash
# -------------------------------------------------------

# Files with the same hash are considered duplicates.
$duplicateGroups = $fileHashes |
    Group-Object Hash |
    Where-Object {
        $_.Count -gt 1
    }

# -------------------------------------------------------
# Display duplicate files
# -------------------------------------------------------

if ($duplicateGroups.Count -eq 0) {

    Write-Host "No duplicate files were found."

}
else {

    foreach ($group in $duplicateGroups) {

        Write-Host ""
        Write-Host "Duplicate Group"
        Write-Host "SHA256: $($group.Name)"
        Write-Host "-------------------------------------------"

        foreach ($item in $group.Group) {

            Write-Host $item.File

        }

    }

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Files Scanned : $($files.Count)"
Write-Host "Duplicate Sets: $($duplicateGroups.Count)"
Write-Host ""