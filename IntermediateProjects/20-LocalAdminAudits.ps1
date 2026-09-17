#requires -Version 7.0

<#
    Project: Local Admin Audit
    Concept: Local Users / Groups
    Language: PowerShell 7+

    Cross-platform:
      Windows / Linux / macOS / GitHub Codespaces

    Windows:
      Audits members of the local Administrators group.

    Linux:
      Audits members of groups commonly associated with
      administrative access: sudo and wheel.

    macOS:
      Audits members of the admin group.

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
    "local-admin-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

New-Item `
    -ItemType Directory `
    -Path $ReportDirectory `
    -Force |
    Out-Null

$Accounts = @()

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "             LOCAL ADMIN AUDIT" -ForegroundColor Cyan
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
# WINDOWS
# ============================================================

if ($IsWindows) {

    Write-Host "Checking local Administrators group..." `
        -ForegroundColor Yellow

    Write-Host ""

    if (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue) {

        try {

            $AdminMembers = Get-LocalGroupMember `
                -Group "Administrators" `
                -ErrorAction Stop

            foreach ($Member in $AdminMembers) {

                $AccountName = $Member.Name

                $AccountType = $Member.ObjectClass

                $Enabled = $null

                # Only attempt local-user lookup for user accounts.
                if ($AccountType -eq "User") {

                    $ShortName = $AccountName

                    if ($ShortName -match "\\") {
                        $ShortName = $ShortName.Split("\")[-1]
                    }

                    $LocalUser = Get-LocalUser `
                        -Name $ShortName `
                        -ErrorAction SilentlyContinue

                    if ($LocalUser) {
                        $Enabled = $LocalUser.Enabled
                    }
                }

                $Accounts += [PSCustomObject]@{
                    Account       = $AccountName
                    Type          = $AccountType
                    Enabled       = $Enabled
                    AdminGroup    = "Administrators"
                    Source        = "Windows Local Groups"
                }
            }
        }
        catch {

            Write-Host "Unable to query local Administrators group." `
                -ForegroundColor Red

            Write-Host $_.Exception.Message `
                -ForegroundColor Red
        }
    }
    else {

        Write-Host "Get-LocalGroupMember is not available." `
            -ForegroundColor Red
    }
}

# ============================================================
# LINUX
# ============================================================

elseif ($IsLinux) {

    Write-Host "Checking Linux administrative groups..." `
        -ForegroundColor Yellow

    Write-Host ""

    # --------------------------------------------------------
    # Groups to check
    # --------------------------------------------------------

    $AdminGroups = @(
        "sudo",
        "wheel"
    )

    foreach ($Group in $AdminGroups) {

        if (-not (Get-Command getent -ErrorAction SilentlyContinue)) {
            continue
        }

        $GroupEntry = & getent group $Group 2>$null

        if ([string]::IsNullOrWhiteSpace($GroupEntry)) {
            continue
        }

        # Format:
        # group:x:GID:user1,user2
        $Parts = $GroupEntry.Split(":", 4)

        if ($Parts.Count -lt 4) {
            continue
        }

        $Members = $Parts[3]

        if ([string]::IsNullOrWhiteSpace($Members)) {
            continue
        }

        foreach ($Member in $Members.Split(",")) {

            if ([string]::IsNullOrWhiteSpace($Member)) {
                continue
            }

            $UserEnabled = $null

            if (Get-Command passwd -ErrorAction SilentlyContinue) {

                $PasswordEntry = & getent passwd $Member 2>$null

                if ($PasswordEntry) {

                    $UserParts = $PasswordEntry.Split(":")

                    if ($UserParts.Count -ge 7) {

                        $Shell = $UserParts[6]

                        $UserEnabled = (
                            $Shell -notmatch `
                                '(nologin|false)$'
                        )
                    }
                }
            }

            $Accounts += [PSCustomObject]@{
                Account       = $Member
                Type          = "User"
                Enabled       = $UserEnabled
                AdminGroup    = $Group
                Source        = "Linux group membership"
            }
        }
    }

    # --------------------------------------------------------
    # Check root
    # --------------------------------------------------------

    $RootEntry = & getent passwd root 2>$null

    if ($RootEntry) {

        $RootParts = $RootEntry.Split(":")

        $RootShell = ""

        if ($RootParts.Count -ge 7) {
            $RootShell = $RootParts[6]
        }

        $Accounts += [PSCustomObject]@{
            Account       = "root"
            Type          = "User"
            Enabled       = (
                $RootShell -notmatch '(nologin|false)$'
            )
            AdminGroup    = "root"
            Source        = "Linux root account"
        }
    }
}

# ============================================================
# MACOS
# ============================================================

elseif ($IsMacOS) {

    Write-Host "Checking macOS admin group..." `
        -ForegroundColor Yellow

    Write-Host ""

    $AdminMembers = @()

    if (Get-Command dscl -ErrorAction SilentlyContinue) {

        $AdminMembers = & dscl . -read /Groups/admin GroupMembership 2>$null
    }

    if ($AdminMembers) {

        $AdminLine = $AdminMembers |
            Where-Object {
                $_ -match "GroupMembership:"
            }

        if ($AdminLine -match "GroupMembership:\s+(.+)$") {

            $Members = $Matches[1].Split(" ")

            foreach ($Member in $Members) {

                if ([string]::IsNullOrWhiteSpace($Member)) {
                    continue
                }

                $Accounts += [PSCustomObject]@{
                    Account       = $Member
                    Type          = "User"
                    Enabled       = $null
                    AdminGroup    = "admin"
                    Source        = "macOS directory services"
                }
            }
        }
    }
}

# ============================================================
# UNKNOWN OS
# ============================================================

else {

    Write-Host "Unsupported operating system." `
        -ForegroundColor Red
}

# ------------------------------------------------------------
# Remove duplicates
# ------------------------------------------------------------

$Accounts = @(
    $Accounts |
        Sort-Object Account, AdminGroup -Unique
)

# ------------------------------------------------------------
# Display accounts
# ------------------------------------------------------------

Write-Host ""
Write-Host "Administrative Accounts" -ForegroundColor Cyan
Write-Host "------------------------"

if ($Accounts.Count -gt 0) {

    $Accounts |
        Format-Table `
            Account,
            Type,
            Enabled,
            AdminGroup `
            -AutoSize
}
else {

    Write-Host "No administrative accounts detected." `
        -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

$UserCount = @(
    $Accounts |
        Where-Object Type -eq "User"
).Count

$EnabledCount = @(
    $Accounts |
        Where-Object Enabled -eq $true
).Count

$DisabledCount = @(
    $Accounts |
        Where-Object Enabled -eq $false
).Count

Write-Host ""
Write-Host "Administrative entries : $($Accounts.Count)"
Write-Host "User entries           : $UserCount"
Write-Host "Enabled users          : $EnabledCount"
Write-Host "Disabled users         : $DisabledCount"

# ------------------------------------------------------------
# Determine overall status
# ------------------------------------------------------------

# This is an inventory audit, not a security verdict.
# We only flag the presence of accounts for review.

$OverallStatus = if ($Accounts.Count -gt 0) {
    "REVIEW"
}
else {
    "NO_ACCOUNTS_FOUND"
}

Write-Host "Audit status            : $OverallStatus"
Write-Host ""

# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

$Report = [PSCustomObject]@{
    ComputerName    = [System.Environment]::MachineName
    OperatingSystem = $OperatingSystem
    AuditTime       = Get-Date

    AuditStatus     = $OverallStatus

    Summary         = [PSCustomObject]@{
        AdministrativeEntries = $Accounts.Count
        UserEntries           = $UserCount
        EnabledUsers          = $EnabledCount
        DisabledUsers         = $DisabledCount
    }

    Accounts        = $Accounts
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
Write-Host "          LOCAL ADMIN AUDIT COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status : $OverallStatus"
Write-Host "Report : $ReportFile"
Write-Host ""