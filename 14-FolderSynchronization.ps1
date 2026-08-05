<#
    Folder Synchronizer
    -------------------
    This script compares two folders and reports which files
    exist in one folder but not the other.

    Features:
    - Cross-platform (Windows, Linux, macOS)
    - Traverses folders recursively
    - Compares files using relative paths
    - Reports missing files
    - Displays a summary

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

# First folder to compare.
$sourceFolder = "./"

# Second folder to compare.
$destinationFolder = "./FolderB"

Write-Host ""
Write-Host "==========================================="
Write-Host " Folder Synchronizer"
Write-Host "==========================================="
Write-Host "Source      : $sourceFolder"
Write-Host "Destination : $destinationFolder"
Write-Host ""

# -------------------------------------------------------
# Verify both folders exist
# -------------------------------------------------------

if (-not (Test-Path $sourceFolder)) {
    Write-Host "Source folder not found."
    exit
}

if (-not (Test-Path $destinationFolder)) {
    Write-Host "Destination folder not found."
    exit
}

# -------------------------------------------------------
# Get all files from both folders
# -------------------------------------------------------

# Store only the relative path so the folders can be compared
# even though they have different root locations.

$sourceFiles = Get-ChildItem `
    -Path $sourceFolder `
    -File `
    -Recurse |
    ForEach-Object {

        $_.FullName.Replace((Resolve-Path $sourceFolder).Path, "")
    }

$destinationFiles = Get-ChildItem `
    -Path $destinationFolder `
    -File `
    -Recurse |
    ForEach-Object {

        $_.FullName.Replace((Resolve-Path $destinationFolder).Path, "")
    }

# -------------------------------------------------------
# Compare the folders
# -------------------------------------------------------

$comparison = Compare-Object `
    -ReferenceObject $sourceFiles `
    -DifferenceObject $destinationFiles

# -------------------------------------------------------
# Display results
# -------------------------------------------------------

if ($comparison.Count -eq 0) {

    Write-Host "The folders contain the same files."

}
else {

    Write-Host "Differences found:"
    Write-Host ""

    foreach ($item in $comparison) {

        if ($item.SideIndicator -eq "<=") {

            Write-Host "Only in Source      : $($item.InputObject)"

        }
        elseif ($item.SideIndicator -eq "=>") {

            Write-Host "Only in Destination : $($item.InputObject)"

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
Write-Host "Source Files      : $($sourceFiles.Count)"
Write-Host "Destination Files : $($destinationFiles.Count)"
Write-Host "Differences Found : $($comparison.Count)"
Write-Host ""