<#
    Startup Programs Viewer
    -----------------------
    This script displays programs configured to start
    automatically when a user signs in.

    Features:
    - Cross-platform compatible
    - Reads startup programs from the Windows Registry
    - Lists shortcuts in the Startup folder
    - Displays a summary

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Startup Programs Viewer"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "Windows startup locations are only available on Windows."
    Write-Host ""
    exit

}

Write-Host ""
Write-Host "==========================================="
Write-Host " Startup Programs Viewer"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Registry locations containing startup programs
# -------------------------------------------------------

$registryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

Write-Host "Registry Startup Programs"
Write-Host "-------------------------"

foreach ($path in $registryPaths) {

    if (-not (Test-Path $path)) {
        continue
    }

    Write-Host ""
    Write-Host "Location: $path"

    # Retrieve all values stored in the Registry key.
    $properties = Get-ItemProperty -Path $path

    # Ignore PowerShell's built-in properties.
    foreach ($property in $properties.PSObject.Properties) {

        if ($property.Name -notmatch "^PS") {

            Write-Host ""
            Write-Host "Program : $($property.Name)"
            Write-Host "Command : $($property.Value)"

        }

    }

}

# -------------------------------------------------------
# Startup folder
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Startup Folder"
Write-Host "==========================================="

# Current user's Startup folder.
$startupFolder = Join-Path `
    $env:APPDATA `
    "Microsoft\Windows\Start Menu\Programs\Startup"

if (Test-Path $startupFolder) {

    $items = Get-ChildItem `
        -Path $startupFolder `
        -File

    if ($items.Count -eq 0) {

        Write-Host "No startup items found."

    }
    else {

        foreach ($item in $items) {

            Write-Host $item.Name

        }

    }

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

$startupCount = (
    Get-ChildItem `
        -Path $startupFolder `
        -File `
        -ErrorAction SilentlyContinue
).Count

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Startup Folder Items: $startupCount"
Write-Host ""