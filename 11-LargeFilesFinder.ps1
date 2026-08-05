<#
    Large Files Finder
    ------------------
    This script searches a directory and displays files that are
    larger than a specified size.

    Features:
    - Cross-platform (Windows, Linux, macOS)
    - Traverses directories recursively
    - Filters files by size
    - Sorts results from largest to smallest
    - Displays a summary

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

# The directory to search.
# "." means the current working directory.
$searchDirectory = "."

# Minimum file size (in MB).
# Only files larger than this value will be displayed.
$minimumSizeMB = 10

# Convert MB to bytes because file sizes are stored in bytes.
$minimumSizeBytes = $minimumSizeMB * 1MB

Write-Host ""
Write-Host "==========================================="
Write-Host " Large Files Finder"
Write-Host "==========================================="
Write-Host "Searching: $searchDirectory"
Write-Host "Minimum Size: $minimumSizeMB MB"
Write-Host ""

# -------------------------------------------------------
# Verify the directory exists
# -------------------------------------------------------

if (-not (Test-Path $searchDirectory)) {
    Write-Host "Directory not found."
    exit
}

# -------------------------------------------------------
# Find files
# -------------------------------------------------------

# Get every file inside the directory and its subdirectories.
$largeFiles = Get-ChildItem `
    -Path $searchDirectory `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |

    # Keep only files larger than the minimum size.
    Where-Object {
        $_.Length -ge $minimumSizeBytes
    } |

    # Sort largest to smallest.
    Sort-Object Length -Descending

# -------------------------------------------------------
# Display results
# -------------------------------------------------------

if ($largeFiles.Count -eq 0) {

    Write-Host "No large files were found."

}
else {

    Write-Host "Large files found:"
    Write-Host ""

    foreach ($file in $largeFiles) {

        # Convert file size to MB for easier reading.
        $sizeMB = [Math]::Round($file.Length / 1MB, 2)

        Write-Host "File : $($file.Name)"
        Write-Host "Size : $sizeMB MB"
        Write-Host "Path : $($file.FullName)"
        Write-Host "-------------------------------------------"
    }

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Files Found: $($largeFiles.Count)"
Write-Host ""