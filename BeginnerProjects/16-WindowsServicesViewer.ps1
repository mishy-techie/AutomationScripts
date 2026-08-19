<#
    Windows Services Viewer
    -----------------------
    This script displays information about Windows services.

    Features:
    - Cross-platform compatible
    - Lists Windows services
    - Displays service name, display name, and status
    - Sorts services alphabetically

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# Windows Services only exist on Windows.
if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Windows Services Viewer"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "Windows Services are only available on Windows."
    Write-Host "This script cannot display services on this operating system."
    Write-Host ""
    exit

}

Write-Host ""
Write-Host "==========================================="
Write-Host " Windows Services Viewer"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Get all Windows services
# -------------------------------------------------------

# Retrieve every installed service.
$services = Get-Service |
    Sort-Object DisplayName

# -------------------------------------------------------
# Display the services
# -------------------------------------------------------

$services |
    Format-Table `
        Name,
        DisplayName,
        Status `
        -AutoSize

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Total Services: $($services.Count)"
Write-Host ""