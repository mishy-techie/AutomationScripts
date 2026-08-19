<#
    Process Manager
    ---------------
    This script displays all running processes and allows the
    user to stop a process by entering its Process ID (PID).

    Features:
    - Cross-platform (Windows, Linux, macOS)
    - Lists running processes
    - Displays Process ID (PID), Process Name, and CPU time
    - Allows the user to stop a process
    - Handles errors gracefully

    Requires:
    PowerShell 7+
#>

# -------------------------------------------------------
# Display script title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Process Manager"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Get all running processes
# -------------------------------------------------------

# Retrieve all running processes and sort them by name.
$processes = Get-Process |
    Sort-Object ProcessName

# Display the process list.
$processes |
    Select-Object `
        Id,
        ProcessName,
        CPU |
    Format-Table -AutoSize

# -------------------------------------------------------
# Ask the user for a Process ID
# -------------------------------------------------------

Write-Host ""
$processId = Read-Host "Enter the Process ID (PID) to stop (or press Enter to exit)"

# Exit if the user presses Enter without typing anything.
if ([string]::IsNullOrWhiteSpace($processId)) {

    Write-Host ""
    Write-Host "No process selected. Exiting..."
    exit

}

# -------------------------------------------------------
# Attempt to stop the selected process
# -------------------------------------------------------

try {

    Stop-Process `
        -Id $processId `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "Process stopped successfully."

}
catch {

    Write-Host ""
    Write-Host "Unable to stop the process."
    Write-Host $_.Exception.Message

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Operation Complete"
Write-Host "==========================================="
Write-Host ""