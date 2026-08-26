<#
.SYNOPSIS
    Cross-platform PC Health Check

.DESCRIPTION
    Performs multiple system-health checks and displays a summary report.

    Checks:
      - Operating system
      - PowerShell version
      - CPU information
      - Memory usage
      - Disk space
      - Network connectivity
      - System uptime
      - Battery status (when available)

.NOTES
    Recommended: PowerShell 7+
#>

$Results = @()

function Add-CheckResult {
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

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         PC HEALTH CHECK" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------
# 1. Operating System
# --------------------------------------------------

try {
    $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

    Add-CheckResult `
        -Check "Operating System" `
        -Status "OK" `
        -Details "$($OS.Caption) $($OS.OSArchitecture)"
}
catch {
    if ($IsLinux) {
        $OSName = (Get-Content /etc/os-release |
            Where-Object { $_ -match '^PRETTY_NAME=' } |
            Select-Object -First 1) -replace 'PRETTY_NAME=', '' -replace '"', ''

        Add-CheckResult `
            -Check "Operating System" `
            -Status "OK" `
            -Details $OSName
    }
    elseif ($IsMacOS) {
        $OSName = sw_vers -productName
        $OSVersion = sw_vers -productVersion

        Add-CheckResult `
            -Check "Operating System" `
            -Status "OK" `
            -Details "$OSName $OSVersion"
    }
}

# --------------------------------------------------
# 2. PowerShell Version
# --------------------------------------------------

Add-CheckResult `
    -Check "PowerShell" `
    -Status "OK" `
    -Details $PSVersionTable.PSVersion.ToString()

# --------------------------------------------------
# 3. CPU Check
# --------------------------------------------------

try {
    if ($IsWindows) {
        $CPU = Get-CimInstance Win32_Processor |
            Select-Object -First 1

        $CPUName = $CPU.Name.Trim()
        $Cores = $CPU.NumberOfLogicalProcessors

        Add-CheckResult `
            -Check "CPU" `
            -Status "OK" `
            -Details "$CPUName ($Cores logical processors)"
    }
    elseif ($IsLinux) {
        $CPUName = (Get-Content /proc/cpuinfo |
            Where-Object { $_ -match '^model name' } |
            Select-Object -First 1) -replace '^model name\s*:\s*', ''

        $Cores = (Get-Content /proc/cpuinfo |
            Where-Object { $_ -match '^processor' }).Count

        Add-CheckResult `
            -Check "CPU" `
            -Status "OK" `
            -Details "$CPUName ($Cores logical processors)"
    }
    elseif ($IsMacOS) {
        $CPUName = sysctl -n machdep.cpu.brand_string
        $Cores = sysctl -n hw.logicalcpu

        Add-CheckResult `
            -Check "CPU" `
            -Status "OK" `
            -Details "$CPUName ($Cores logical processors)"
    }
}
catch {
    Add-CheckResult `
        -Check "CPU" `
        -Status "WARNING" `
        -Details "Unable to retrieve CPU information."
}

# --------------------------------------------------
# 4. Memory Check
# --------------------------------------------------

try {
    if ($IsWindows) {
        $ComputerSystem = Get-CimInstance Win32_ComputerSystem
        $TotalMemoryGB = [math]::Round(
            $ComputerSystem.TotalPhysicalMemory / 1GB, 2
        )

        $OSInfo = Get-CimInstance Win32_OperatingSystem
        $FreeMemoryGB = [math]::Round(
            $OSInfo.FreePhysicalMemory / 1MB, 2
        )

        $UsedMemoryGB = [math]::Round(
            $TotalMemoryGB - $FreeMemoryGB, 2
        )
    }
    elseif ($IsLinux) {
        $Memory = Get-Content /proc/meminfo

        $TotalKB = [int64](
            ($Memory |
                Where-Object { $_ -match '^MemTotal:' }) `
                -replace '\D+', ''
        )

        $AvailableKB = [int64](
            ($Memory |
                Where-Object { $_ -match '^MemAvailable:' }) `
                -replace '\D+', ''
        )

        $TotalMemoryGB = [math]::Round($TotalKB / 1MB, 2)
        $FreeMemoryGB = [math]::Round($AvailableKB / 1MB, 2)
        $UsedMemoryGB = [math]::Round(
            $TotalMemoryGB - $FreeMemoryGB, 2
        )
    }
    elseif ($IsMacOS) {
        $TotalBytes = [int64](sysctl -n hw.memsize)
        $TotalMemoryGB = [math]::Round(
            $TotalBytes / 1GB, 2
        )

        $VMStat = vm_stat
        $PageSize = 4096

        $FreePages = [int64](
            (($VMStat |
                Select-String "Pages free") -replace '[^0-9]', '')
        )

        $FreeMemoryGB = [math]::Round(
            ($FreePages * $PageSize) / 1GB, 2
        )

        $UsedMemoryGB = [math]::Round(
            $TotalMemoryGB - $FreeMemoryGB, 2
        )
    }

    $MemoryPercent = [math]::Round(
        ($UsedMemoryGB / $TotalMemoryGB) * 100, 1
    )

    if ($MemoryPercent -lt 80) {
        $MemoryStatus = "OK"
    }
    else {
        $MemoryStatus = "WARNING"
    }

    Add-CheckResult `
        -Check "Memory" `
        -Status $MemoryStatus `
        -Details "$UsedMemoryGB GB used of $TotalMemoryGB GB ($MemoryPercent%)"
}
catch {
    Add-CheckResult `
        -Check "Memory" `
        -Status "WARNING" `
        -Details "Unable to retrieve memory information."
}

# --------------------------------------------------
# 5. Disk Space Check
# --------------------------------------------------

try {
    $Drives = Get-PSDrive -PSProvider FileSystem

    foreach ($Drive in $Drives) {
        if ($Drive.Used -and $Drive.Free) {
            $TotalGB = [math]::Round(
                ($Drive.Used + $Drive.Free) / 1GB, 2
            )

            $FreeGB = [math]::Round(
                $Drive.Free / 1GB, 2
            )

            $FreePercent = [math]::Round(
                ($Drive.Free / ($Drive.Used + $Drive.Free)) * 100,
                1
            )

            if ($FreePercent -lt 10) {
                $Status = "WARNING"
            }
            else {
                $Status = "OK"
            }

            Add-CheckResult `
                -Check "Disk $($Drive.Name)" `
                -Status $Status `
                -Details "$FreeGB GB free of $TotalGB GB ($FreePercent% free)"
        }
    }
}
catch {
    Add-CheckResult `
        -Check "Disk" `
        -Status "WARNING" `
        -Details "Unable to retrieve disk information."
}

# --------------------------------------------------
# 6. Network Connectivity
# --------------------------------------------------

try {
    $TestConnection = Test-Connection `
        -ComputerName "1.1.1.1" `
        -Count 1 `
        -Quiet `
        -ErrorAction SilentlyContinue

    if ($TestConnection) {
        Add-CheckResult `
            -Check "Network" `
            -Status "OK" `
            -Details "Internet connectivity is available."
    }
    else {
        Add-CheckResult `
            -Check "Network" `
            -Status "WARNING" `
            -Details "Internet connectivity test failed."
    }
}
catch {
    Add-CheckResult `
        -Check "Network" `
        -Status "WARNING" `
        -Details "Unable to test network connectivity."
}

# --------------------------------------------------
# 7. System Uptime
# --------------------------------------------------

try {
    if ($IsWindows) {
        $OSInfo = Get-CimInstance Win32_OperatingSystem
        $BootTime = $OSInfo.LastBootUpTime
    }
    elseif ($IsLinux) {
        $UptimeSeconds = [double](
            (Get-Content /proc/uptime).Split()[0]
        )

        $BootTime = (Get-Date).AddSeconds(-$UptimeSeconds)
    }
    elseif ($IsMacOS) {
        $BootString = sysctl -n kern.boottime
        $BootUnix = [int64](
            [regex]::Match($BootString, '\d+').Value
        )

        $BootTime = [DateTimeOffset]::FromUnixTimeSeconds(
            $BootUnix
        ).LocalDateTime
    }

    $Uptime = (Get-Date) - $BootTime

    Add-CheckResult `
        -Check "System Uptime" `
        -Status "OK" `
        -Details "$($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes"
}
catch {
    Add-CheckResult `
        -Check "System Uptime" `
        -Status "WARNING" `
        -Details "Unable to determine system uptime."
}

# --------------------------------------------------
# 8. Battery Check
# --------------------------------------------------

try {
    if ($IsWindows) {
        $Battery = Get-CimInstance Win32_Battery `
            -ErrorAction SilentlyContinue

        if ($Battery) {
            $BatteryLevel = $Battery.EstimatedChargeRemaining

            if ($BatteryLevel -lt 20) {
                $BatteryStatus = "WARNING"
            }
            else {
                $BatteryStatus = "OK"
            }

            Add-CheckResult `
                -Check "Battery" `
                -Status $BatteryStatus `
                -Details "$BatteryLevel% remaining"
        }
        else {
            Add-CheckResult `
                -Check "Battery" `
                -Status "N/A" `
                -Details "No battery detected."
        }
    }
    else {
        Add-CheckResult `
            -Check "Battery" `
            -Status "N/A" `
            -Details "Battery check not implemented for this platform."
    }
}
catch {
    Add-CheckResult `
        -Check "Battery" `
        -Status "N/A" `
        -Details "Battery information unavailable."
}

# --------------------------------------------------
# Display Results
# --------------------------------------------------

Write-Host ""
Write-Host "HEALTH CHECK RESULTS" -ForegroundColor Cyan
Write-Host "----------------------------------------"

foreach ($Result in $Results) {

    switch ($Result.Status) {
        "OK" {
            $Color = "Green"
        }
        "WARNING" {
            $Color = "Yellow"
        }
        default {
            $Color = "Gray"
        }
    }

    Write-Host "$($Result.Check): " -NoNewline
    Write-Host $Result.Status -ForegroundColor $Color
    Write-Host "  $($Result.Details)"
}

# --------------------------------------------------
# Overall Health
# --------------------------------------------------

$Warnings = @(
    $Results | Where-Object {
        $_.Status -eq "WARNING"
    }
).Count

Write-Host ""
Write-Host "========================================="

if ($Warnings -eq 0) {
    Write-Host "Overall Health: GOOD" -ForegroundColor Green
}
else {
    Write-Host "Overall Health: $Warnings warning(s) found" `
        -ForegroundColor Yellow
}

Write-Host "========================================="