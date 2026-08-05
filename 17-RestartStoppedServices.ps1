<#
    Restart Stopped Services
    ------------------------
    This script checks Windows services and attempts to start
    services that are currently stopped.

    Features:
    - Detects Windows operating system
    - Finds stopped services
    - Attempts to start each stopped service
    - Handles errors gracefully
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
    Write-Host " Restart Stopped Services"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "Windows Services are only available on Windows."
    Write-Host ""
    exit

}

Write-Host ""
Write-Host "==========================================="
Write-Host " Restart Stopped Services"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Get all stopped services
# -------------------------------------------------------

# Retrieve services whose current status is "Stopped".
$stoppedServices = Get-Service |
    Where-Object {
        $_.Status -eq "Stopped"
    }

# Statistics
$startedCount = 0
$failedCount = 0

# -------------------------------------------------------
# Attempt to start each stopped service
# -------------------------------------------------------

foreach ($service in $stoppedServices) {

    Write-Host "Checking: $($service.DisplayName)"

    # Some services cannot be started manually.
    # Skip services that are disabled.
    if ($service.StartType -eq "Disabled") {

        Write-Host "Skipped (Disabled)"
        Write-Host ""
        continue

    }

    try {

        Start-Service `
            -Name $service.Name `
            -ErrorAction Stop

        Write-Host "Started successfully."
        Write-Host ""

        $startedCount++

    }
    catch {

        Write-Host "Could not start the service."
        Write-Host ""

        $failedCount++

    }

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Stopped Services Found : $($stoppedServices.Count)"
Write-Host "Started Successfully   : $startedCount"
Write-Host "Failed                 : $failedCount"
Write-Host ""