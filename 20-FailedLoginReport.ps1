<#
    Failed Login Report
    -------------------
    This script searches the Windows Security event log
    for failed login attempts.

    Windows Security Event ID:
    4625 = An account failed to log on.

    Features:
    - Queries the Windows Security event log
    - Finds failed login attempts
    - Displays useful security information
    - Counts failed login attempts
    - Handles errors gracefully

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# Windows Security Event Logs are not available on
# Linux or macOS.
if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Failed Login Report"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "Windows Security Event Logs are only available on Windows."
    Write-Host ""
    exit
}

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

# Security is the Windows event log containing
# authentication and security-related events.
$logName = "Security"

# Event ID 4625 means an account failed to log on.
$eventId = 4625

# Number of events to search.
$maxEvents = 100

Write-Host ""
Write-Host "==========================================="
Write-Host " Failed Login Report"
Write-Host "==========================================="
Write-Host ""
Write-Host "Searching the Security event log..."
Write-Host ""

# -------------------------------------------------------
# Query the Security event log
# -------------------------------------------------------

try {

    # FilterHashtable allows us to ask Windows Event Log
    # for only the events we are interested in.
    $failedLogins = Get-WinEvent -FilterHashtable @{
        LogName = $logName
        Id      = $eventId
    } -MaxEvents $maxEvents -ErrorAction Stop

}
catch {

    Write-Host "Unable to read the Security event log."
    Write-Host $_.Exception.Message
    exit
}

# -------------------------------------------------------
# Check whether events were found
# -------------------------------------------------------

if ($failedLogins.Count -eq 0) {

    Write-Host "No failed login attempts were found."

}
else {

    Write-Host "Failed login attempts found: $($failedLogins.Count)"
    Write-Host ""

    # ---------------------------------------------------
    # Display each failed login event
    # ---------------------------------------------------

    foreach ($event in $failedLogins) {

        Write-Host "-------------------------------------------"
        Write-Host "Time   : $($event.TimeCreated)"
        Write-Host "Event  : $($event.Id)"
        Write-Host "Message:"
        Write-Host $event.Message
        Write-Host ""

    }
}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Events Checked : $($failedLogins.Count)"
Write-Host "Event ID       : $eventId"
Write-Host "Event Meaning  : Failed logon attempt"
Write-Host ""
