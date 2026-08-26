#requires -Version 5.1

<#
.SYNOPSIS
    Software Inventory Report

.DESCRIPTION
    Collects installed software from the Windows registry
    and generates a formatted inventory report.

.NOTES
    Project: Software Inventory Report
    Concept: Reporting
#>

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "        SOFTWARE INVENTORY REPORT           " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$ComputerName = $env:COMPUTERNAME
$ReportDate   = Get-Date

# Registry locations containing installed applications
$RegistryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$Software = foreach ($Path in $RegistryPaths) {

    Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -and
            $_.SystemComponent -ne 1
        } |
        Select-Object @{
            Name = "ComputerName"
            Expression = { $ComputerName }
        },
        @{
            Name = "SoftwareName"
            Expression = { $_.DisplayName }
        },
        @{
            Name = "Version"
            Expression = { $_.DisplayVersion }
        },
        @{
            Name = "Publisher"
            Expression = { $_.Publisher }
        },
        @{
            Name = "InstallDate"
            Expression = { $_.InstallDate }
        }
}

# Remove duplicate applications
$Software = $Software |
    Sort-Object SoftwareName, Version -Unique

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------

$TotalSoftware = @($Software).Count

$PublisherCount = @(
    $Software |
        Where-Object { $_.Publisher } |
        Select-Object -ExpandProperty Publisher -Unique
).Count

Write-Host "REPORT INFORMATION" -ForegroundColor Yellow
Write-Host "------------------"
Write-Host "Computer : $ComputerName"
Write-Host "Date     : $ReportDate"
Write-Host "Software : $TotalSoftware"
Write-Host "Publishers: $PublisherCount"
Write-Host ""

# ---------------------------------------------------------
# Software Inventory
# ---------------------------------------------------------

Write-Host "INSTALLED SOFTWARE" -ForegroundColor Yellow
Write-Host "------------------"

$Software |
    Sort-Object SoftwareName |
    Format-Table `
        SoftwareName,
        Version,
        Publisher,
        InstallDate `
        -AutoSize

# ---------------------------------------------------------
# Publisher Summary
# ---------------------------------------------------------

Write-Host ""
Write-Host "SOFTWARE BY PUBLISHER" -ForegroundColor Yellow
Write-Host "---------------------"

$Software |
    Where-Object { $_.Publisher } |
    Group-Object Publisher |
    Sort-Object Count -Descending |
    Select-Object @{
        Name = "Publisher"
        Expression = { $_.Name }
    },
    @{
        Name = "SoftwareCount"
        Expression = { $_.Count }
    } |
    Format-Table -AutoSize

# ---------------------------------------------------------
# Export CSV Report
# ---------------------------------------------------------

$ReportFile = Join-Path `
    $PWD `
    "Software-Inventory-$ComputerName-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

$Software |
    Sort-Object SoftwareName |
    Export-Csv `
        -Path $ReportFile `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "REPORT COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "CSV report saved to:"
Write-Host $ReportFile -ForegroundColor Cyan
Write-Host ""