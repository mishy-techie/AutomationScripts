<#
    Installed Software Inventory
    ----------------------------
    This script displays installed software by reading the
    Windows Registry.

    Features:
    - Cross-platform compatible
    - Reads installed applications from the Windows Registry
    - Displays software name, version, and publisher
    - Sorts results alphabetically

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# The Windows Registry is only available on Windows.
# If running on Linux or macOS, display a message and exit.

if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Installed Software Inventory"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "This project demonstrates Windows Registry access."
    Write-Host "The Windows Registry is not available on this operating system."
    Write-Host ""
    exit

}

# -------------------------------------------------------
# Registry locations containing installed software
# -------------------------------------------------------

# 64-bit applications
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",

    # 32-bit applications on a 64-bit Windows installation
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

Write-Host ""
Write-Host "==========================================="
Write-Host " Installed Software Inventory"
Write-Host "==========================================="
Write-Host ""

# This array will store information about installed software.
$softwareInventory = @()

# -------------------------------------------------------
# Read each Registry location
# -------------------------------------------------------

foreach ($path in $registryPaths) {

    # Skip Registry paths that do not exist.
    if (-not (Test-Path $path)) {
        continue
    }

    # Each subkey usually represents one installed application.
    $applications = Get-ChildItem -Path $path

    foreach ($application in $applications) {

        try {

            # Read the values stored in the Registry key.
            $properties = Get-ItemProperty -Path $application.PSPath

            # Ignore entries without a display name.
            if ([string]::IsNullOrWhiteSpace($properties.DisplayName)) {
                continue
            }

            # Store the software information in a custom object.
            $softwareInventory += [PSCustomObject]@{
                Name      = $properties.DisplayName
                Version   = $properties.DisplayVersion
                Publisher = $properties.Publisher
            }

        }
        catch {

            # Some Registry keys may not be readable.
            # Continue with the remaining applications.
            continue

        }

    }

}

# -------------------------------------------------------
# Display the results
# -------------------------------------------------------

$softwareInventory |
    Sort-Object Name |
    Format-Table `
        Name,
        Version,
        Publisher `
        -AutoSize

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Applications Found: $($softwareInventory.Count)"
Write-Host ""