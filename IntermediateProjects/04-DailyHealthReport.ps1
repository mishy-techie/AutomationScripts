#requires -Version 7.0

<#
.SYNOPSIS
    Daily PC Health Report

.DESCRIPTION
    Automatically checks system health and generates a daily report.

    Checks:
      - CPU usage
      - Memory usage
      - Disk space
      - System uptime
      - Internet connectivity
      - Operating system
      - Overall health

.NOTES
    Project: Daily Health Report
    Concept: Automation
#>

$ReportDirectory = Join-Path $HOME "PC-Health-Reports"

# Create report directory if it does not exist
if (-not (Test-Path $ReportDirectory)) {
    New-Item `
        -Path $ReportDirectory `
        -ItemType Directory `
        -Force |
        Out-Null
}

$Date = Get-Date
$ComputerName = [System.Environment]::MachineName

$Results = @()

function Add-Result {
    param (
        [string]$Check,
        [string]$Status,
        [string]$Details
    )

    $script:Results += [PSCustomObject]@{
        Check   = $Check
        Status  = $Status
        Details = $Details
    }
}

# ---------------------------------------------------------
# Operating System
# ---------------------------------------------------------

if ($IsWindows) {
    $OS = Get-CimInstance Win32_OperatingSystem

    Add-Result `
        -Check "Operating System" `
        -Status "OK" `
        -Details $OS.Caption
}
else {
    Add-Result `
        -Check "Operating System" `
        -Status "OK" `
        -Details ([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)
}

# ---------------------------------------------------------
# CPU
# ---------------------------------------------------------

try {
    if ($IsWindows) {

        $CPU = (
            Get-Counter '\Processor(_Total)\% Processor Time'
        ).CounterSamples.CookedValue

        $CPU = [math]::Round($CPU, 1)

        if ($CPU -lt 80) {
            $Status = "OK"
        }
        elseif ($CPU -lt 95) {
            $Status = "WARNING"
        }
        else {
            $Status = "CRITICAL"
        }

        Add-Result `
            -Check "CPU Usage" `
            -Status $Status `
            -Details "$CPU%"

    }
    else {
        Add-Result `
            -Check "CPU Usage" `
            -Status "INFO" `
            -Details "Platform-specific CPU monitoring required."
    }
}
catch {
    Add-Result `
        -Check "CPU Usage" `
        -Status "INFO" `
        -Details "CPU information unavailable."
}

# ---------------------------------------------------------
# Memory
# ---------------------------------------------------------

try {

    if ($IsWindows) {

        $TotalMemory = $OS.TotalVisibleMemorySize * 1KB
        $FreeMemory  = $OS.FreePhysicalMemory * 1KB

        $UsedMemory = $TotalMemory - $FreeMemory

        $MemoryPercent = [math]::Round(
            ($UsedMemory / $TotalMemory) * 100,
            1
        )

        if ($MemoryPercent -lt 80) {
            $Status = "OK"
        }
        elseif ($MemoryPercent -lt 90) {
            $Status = "WARNING"
        }
        else {
            $Status = "CRITICAL"
        }

        Add-Result `
            -Check "Memory Usage" `
            -Status $Status `
            -Details "$MemoryPercent% used"

    }
    else {

        Add-Result `
            -Check "Memory Usage" `
            -Status "INFO" `
            -Details "Platform-specific memory monitoring required."
    }

}
catch {

    Add-Result `
        -Check "Memory Usage" `
        -Status "INFO" `
        -Details "Memory information unavailable."
}

# ---------------------------------------------------------
# Disk Space
# ---------------------------------------------------------

try {

    $Drives = Get-PSDrive -PSProvider FileSystem

    foreach ($Drive in $Drives) {

        $Total = $Drive.Used + $Drive.Free

        if ($Total -gt 0) {

            $FreePercent = [math]::Round(
                ($Drive.Free / $Total) * 100,
                1
            )

            if ($FreePercent -gt 20) {
                $Status = "OK"
            }
            elseif ($FreePercent -gt 10) {
                $Status = "WARNING"
            }
            else {
                $Status = "CRITICAL"
            }

            Add-Result `
                -Check "Disk $($Drive.Name)" `
                -Status $Status `
                -Details "$FreePercent% free"
        }
    }
}
catch {

    Add-Result `
        -Check "Disk Space" `
        -Status "INFO" `
        -Details "Disk information unavailable."
}

# ---------------------------------------------------------
# Uptime
# ---------------------------------------------------------

try {

    if ($IsWindows) {

        $BootTime = $OS.LastBootUpTime
    }
    else {

        $BootTime = (Get-Date).AddMilliseconds(
            -[Environment]::TickCount64
        )
    }

    $Uptime = (Get-Date) - $BootTime

    Add-Result `
        -Check "System Uptime" `
        -Status "OK" `
        -Details "$($Uptime.Days) days, $($Uptime.Hours) hours"
}
catch {

    Add-Result `
        -Check "System Uptime" `
        -Status "INFO" `
        -Details "Uptime unavailable."
}

# ---------------------------------------------------------
# Internet Connectivity
# ---------------------------------------------------------

try {

    $Internet = Test-Connection `
        -ComputerName "1.1.1.1" `
        -Count 1 `
        -Quiet `
        -ErrorAction SilentlyContinue

    if ($Internet) {

        Add-Result `
            -Check "Internet Connectivity" `
            -Status "OK" `
            -Details "Internet connection available."
    }
    else {

        Add-Result `
            -Check "Internet Connectivity" `
            -Status "CRITICAL" `
            -Details "Internet connection unavailable."
    }
}
catch {

    Add-Result `
        -Check "Internet Connectivity" `
        -Status "WARNING" `
        -Details "Connectivity test failed."
}

# ---------------------------------------------------------
# Overall Health
# ---------------------------------------------------------

$Critical = @(
    $Results |
        Where-Object Status -eq "CRITICAL"
).Count

$Warnings = @(
    $Results |
        Where-Object Status -eq "WARNING"
).Count

if ($Critical -gt 0) {
    $OverallStatus = "CRITICAL"
}
elseif ($Warnings -gt 0) {
    $OverallStatus = "WARNING"
}
else {
    $OverallStatus = "HEALTHY"
}

# ---------------------------------------------------------
# Create Daily Report
# ---------------------------------------------------------

$ReportFile = Join-Path `
    $ReportDirectory `
    "Health-Report-$($Date.ToString('yyyy-MM-dd')).txt"

$Report = @"

=========================================
          DAILY HEALTH REPORT
=========================================

Computer : $ComputerName
Date     : $Date
Status   : $OverallStatus

-----------------------------------------
HEALTH CHECKS
-----------------------------------------

$(
    $Results |
        Format-Table Check, Status, Details -AutoSize |
        Out-String
)

-----------------------------------------
SUMMARY
-----------------------------------------

Critical Issues : $Critical
Warnings        : $Warnings
Checks Performed: $($Results.Count)

=========================================
"@

$Report | Out-File `
    -FilePath $ReportFile `
    -Encoding UTF8

# Also display the report
Write-Host $Report

Write-Host "Report saved to:" -ForegroundColor Green
Write-Host $ReportFile -ForegroundColor Cyan