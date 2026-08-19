<#
    Printer Inventory
    -----------------
    This script displays printers installed on a Windows computer.

    Main concept:
    - Printer management

    Features:
    - Detects the operating system
    - Lists installed printers
    - Displays printer name, type, port, and status
    - Displays a summary

    Requires:
    - PowerShell 7+
    - Windows
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# The Windows printer cmdlets used by this project
# are not available on Linux or macOS.
if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Printer Inventory"
    Write-Host "==========================================="
    Write-Host ""

    Write-Host "This project requires Windows."
    Write-Host "Windows printer management cmdlets are not"
    Write-Host "available on Linux or macOS."

    Write-Host ""
    exit
}

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Printer Inventory"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Get installed printers
# -------------------------------------------------------

try {

    # Get all printers installed on the computer.
    $printers = Get-Printer -ErrorAction Stop |
        Sort-Object Name

}
catch {

    Write-Host "Unable to retrieve printers."
    Write-Host $_.Exception.Message
    exit
}

# -------------------------------------------------------
# Check whether printers were found
# -------------------------------------------------------

if ($printers.Count -eq 0) {

    Write-Host "No printers were found."

}
else {

    Write-Host "Installed Printers:"
    Write-Host ""

    # ---------------------------------------------------
    # Display printer information
    # ---------------------------------------------------

    foreach ($printer in $printers) {

        Write-Host "-------------------------------------------"
        Write-Host "Name       : $($printer.Name)"
        Write-Host "Type       : $($printer.Type)"
        Write-Host "Port       : $($printer.PortName)"
        Write-Host "Shared     : $($printer.Shared)"
        Write-Host "Published  : $($printer.Published)"
        Write-Host ""

    }
}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Printers Found: $($printers.Count)"
Write-Host ""
