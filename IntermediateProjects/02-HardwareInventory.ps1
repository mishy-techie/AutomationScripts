#requires -Version 7.0

<#
.SYNOPSIS
    Hardware Inventory using WMI/CIM

.DESCRIPTION
    Collects hardware information including:
      - Computer/system information
      - BIOS
      - CPU
      - Memory
      - Disk drives
      - Network adapters
      - Video controllers

    Tested conceptually for Windows PowerShell/CIM usage.

.NOTES
    Project: Hardware Inventory
    Concept: WMI/CIM
#>

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       HARDWARE INVENTORY REPORT        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------
# Computer Information
# ---------------------------------------------------------

$Computer = Get-CimInstance -ClassName Win32_ComputerSystem

Write-Host "COMPUTER INFORMATION" -ForegroundColor Yellow
Write-Host "--------------------"

[PSCustomObject]@{
    Manufacturer = $Computer.Manufacturer
    Model        = $Computer.Model
    ComputerName = $Computer.Name
    Domain       = $Computer.Domain
    TotalMemoryGB = [math]::Round(
        $Computer.TotalPhysicalMemory / 1GB, 2
    )
} | Format-List

# ---------------------------------------------------------
# BIOS Information
# ---------------------------------------------------------

Write-Host "BIOS INFORMATION" -ForegroundColor Yellow
Write-Host "----------------"

Get-CimInstance -ClassName Win32_BIOS |
    Select-Object Manufacturer,
                  SMBIOSBIOSVersion,
                  SerialNumber,
                  ReleaseDate |
    Format-List

# ---------------------------------------------------------
# Processor Information
# ---------------------------------------------------------

Write-Host "PROCESSOR INFORMATION" -ForegroundColor Yellow
Write-Host "---------------------"

Get-CimInstance -ClassName Win32_Processor |
    Select-Object Name,
                  Manufacturer,
                  NumberOfCores,
                  NumberOfLogicalProcessors,
                  MaxClockSpeed |
    Format-List

# ---------------------------------------------------------
# Memory Information
# ---------------------------------------------------------

Write-Host "MEMORY MODULES" -ForegroundColor Yellow
Write-Host "--------------"

Get-CimInstance -ClassName Win32_PhysicalMemory |
    Select-Object DeviceLocator,
                  Manufacturer,
                  PartNumber,
                  SerialNumber,
                  @{Name="CapacityGB"; Expression={
                      [math]::Round($_.Capacity / 1GB, 2)
                  }},
                  Speed |
    Format-Table -AutoSize

# ---------------------------------------------------------
# Disk Information
# ---------------------------------------------------------

Write-Host "DISK DRIVES" -ForegroundColor Yellow
Write-Host "-----------"

Get-CimInstance -ClassName Win32_DiskDrive |
    Select-Object Model,
                  Manufacturer,
                  SerialNumber,
                  InterfaceType,
                  MediaType,
                  @{Name="SizeGB"; Expression={
                      [math]::Round($_.Size / 1GB, 2)
                  }} |
    Format-Table -AutoSize

# ---------------------------------------------------------
# Network Adapters
# ---------------------------------------------------------

Write-Host "NETWORK ADAPTERS" -ForegroundColor Yellow
Write-Host "----------------"

Get-CimInstance -ClassName Win32_NetworkAdapter |
    Where-Object {
        $_.PhysicalAdapter -eq $true
    } |
    Select-Object Name,
                  Manufacturer,
                  MACAddress,
                  AdapterType,
                  Speed,
                  NetEnabled |
    Format-Table -AutoSize

# ---------------------------------------------------------
# Graphics / Video Controller
# ---------------------------------------------------------

Write-Host "GRAPHICS INFORMATION" -ForegroundColor Yellow
Write-Host "--------------------"

Get-CimInstance -ClassName Win32_VideoController |
    Select-Object Name,
                  AdapterCompatibility,
                  DriverVersion,
                  VideoModeDescription,
                  @{Name="AdapterRAM_GB"; Expression={
                      if ($_.AdapterRAM) {
                          [math]::Round($_.AdapterRAM / 1GB, 2)
                      }
                  }} |
    Format-Table -AutoSize

# ---------------------------------------------------------
# Operating System
# ---------------------------------------------------------

Write-Host "OPERATING SYSTEM" -ForegroundColor Yellow
Write-Host "----------------"

Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object Caption,
                  Version,
                  BuildNumber,
                  OSArchitecture,
                  SerialNumber |
    Format-List

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "       INVENTORY COMPLETE               " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green