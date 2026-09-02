#requires -Version 7.0

<#
.SYNOPSIS
    Performs routine PC maintenance tasks.

.DESCRIPTION
    Cleans temporary files, clears selected caches, checks disk space,
    and optionally creates a maintenance log.

    The script is designed to run manually or through Windows Task Scheduler.

.NOTES
    Project: Scheduled Maintenance Script
    Concept: Task Scheduler
    Language: PowerShell
#>

$ErrorActionPreference = "Continue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$LogDirectory = Join-Path $PSScriptRoot "logs"

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

$LogFile = Join-Path $LogDirectory "maintenance-$(Get-Date -Format 'yyyy-MM-dd').log"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Timestamp] [$Level] $Message"

    Write-Host $Line
    Add-Content -Path $LogFile -Value $Line
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Write-Log "========================================"
Write-Log "Scheduled Maintenance Started"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "User: $env:USERNAME"
Write-Log "PowerShell: $($PSVersionTable.PSVersion)"
Write-Log "========================================"

# ------------------------------------------------------------
# Check operating system
# ------------------------------------------------------------

if (-not $IsWindows) {
    Write-Log "This maintenance script is intended for Windows." "WARNING"
    Write-Log "Current environment is not Windows. Exiting."
    exit 0
}

# ------------------------------------------------------------
# 1. Clean Windows temporary files
# ------------------------------------------------------------

Write-Log "Cleaning Windows temporary files..."

$TempPaths = @(
    $env:TEMP,
    "$env:WINDIR\Temp"
)

foreach ($Path in $TempPaths) {

    if (-not (Test-Path $Path)) {
        Write-Log "Path not found: $Path" "WARNING"
        continue
    }

    try {
        $Files = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

        $Count = 0

        foreach ($File in $Files) {
            try {
                Remove-Item -Path $File.FullName -Recurse -Force -ErrorAction Stop
                $Count++
            }
            catch {
                # Some files may be in use.
            }
        }

        Write-Log "Cleaned $Count items from $Path"
    }
    catch {
        Write-Log "Could not fully clean $Path : $($_.Exception.Message)" "WARNING"
    }
}

# ------------------------------------------------------------
# 2. Clear Windows Update download cache
# ------------------------------------------------------------

Write-Log "Checking Windows Update cache..."

$UpdateCache = "$env:WINDIR\SoftwareDistribution\Download"

if (Test-Path $UpdateCache) {

    try {
        $UpdateFiles = Get-ChildItem `
            -Path $UpdateCache `
            -Force `
            -ErrorAction SilentlyContinue

        $Count = 0

        foreach ($File in $UpdateFiles) {
            try {
                Remove-Item `
                    -Path $File.FullName `
                    -Recurse `
                    -Force `
                    -ErrorAction Stop

                $Count++
            }
            catch {
                # Files currently being used are skipped.
            }
        }

        Write-Log "Removed $Count Windows Update cache items."
    }
    catch {
        Write-Log "Unable to completely clean Windows Update cache." "WARNING"
    }
}
else {
    Write-Log "Windows Update cache directory not found." "WARNING"
}

# ------------------------------------------------------------
# 3. Check disk space
# ------------------------------------------------------------

Write-Log "Checking disk space..."

try {

    $Disks = Get-CimInstance Win32_LogicalDisk `
        -Filter "DriveType=3"

    foreach ($Disk in $Disks) {

        $FreeGB = [math]::Round(
            $Disk.FreeSpace / 1GB,
            2
        )

        $TotalGB = [math]::Round(
            $Disk.Size / 1GB,
            2
        )

        $FreePercent = if ($Disk.Size -gt 0) {
            [math]::Round(
                ($Disk.FreeSpace / $Disk.Size) * 100,
                1
            )
        }
        else {
            0
        }

        if ($FreePercent -lt 10) {
            Write-Log "$($Disk.DeviceID) has only $FreeGB GB free ($FreePercent%)." "WARNING"
        }
        else {
            Write-Log "$($Disk.DeviceID): $FreeGB GB free of $TotalGB GB ($FreePercent%)."
        }
    }
}
catch {
    Write-Log "Could not retrieve disk information: $($_.Exception.Message)" "WARNING"
}

# ------------------------------------------------------------
# 4. Check Windows services
# ------------------------------------------------------------

Write-Log "Checking important Windows services..."

$ImportantServices = @(
    "wuauserv",
    "BITS",
    "WinDefend"
)

foreach ($ServiceName in $ImportantServices) {

    try {

        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction Stop

        if ($Service.Status -eq "Running") {
            Write-Log "$ServiceName is running."
        }
        else {
            Write-Log "$ServiceName is $($Service.Status)." "WARNING"
        }
    }
    catch {
        Write-Log "Service $ServiceName was not found or could not be checked." "WARNING"
    }
}

# ------------------------------------------------------------
# 5. Check Windows Defender
# ------------------------------------------------------------

Write-Log "Checking Windows Defender..."

try {

    $Defender = Get-MpComputerStatus -ErrorAction Stop

    if ($Defender.RealTimeProtectionEnabled) {
        Write-Log "Windows Defender real-time protection is enabled."
    }
    else {
        Write-Log "Windows Defender real-time protection is disabled." "WARNING"
    }
}
catch {
    Write-Log "Windows Defender status could not be checked." "WARNING"
}

# ------------------------------------------------------------
# 6. Check system uptime
# ------------------------------------------------------------

Write-Log "Checking system uptime..."

try {

    $OS = Get-CimInstance Win32_OperatingSystem

    $BootTime = $OS.LastBootUpTime
    $Uptime = (Get-Date) - $BootTime

    Write-Log "System uptime: $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes."
}
catch {
    Write-Log "Could not determine system uptime." "WARNING"
}

# ------------------------------------------------------------
# 7. Run Windows maintenance command
# ------------------------------------------------------------

Write-Log "Running Windows component cleanup..."

try {

    $DismProcess = Start-Process `
        -FilePath "DISM.exe" `
        -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup" `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($DismProcess.ExitCode -eq 0) {
        Write-Log "DISM component cleanup completed successfully."
    }
    else {
        Write-Log "DISM exited with code $($DismProcess.ExitCode)." "WARNING"
    }
}
catch {
    Write-Log "Could not run DISM cleanup: $($_.Exception.Message)" "WARNING"
}

# ------------------------------------------------------------
# 8. Final status
# ------------------------------------------------------------

Write-Log "========================================"
Write-Log "Scheduled Maintenance Completed"
Write-Log "Log file: $LogFile"
Write-Log "========================================"