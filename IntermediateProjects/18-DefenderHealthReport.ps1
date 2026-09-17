#requires -Version 7.0

<#
    Project: Defender Health Report
    Concept: Microsoft Defender
    Language: PowerShell 7+

    Windows:
      Uses Get-MpComputerStatus

    Linux/macOS:
      Reports that Microsoft Defender Antivirus is not available
      through the Windows Defender PowerShell cmdlets.

    Checks:
      - Antivirus enabled
      - Real-time protection
      - Behavior monitoring
      - Antivirus signatures
      - Signature age
      - Engine version
      - Antivirus version
      - Quick scan age
      - Full scan age

    Output:
      - Console report
      - JSON report
#>

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$WarningSignatureAgeDays = 3
$CriticalSignatureAgeDays = 7

$WarningScanAgeDays = 7
$CriticalScanAgeDays = 30

$ReportDirectory = Join-Path $PSScriptRoot "reports"

$ReportFile = Join-Path `
    $ReportDirectory `
    "defender-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

New-Item `
    -ItemType Directory `
    -Path $ReportDirectory `
    -Force |
    Out-Null

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "          DEFENDER HEALTH REPORT" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Determine operating system
# ------------------------------------------------------------

$OperatingSystem = if ($IsWindows) {
    "Windows"
}
elseif ($IsLinux) {
    "Linux"
}
elseif ($IsMacOS) {
    "macOS"
}
else {
    "Unknown"
}

Write-Host "Operating system: $OperatingSystem" -ForegroundColor Green
Write-Host ""

# ============================================================
# NON-WINDOWS
# ============================================================

if (-not $IsWindows) {

    Write-Host "Microsoft Defender Antivirus Windows cmdlets are not available." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "This script uses Get-MpComputerStatus on Windows."
    Write-Host "Linux/macOS security products require different APIs."
    Write-Host ""

    $Report = [PSCustomObject]@{
        ComputerName       = [System.Environment]::MachineName
        OperatingSystem    = $OperatingSystem
        AuditTime          = Get-Date
        DefenderAvailable  = $false
        OverallStatus      = "NOT_APPLICABLE"
        Message            = "Microsoft Defender Antivirus PowerShell cmdlets are Windows-specific."
    }

    $Report |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -Path $ReportFile `
            -Encoding UTF8

    Write-Host "Status : NOT_APPLICABLE"
    Write-Host "Report : $ReportFile"
    Write-Host ""

    exit 0
}

# ============================================================
# WINDOWS
# ============================================================

Write-Host "Checking Microsoft Defender..." -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------------------------
# Check cmdlet
# ------------------------------------------------------------

if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {

    Write-Host "Get-MpComputerStatus is not available." -ForegroundColor Red
    Write-Host ""

    $Report = [PSCustomObject]@{
        ComputerName      = [System.Environment]::MachineName
        OperatingSystem   = "Windows"
        AuditTime         = Get-Date
        DefenderAvailable = $false
        OverallStatus     = "ERROR"
        Message           = "Get-MpComputerStatus is not available."
    }

    $Report |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -Path $ReportFile `
            -Encoding UTF8

    Write-Host "Report : $ReportFile"

    exit 1
}

# ------------------------------------------------------------
# Get Defender status
# ------------------------------------------------------------

try {

    $Defender = Get-MpComputerStatus -ErrorAction Stop

}
catch {

    Write-Host "Unable to query Microsoft Defender." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    $Report = [PSCustomObject]@{
        ComputerName      = [System.Environment]::MachineName
        OperatingSystem   = "Windows"
        AuditTime         = Get-Date
        DefenderAvailable = $true
        OverallStatus     = "ERROR"
        Message           = $_.Exception.Message
    }

    $Report |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -Path $ReportFile `
            -Encoding UTF8

    exit 1
}

# ------------------------------------------------------------
# Signature age
# ------------------------------------------------------------

$SignatureAgeDays = $null

if ($Defender.AntivirusSignatureLastUpdated) {

    $SignatureAgeDays = [math]::Floor(
        ((Get-Date) - $Defender.AntivirusSignatureLastUpdated).TotalDays
    )
}

# ------------------------------------------------------------
# Quick scan age
# ------------------------------------------------------------

$QuickScanAgeDays = $null

if ($Defender.QuickScanStartTime) {

    $QuickScanAgeDays = [math]::Floor(
        ((Get-Date) - $Defender.QuickScanStartTime).TotalDays
    )
}

# ------------------------------------------------------------
# Full scan age
# ------------------------------------------------------------

$FullScanAgeDays = $null

if ($Defender.FullScanStartTime) {

    $FullScanAgeDays = [math]::Floor(
        ((Get-Date) - $Defender.FullScanStartTime).TotalDays
    )
}

# ------------------------------------------------------------
# Individual health checks
# ------------------------------------------------------------

$Checks = @()

# Antivirus enabled

$Checks += [PSCustomObject]@{
    Check  = "Antivirus Enabled"
    Value  = $Defender.AntivirusEnabled
    Status = if ($Defender.AntivirusEnabled) {
        "HEALTHY"
    }
    else {
        "CRITICAL"
    }
}

# Real-time protection

$Checks += [PSCustomObject]@{
    Check  = "Real-Time Protection"
    Value  = $Defender.RealTimeProtectionEnabled
    Status = if ($Defender.RealTimeProtectionEnabled) {
        "HEALTHY"
    }
    else {
        "CRITICAL"
    }
}

# Behavior monitoring

$Checks += [PSCustomObject]@{
    Check  = "Behavior Monitoring"
    Value  = $Defender.BehaviorMonitorEnabled
    Status = if ($Defender.BehaviorMonitorEnabled) {
        "HEALTHY"
    }
    else {
        "WARNING"
    }
}

# Signature age

$SignatureStatus = "HEALTHY"

if ($null -eq $SignatureAgeDays) {
    $SignatureStatus = "WARNING"
}
elseif ($SignatureAgeDays -gt $CriticalSignatureAgeDays) {
    $SignatureStatus = "CRITICAL"
}
elseif ($SignatureAgeDays -gt $WarningSignatureAgeDays) {
    $SignatureStatus = "WARNING"
}

$Checks += [PSCustomObject]@{
    Check  = "Signature Age"
    Value  = if ($null -ne $SignatureAgeDays) {
        "$SignatureAgeDays days"
    }
    else {
        "Unknown"
    }
    Status = $SignatureStatus
}

# Quick scan

$QuickScanStatus = "HEALTHY"

if ($null -eq $QuickScanAgeDays) {
    $QuickScanStatus = "WARNING"
}
elseif ($QuickScanAgeDays -gt $CriticalScanAgeDays) {
    $QuickScanStatus = "CRITICAL"
}
elseif ($QuickScanAgeDays -gt $WarningScanAgeDays) {
    $QuickScanStatus = "WARNING"
}

$Checks += [PSCustomObject]@{
    Check  = "Last Quick Scan"
    Value  = if ($null -ne $QuickScanAgeDays) {
        "$QuickScanAgeDays days ago"
    }
    else {
        "Never / Unknown"
    }
    Status = $QuickScanStatus
}

# Full scan

$FullScanStatus = "HEALTHY"

if ($null -eq $FullScanAgeDays) {
    $FullScanStatus = "WARNING"
}
elseif ($FullScanAgeDays -gt $CriticalScanAgeDays) {
    $FullScanStatus = "CRITICAL"
}
elseif ($FullScanAgeDays -gt $WarningScanAgeDays) {
    $FullScanStatus = "WARNING"
}

$Checks += [PSCustomObject]@{
    Check  = "Last Full Scan"
    Value  = if ($null -ne $FullScanAgeDays) {
        "$FullScanAgeDays days ago"
    }
    else {
        "Never / Unknown"
    }
    Status = $FullScanStatus
}

# ------------------------------------------------------------
# Display checks
# ------------------------------------------------------------

$Checks |
    Format-Table `
        Check,
        Value,
        Status `
        -AutoSize

Write-Host ""

# ------------------------------------------------------------
# Overall status
# ------------------------------------------------------------

$OverallStatus = "HEALTHY"

if ($Checks.Status -contains "CRITICAL") {
    $OverallStatus = "CRITICAL"
}
elseif ($Checks.Status -contains "WARNING") {
    $OverallStatus = "WARNING"
}

switch ($OverallStatus) {

    "HEALTHY" {
        Write-Host "Overall Status: HEALTHY" -ForegroundColor Green
    }

    "WARNING" {
        Write-Host "Overall Status: WARNING" -ForegroundColor Yellow
    }

    "CRITICAL" {
        Write-Host "Overall Status: CRITICAL" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Defender information
# ------------------------------------------------------------

Write-Host ""
Write-Host "Defender Information" -ForegroundColor Cyan
Write-Host "--------------------"
Write-Host "Antivirus Version : $($Defender.AntivirusVersion)"
Write-Host "Engine Version    : $($Defender.AMEngineVersion)"
Write-Host "Signature Version : $($Defender.AntivirusSignatureVersion)"
Write-Host "Signature Updated : $($Defender.AntivirusSignatureLastUpdated)"
Write-Host ""

# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

$Report = [PSCustomObject]@{
    ComputerName      = [System.Environment]::MachineName
    OperatingSystem   = "Windows"
    AuditTime         = Get-Date

    DefenderAvailable = $true
    OverallStatus     = $OverallStatus

    AntivirusEnabled  = $Defender.AntivirusEnabled
    RealTimeProtection = $Defender.RealTimeProtectionEnabled
    BehaviorMonitoring = $Defender.BehaviorMonitorEnabled

    AntivirusVersion  = $Defender.AntivirusVersion
    EngineVersion     = $Defender.AMEngineVersion
    SignatureVersion  = $Defender.AntivirusSignatureVersion
    SignatureUpdated  = $Defender.AntivirusSignatureLastUpdated
    SignatureAgeDays  = $SignatureAgeDays

    QuickScanStart    = $Defender.QuickScanStartTime
    QuickScanAgeDays  = $QuickScanAgeDays

    FullScanStart     = $Defender.FullScanStartTime
    FullScanAgeDays   = $FullScanAgeDays

    Checks            = $Checks
}

# ------------------------------------------------------------
# Export JSON
# ------------------------------------------------------------

$Report |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -Path $ReportFile `
        -Encoding UTF8

# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "        DEFENDER REPORT COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status : $OverallStatus"
Write-Host "Report : $ReportFile"
Write-Host ""