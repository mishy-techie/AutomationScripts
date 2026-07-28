# ============================================
# Project 7 - Network Information Viewer
# ============================================

Clear-Host

Write-Host "==============================================="
Write-Host "       NETWORK INFORMATION VIEWER"
Write-Host "==============================================="
Write-Host ""

# Computer Information
$ComputerName = [System.Environment]::MachineName
$CurrentUser = [System.Environment]::UserName
$OperatingSystem = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription

# Date & Time
$Date = Get-Date -Format "dd MMMM yyyy"
$Time = Get-Date -Format "HH:mm:ss"

# Host Information
$HostEntry = [System.Net.Dns]::GetHostEntry($ComputerName)

$IPv4 = $HostEntry.AddressList |
    Where-Object { $_.AddressFamily -eq 'InterNetwork' }

$IPv6 = $HostEntry.AddressList |
    Where-Object { $_.AddressFamily -eq 'InterNetworkV6' }

Write-Host "Computer Name : $ComputerName"
Write-Host "Current User  : $CurrentUser"
Write-Host "Operating Sys : $OperatingSystem"

Write-Host ""
Write-Host "DNS Host Name : $($HostEntry.HostName)"

Write-Host ""
Write-Host "IPv4 Address(es)"
Write-Host "----------------"

foreach ($ip in $IPv4) {
    Write-Host $ip.IPAddressToString
}

Write-Host ""

Write-Host "IPv6 Address(es)"
Write-Host "----------------"

foreach ($ip in $IPv6) {
    Write-Host $ip.IPAddressToString
}

Write-Host ""

Write-Host "Date          : $Date"
Write-Host "Time          : $Time"

Write-Host ""
Write-Host "==============================================="