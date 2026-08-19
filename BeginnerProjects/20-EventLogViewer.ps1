<#
    Event Log Viewer
    ----------------
    This script displays recent entries from the Windows
    System Event Log.

    Features:
    - Cross-platform compatible
    - Reads the Windows System Event Log
    - Displays recent events
    - Shows Event ID, Level, Time Created and Message
    - Displays a summary

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# Windows Event Logs only exist on Windows.
if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Event Log Viewer"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "Windows Event Logs are only available on Windows."
    Write-Host ""
    exit

}

Write-Host ""
Write-Host "==========================================="
Write-Host " Event Log Viewer"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

# Name of the event log to read.
$logName = "System"

# Number of recent events to display.
$maxEvents = 20

# -------------------------------------------------------
# Retrieve recent events
# -------------------------------------------------------

try {

    # Get the most recent events from the selected log.
    $events = Get-WinEvent `
        -LogName $logName `
        -MaxEvents $maxEvents `
        -ErrorAction Stop

}
catch {

    Write-Host "Unable to read the event log."
    Write-Host $_.Exception.Message
    exit

}

# -------------------------------------------------------
# Display the events
# -------------------------------------------------------

$events |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        ProviderName,
        Message |
    Format-Table -Wrap -AutoSize

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Log Name       : $logName"
Write-Host "Events Displayed: $($events.Count)"
Write-Host ""