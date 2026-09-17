#requires -Version 7.0

<#
    Project: BitLocker Status Report
    Concept: BitLocker Cmdlets
    Language: PowerShell 7+

    Windows:
      Uses Get-BitLockerVolume

    Linux/macOS:
      BitLocker is not natively supported, so the script reports
      that the BitLocker check is not applicable.

    Output:
      - Console report
      - JSON report
#>

$ErrorActionPreference = "Stop"

$ReportDirectory = Join-Path $PSScriptRoot "reports"
$ReportFile = Join-Path $ReportDirectory "bitlocker-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        BITLOCKER STATUS REPORT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Operating system detection
# ------------------------------------------------------------

if (-not $IsWindows) {

    Write-Host "Operating system: Non-Windows" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "BitLocker is a Windows-specific disk encryption technology."
    Write-Host "This report cannot query BitLocker volumes on this system."
    Write-Host ""

    $Report = [PSCustomObject]@{
        ComputerName   = [System.Environment]::MachineName
        OperatingSystem = if ($IsLinux) {
            "Linux"
        }
        elseif ($IsMacOS) {
            "macOS"
        }
        else {
            "Unknown"
        }
        AuditTime      = Get-Date
        BitLockerAvailable = $false
        OverallStatus  = "NOT_APPLICABLE"
        Volumes        = @()
        Message        = "BitLocker status can only be queried on Windows."
    }

    $Report |
        ConvertTo-Json -Depth 10 |
        Set-Content -Path $ReportFile -Encoding UTF8

    Write-Host "Report: $ReportFile" -ForegroundColor Cyan
    Write-Host ""

    exit 0
}

# ------------------------------------------------------------
# Windows
# ------------------------------------------------------------

Write-Host "Operating system: Windows" -ForegroundColor Green
Write-Host "Checking BitLocker volumes..." -ForegroundColor Yellow
Write-Host ""

# Check whether the cmdlet exists
if (-not (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)) {

    Write-Host "Get-BitLockerVolume is not available." -ForegroundColor Red
    Write-Host ""
    Write-Host "This normally requires the BitLocker PowerShell module"
    Write-Host "and appropriate Windows components/permissions."
    Write-Host ""

    $Report = [PSCustomObject]@{
        ComputerName       = [System.Environment]::MachineName
        OperatingSystem    = "Windows"
        AuditTime          = Get-Date
        BitLockerAvailable = $false
        OverallStatus      = "ERROR"
        Volumes            = @()
        Message            = "Get-BitLockerVolume is not available."
    }

    $Report |
        ConvertTo-Json -Depth 10 |
        Set-Content -Path $ReportFile -Encoding UTF8

    Write-Host "Report: $ReportFile" -ForegroundColor Cyan

    exit 1
}

# ------------------------------------------------------------
# Get BitLocker volumes
# ------------------------------------------------------------

try {

    $BitLockerVolumes = Get-BitLockerVolume -ErrorAction Stop

}
catch {

    Write-Host "Unable to query BitLocker volumes." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    $Report = [PSCustomObject]@{
        ComputerName       = [System.Environment]::MachineName
        OperatingSystem    = "Windows"
        AuditTime          = Get-Date
        BitLockerAvailable = $true
        OverallStatus      = "ERROR"
        Volumes            = @()
        Message            = $_.Exception.Message
    }

    $Report |
        ConvertTo-Json -Depth 10 |
        Set-Content -Path $ReportFile -Encoding UTF8

    exit 1
}

# ------------------------------------------------------------
# Process volumes
# ------------------------------------------------------------

$Volumes = @()

foreach ($Volume in $BitLockerVolumes) {

    $EncryptionPercentage = $Volume.EncryptionPercentage

    # Normalize encryption percentage
    if ($null -eq $EncryptionPercentage) {
        $EncryptionPercentage = 0
    }

    $VolumeStatus = "HEALTHY"

    # Determine volume health
    if ($Volume.VolumeStatus -ne "FullyEncrypted") {
        $VolumeStatus = "WARNING"
    }

    if ($Volume.ProtectionStatus -ne "On") {
        $VolumeStatus = "WARNING"
    }

    if ($EncryptionPercentage -lt 100) {
        $VolumeStatus = "WARNING"
    }

    $Volumes += [PSCustomObject]@{
        MountPoint           = $Volume.MountPoint
        VolumeStatus         = $Volume.VolumeStatus
        EncryptionPercentage = $EncryptionPercentage
        EncryptionMethod     = $Volume.EncryptionMethod
        ProtectionStatus     = $Volume.ProtectionStatus
        LockStatus            = $Volume.LockStatus
        AutoUnlockEnabled    = $Volume.AutoUnlockEnabled
        KeyProtectorCount    = @($Volume.KeyProtector).Count
        Status               = $VolumeStatus
    }
}

# ------------------------------------------------------------
# Determine overall status
# ------------------------------------------------------------

$OverallStatus = "HEALTHY"

if ($Volumes.Count -eq 0) {
    $OverallStatus = "WARNING"
}
elseif ($Volumes.Status -contains "WARNING") {
    $OverallStatus = "WARNING"
}

# ------------------------------------------------------------
# Display results
# ------------------------------------------------------------

$Volumes |
    Format-Table `
        MountPoint,
        VolumeStatus,
        EncryptionPercentage,
        ProtectionStatus,
        LockStatus,
        Status `
        -AutoSize

Write-Host ""

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

$EncryptedCount = @(
    $Volumes |
        Where-Object {
            $_.VolumeStatus -eq "FullyEncrypted" -and
            $_.ProtectionStatus -eq "On"
        }
).Count

$WarningCount = @(
    $Volumes |
        Where-Object {
            $_.Status -eq "WARNING"
        }
).Count

Write-Host "Volume count    : $($Volumes.Count)"
Write-Host "Fully protected : $EncryptedCount"
Write-Host "Warnings        : $WarningCount"
Write-Host "Overall status  : $OverallStatus"
Write-Host ""

# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

$Report = [PSCustomObject]@{
    ComputerName       = [System.Environment]::MachineName
    OperatingSystem    = "Windows"
    AuditTime          = Get-Date
    BitLockerAvailable = $true
    OverallStatus      = $OverallStatus
    VolumeCount        = $Volumes.Count
    ProtectedVolumes   = $EncryptedCount
    WarningVolumes     = $WarningCount
    Volumes            = $Volumes
}

# ------------------------------------------------------------
# Export JSON
# ------------------------------------------------------------

$Report |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path $ReportFile -Encoding UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       BITLOCKER AUDIT COMPLETE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Report: $ReportFile"
Write-Host ""