# =====================================
# Project 2 - System Information Viewer
# Cross-Platform Edition
# =====================================

Clear-Host

Write-Host "========================================"
Write-Host "      SYSTEM INFORMATION VIEWER"
Write-Host "========================================"
Write-Host ""

# Computer Name
$ComputerName = [System.Environment]::MachineName

# Current User
$CurrentUser = [System.Environment]::UserName

# Operating System
$OperatingSystem = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription

# PowerShell Version
$PowerShellVersion = $PSVersionTable.PSVersion

# Date & Time
$CurrentDate = Get-Date -Format "dd MMMM yyyy"
$CurrentTime = Get-Date -Format "HH:mm:ss"

Write-Host "Computer Name : $ComputerName"
Write-Host "Current User  : $CurrentUser"
Write-Host "Operating Sys : $OperatingSystem"
Write-Host "PowerShell    : $PowerShellVersion"
Write-Host "Date          : $CurrentDate"
Write-Host "Time          : $CurrentTime"

Write-Host ""
Write-Host "========================================"