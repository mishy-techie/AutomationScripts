# ==========================================================
# Project: IP Configuration Report
# Author: Your Name
#
# Description:
# This script creates a report containing the computer's
# network configuration and saves it to a text file.
#
# Skills Demonstrated:
# - Variables
# - File Output
# - Conditional Statements (if/else)
# - PowerShell Commands
# - Comments
#
# This script works on both Windows and Linux.
# ==========================================================

# Store the report file name in a variable
$ReportFile = "IP_Report.txt"

# Create the report title
"===================================" | Out-File $ReportFile
"      IP Configuration Report" | Out-File $ReportFile -Append
"===================================" | Out-File $ReportFile -Append

# Add the date and time the report was created
"Report Created: $(Get-Date)" | Out-File $ReportFile -Append

# Get the computer name
$ComputerName = [System.Net.Dns]::GetHostName()

# Add the computer name to the report
"Computer Name: $ComputerName" | Out-File $ReportFile -Append

# Add a blank line
"" | Out-File $ReportFile -Append

# Check which operating system is running
if ($IsWindows)
{
    # This section runs only on Windows

    "Operating System: Windows" | Out-File $ReportFile -Append
    "" | Out-File $ReportFile -Append
    "===== Network Configuration =====" | Out-File $ReportFile -Append

    # Get the Windows IP configuration
    Get-NetIPConfiguration | Out-File $ReportFile -Append
}
else
{
    # This section runs on Linux or macOS

    "Operating System: Linux/macOS" | Out-File $ReportFile -Append
    "" | Out-File $ReportFile -Append
    "===== Network Configuration =====" | Out-File $ReportFile -Append

    # Get the network configuration using the Linux/macOS command
    ip addr | Out-File $ReportFile -Append
}

# Add a blank line
"" | Out-File $ReportFile -Append

# Add the end of the report
"===================================" | Out-File $ReportFile -Append
"End of Report" | Out-File $ReportFile -Append
"===================================" | Out-File $ReportFile -Append

# Display a message letting the user know the report is finished
Write-Host "The IP Configuration Report has been saved as '$ReportFile'."