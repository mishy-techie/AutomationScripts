#requires -Version 7.0

<#
    Project: Firewall Status Checker
    Concept: Windows Firewall
    Language: PowerShell 7+

    Cross-platform behavior:

      Windows:
        Uses Get-NetFirewallProfile

      Linux:
        Checks ufw, firewall-cmd, nft, and iptables

      macOS:
        Checks the macOS Application Firewall using
        /usr/libexec/ApplicationFirewall/socketfilterfw

      GitHub Codespaces:
        Uses the Linux detection logic.

    Output:
      - Console report
      - JSON report
#>

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$ReportDirectory = Join-Path $PSScriptRoot "reports"

$ReportFile = Join-Path `
    $ReportDirectory `
    "firewall-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

New-Item `
    -ItemType Directory `
    -Path $ReportDirectory `
    -Force |
    Out-Null

$Profiles = @()

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "         FIREWALL STATUS CHECKER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# WINDOWS
# ============================================================

if ($IsWindows) {

    Write-Host "Operating system: Windows" -ForegroundColor Green
    Write-Host "Checking Windows Firewall profiles..." -ForegroundColor Yellow
    Write-Host ""

    if (-not (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue)) {

        Write-Host "Get-NetFirewallProfile is not available." -ForegroundColor Red

        $Report = [PSCustomObject]@{
            ComputerName    = [System.Environment]::MachineName
            OperatingSystem = "Windows"
            AuditTime       = Get-Date
            FirewallType    = "Windows Firewall"
            OverallStatus   = "ERROR"
            Profiles        = @()
            Message         = "Get-NetFirewallProfile is not available."
        }

        $Report |
            ConvertTo-Json -Depth 10 |
            Set-Content -Path $ReportFile -Encoding UTF8

        exit 1
    }

    try {

        $FirewallProfiles = Get-NetFirewallProfile -ErrorAction Stop

        foreach ($Profile in $FirewallProfiles) {

            $Status = if ($Profile.Enabled) {
                "HEALTHY"
            }
            else {
                "WARNING"
            }

            $Profiles += [PSCustomObject]@{
                Name             = $Profile.Name
                Enabled          = $Profile.Enabled
                DefaultInbound   = $Profile.DefaultInboundAction
                DefaultOutbound  = $Profile.DefaultOutboundAction
                AllowLocalRules  = $Profile.AllowLocalRules
                AllowLocalIPsecRules = $Profile.AllowLocalIPsecRules
                LogAllowed       = $Profile.LogAllowed
                LogBlocked       = $Profile.LogBlocked
                Status           = $Status
            }
        }
    }
    catch {

        Write-Host "Unable to query Windows Firewall." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# ============================================================
# LINUX
# ============================================================

elseif ($IsLinux) {

    Write-Host "Operating system: Linux" -ForegroundColor Green
    Write-Host "Checking available firewall service..." -ForegroundColor Yellow
    Write-Host ""

    $FirewallFound = $false

    # --------------------------------------------------------
    # UFW
    # --------------------------------------------------------

    if (Get-Command ufw -ErrorAction SilentlyContinue) {

        $FirewallFound = $true

        $UfwStatus = & ufw status 2>$null

        $UfwActive = $UfwStatus -match "Status:\s+active"

        $Profiles += [PSCustomObject]@{
            Name            = "UFW"
            Enabled         = $UfwActive
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = ($UfwStatus -join " ")
            Status          = if ($UfwActive) {
                "HEALTHY"
            }
            else {
                "WARNING"
            }
        }
    }

    # --------------------------------------------------------
    # firewalld
    # --------------------------------------------------------

    if (Get-Command firewall-cmd -ErrorAction SilentlyContinue) {

        $FirewallFound = $true

        $FirewalldState = & firewall-cmd --state 2>$null

        $FirewalldActive = $FirewalldState -match "running"

        $Profiles += [PSCustomObject]@{
            Name            = "firewalld"
            Enabled         = $FirewalldActive
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = ($FirewalldState -join " ")
            Status          = if ($FirewalldActive) {
                "HEALTHY"
            }
            else {
                "WARNING"
            }
        }
    }

    # --------------------------------------------------------
    # nftables
    # --------------------------------------------------------

    if (Get-Command nft -ErrorAction SilentlyContinue) {

        $FirewallFound = $true

        $NftRules = & nft list ruleset 2>$null

        $NftActive = $NftRules.Count -gt 0

        $Profiles += [PSCustomObject]@{
            Name            = "nftables"
            Enabled         = $NftActive
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = "Rules detected: $($NftRules.Count)"
            Status          = if ($NftActive) {
                "HEALTHY"
            }
            else {
                "WARNING"
            }
        }
    }

    # --------------------------------------------------------
    # iptables
    # --------------------------------------------------------

    if ((Get-Command iptables -ErrorAction SilentlyContinue) -and
        -not $FirewallFound) {

        $FirewallFound = $true

        $IptablesRules = & iptables -L -n 2>$null

        $IptablesActive = $IptablesRules.Count -gt 0

        $Profiles += [PSCustomObject]@{
            Name            = "iptables"
            Enabled         = $IptablesActive
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = "Rules detected: $($IptablesRules.Count)"
            Status          = if ($IptablesActive) {
                "HEALTHY"
            }
            else {
                "WARNING"
            }
        }
    }

    if (-not $FirewallFound) {

        Write-Host "No supported firewall utility was detected." -ForegroundColor Yellow

        $Profiles += [PSCustomObject]@{
            Name            = "Firewall"
            Enabled         = $false
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = "No supported firewall utility detected."
            Status          = "WARNING"
        }
    }
}

# ============================================================
# MACOS
# ============================================================

elseif ($IsMacOS) {

    Write-Host "Operating system: macOS" -ForegroundColor Green
    Write-Host "Checking Application Firewall..." -ForegroundColor Yellow
    Write-Host ""

    $FirewallCommand = "/usr/libexec/ApplicationFirewall/socketfilterfw"

    if (Test-Path $FirewallCommand) {

        $FirewallState = & $FirewallCommand --getglobalstate 2>$null

        $FirewallEnabled = $FirewallState -match "enabled"

        $Profiles += [PSCustomObject]@{
            Name            = "macOS Application Firewall"
            Enabled         = $FirewallEnabled
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = ($FirewallState -join " ")
            Status          = if ($FirewallEnabled) {
                "HEALTHY"
            }
            else {
                "WARNING"
            }
        }
    }
    else {

        $Profiles += [PSCustomObject]@{
            Name            = "macOS Application Firewall"
            Enabled         = $false
            DefaultInbound  = ""
            DefaultOutbound = ""
            Details         = "Firewall utility was not found."
            Status          = "ERROR"
        }
    }
}

# ============================================================
# UNKNOWN OS
# ============================================================

else {

    Write-Host "Unsupported operating system." -ForegroundColor Red

    $Profiles += [PSCustomObject]@{
        Name            = "Unknown"
        Enabled         = $false
        Status          = "ERROR"
        Details         = "Unsupported operating system."
    }
}

# ------------------------------------------------------------
# Determine OS name
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

# ------------------------------------------------------------
# Determine overall status
# ------------------------------------------------------------

$OverallStatus = "HEALTHY"

if ($Profiles.Count -eq 0) {
    $OverallStatus = "ERROR"
}
elseif ($Profiles.Status -contains "ERROR") {
    $OverallStatus = "ERROR"
}
elseif ($Profiles.Status -contains "WARNING") {
    $OverallStatus = "WARNING"
}

# ------------------------------------------------------------
# Display results
# ------------------------------------------------------------

Write-Host ""

$Profiles |
    Select-Object Name, Enabled, DefaultInbound, DefaultOutbound, Status |
    Format-Table -AutoSize

Write-Host ""

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

$EnabledCount = @(
    $Profiles |
        Where-Object Enabled -eq $true
).Count

$WarningCount = @(
    $Profiles |
        Where-Object Status -eq "WARNING"
).Count

$ErrorCount = @(
    $Profiles |
        Where-Object Status -eq "ERROR"
).Count

Write-Host "Firewall entries : $($Profiles.Count)"
Write-Host "Enabled          : $EnabledCount"
Write-Host "Warnings         : $WarningCount"
Write-Host "Errors           : $ErrorCount"
Write-Host "Overall status   : $OverallStatus"
Write-Host ""

# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

$Report = [PSCustomObject]@{
    ComputerName    = [System.Environment]::MachineName
    OperatingSystem = $OperatingSystem
    AuditTime       = Get-Date
    FirewallType    = if ($IsWindows) {
        "Windows Firewall"
    }
    elseif ($IsLinux) {
        "Linux Firewall"
    }
    elseif ($IsMacOS) {
        "macOS Application Firewall"
    }
    else {
        "Unknown"
    }

    OverallStatus   = $OverallStatus
    EntryCount      = $Profiles.Count
    EnabledCount    = $EnabledCount
    WarningCount    = $WarningCount
    ErrorCount      = $ErrorCount
    Profiles        = $Profiles
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
# Final message
# ------------------------------------------------------------

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       FIREWALL CHECK COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status : $OverallStatus"
Write-Host "Report : $ReportFile"
Write-Host ""