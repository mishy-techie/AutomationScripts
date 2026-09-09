#requires -Version 7.0

<#
.SYNOPSIS
    Multi-PC Inventory Tool

.DESCRIPTION
    Connects to multiple Windows computers remotely and collects
    basic hardware, operating system, memory, CPU, and disk information.

.NOTES
    Project: Multi-PC Inventory Tool
    Concept: Remote execution
    Language: PowerShell
    Platform: Windows
#>

$ErrorActionPreference = "Continue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$ComputerListFile = Join-Path $PSScriptRoot "computers.txt"
$ReportDirectory = Join-Path $PSScriptRoot "reports"

if (-not (Test-Path $ReportDirectory)) {
    New-Item -ItemType Directory -Path $ReportDirectory -Force |
        Out-Null
}

$ReportFile = Join-Path $ReportDirectory `
    "Multi-PC-Inventory-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').csv"

# ------------------------------------------------------------
# Check computer list
# ------------------------------------------------------------

if (-not (Test-Path $ComputerListFile)) {

    Write-Host ""
    Write-Host "Computer list not found:" -ForegroundColor Red
    Write-Host $ComputerListFile
    Write-Host ""

    exit 1
}

$Computers = Get-Content $ComputerListFile |
    Where-Object {
        $_.Trim() -and
        -not $_.Trim().StartsWith("#")
    } |
    ForEach-Object {
        $_.Trim()
    }

if ($Computers.Count -eq 0) {

    Write-Host "No computers were found in computers.txt." `
        -ForegroundColor Yellow

    exit 1
}

# ------------------------------------------------------------
# Display header
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "       MULTI-PC INVENTORY TOOL"
Write-Host "========================================"
Write-Host ""
Write-Host "Computers to scan: $($Computers.Count)"
Write-Host ""

# ------------------------------------------------------------
# Remote inventory script
# ------------------------------------------------------------

$InventoryScript = {

    $ComputerSystem = Get-CimInstance Win32_ComputerSystem
    $OperatingSystem = Get-CimInstance Win32_OperatingSystem
    $Processor = Get-CimInstance Win32_Processor |
        Select-Object -First 1
    $BIOS = Get-CimInstance Win32_BIOS

    $MemoryGB = [math]::Round(
        $ComputerSystem.TotalPhysicalMemory / 1GB,
        2
    )

    $Disks = Get-CimInstance Win32_LogicalDisk `
        -Filter "DriveType=3"

    foreach ($Disk in $Disks) {

        $TotalGB = [math]::Round(
            $Disk.Size / 1GB,
            2
        )

        $FreeGB = [math]::Round(
            $Disk.FreeSpace / 1GB,
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

        [PSCustomObject]@{
            ComputerName      = $ComputerSystem.Name
            Manufacturer      = $ComputerSystem.Manufacturer
            Model             = $ComputerSystem.Model
            OperatingSystem   = $OperatingSystem.Caption
            OSVersion         = $OperatingSystem.Version
            Architecture      = $OperatingSystem.OSArchitecture
            CPU               = $Processor.Name
            Cores             = $Processor.NumberOfCores
            LogicalProcessors = $Processor.NumberOfLogicalProcessors
            MemoryGB          = $MemoryGB
            BIOSVersion       = $BIOS.SMBIOSBIOSVersion
            Drive             = $Disk.DeviceID
            DiskTotalGB       = $TotalGB
            DiskFreeGB        = $FreeGB
            DiskFreePercent   = $FreePercent
            LastBoot          = $OperatingSystem.LastBootUpTime
            Status             = "SUCCESS"
            Error              = ""
        }
    }
}

# ------------------------------------------------------------
# Inventory collection
# ------------------------------------------------------------

$Results = [System.Collections.Generic.List[object]]::new()

foreach ($Computer in $Computers) {

    Write-Host "Scanning: $Computer" -ForegroundColor Cyan

    try {

        # Test network connectivity first
        $Online = Test-Connection `
            -ComputerName $Computer `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        if (-not $Online) {

            Write-Host "  Offline or unreachable." `
                -ForegroundColor Yellow

            $Results.Add(
                [PSCustomObject]@{
                    ComputerName = $Computer
                    Status       = "UNREACHABLE"
                    Error        = "Computer did not respond to ping."
                }
            )

            continue
        }

        Write-Host "  Computer is reachable."

        # ----------------------------------------------------
        # Remote execution
        # ----------------------------------------------------

        $RemoteResults = Invoke-Command `
            -ComputerName $Computer `
            -ScriptBlock $InventoryScript `
            -ErrorAction Stop

        foreach ($Result in $RemoteResults) {

            $Results.Add($Result)

        }

        Write-Host "  Inventory collected successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "  Remote inventory failed." `
            -ForegroundColor Red

        Write-Host "  Error: $($_.Exception.Message)"

        $Results.Add(
            [PSCustomObject]@{
                ComputerName = $Computer
                Status       = "FAILED"
                Error        = $_.Exception.Message
            }
        )
    }

    Write-Host ""
}

# ------------------------------------------------------------
# Export report
# ------------------------------------------------------------

if ($Results.Count -gt 0) {

    $Results |
        Export-Csv `
            -Path $ReportFile `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Host "========================================"
    Write-Host "Inventory Complete"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Computers scanned : $($Computers.Count)"
    Write-Host "Results collected : $($Results.Count)"
    Write-Host "Report            : $ReportFile"
    Write-Host ""
}
else {

    Write-Host "No inventory results were collected." `
        -ForegroundColor Yellow
}