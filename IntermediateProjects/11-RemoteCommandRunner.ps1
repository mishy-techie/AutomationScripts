#requires -Version 7.0

<#
.SYNOPSIS
    Remote Command Runner

.DESCRIPTION
    Executes a PowerShell command remotely on one or more
    Windows computers using PowerShell Remoting.

.NOTES
    Project: Remote Command Runner
    Concept: PowerShell Remoting
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
    New-Item `
        -ItemType Directory `
        -Path $ReportDirectory `
        -Force |
        Out-Null
}

$ReportFile = Join-Path `
    $ReportDirectory `
    "Remote-Command-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').csv"

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

$Computers = @(
    Get-Content $ComputerListFile |
        Where-Object {
            $_.Trim() -and
            -not $_.Trim().StartsWith("#")
        } |
        ForEach-Object {
            $_.Trim()
        }
)

if ($Computers.Count -eq 0) {

    Write-Host "No computers found in computers.txt." `
        -ForegroundColor Yellow

    exit 1
}

# ------------------------------------------------------------
# Ask for command
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "       REMOTE COMMAND RUNNER"
Write-Host "========================================"
Write-Host ""

Write-Host "Computers:"
$Computers | ForEach-Object {
    Write-Host "  - $_"
}

Write-Host ""
Write-Host "Enter a PowerShell command to run remotely."
Write-Host "Example: Get-Service"
Write-Host ""

$Command = Read-Host "Command"

if ([string]::IsNullOrWhiteSpace($Command)) {

    Write-Host ""
    Write-Host "No command entered. Exiting." `
        -ForegroundColor Yellow

    exit 1
}

# ------------------------------------------------------------
# Confirmation
# ------------------------------------------------------------

Write-Host ""
Write-Host "The following command will be executed on:"
$Computers | ForEach-Object {
    Write-Host "  - $_"
}

Write-Host ""
Write-Host "Command: $Command"
Write-Host ""

$Confirmation = Read-Host "Continue? (Y/N)"

if ($Confirmation -notmatch "^(Y|y)$") {

    Write-Host "Operation cancelled."
    exit 0
}

# ------------------------------------------------------------
# Prepare results
# ------------------------------------------------------------

$Results = [System.Collections.Generic.List[object]]::new()

# ------------------------------------------------------------
# Execute command remotely
# ------------------------------------------------------------

foreach ($Computer in $Computers) {

    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host "Computer: $Computer"
    Write-Host "----------------------------------------"

    try {

        # ----------------------------------------------------
        # Check connectivity
        # ----------------------------------------------------

        Write-Host "Testing PowerShell Remoting..."

        Test-WSMan `
            -ComputerName $Computer `
            -ErrorAction Stop |
            Out-Null

        Write-Host "Remoting available." `
            -ForegroundColor Green

        # ----------------------------------------------------
        # Execute remote command
        # ----------------------------------------------------

        Write-Host "Executing command..."

        $StartTime = Get-Date

        $Output = Invoke-Command `
            -ComputerName $Computer `
            -ScriptBlock {
                param($RemoteCommand)

                Invoke-Expression $RemoteCommand

            } `
            -ArgumentList $Command `
            -ErrorAction Stop

        $EndTime = Get-Date

        $Duration = $EndTime - $StartTime

        # ----------------------------------------------------
        # Display output
        # ----------------------------------------------------

        Write-Host ""
        Write-Host "Remote output:" `
            -ForegroundColor Cyan

        if ($null -eq $Output) {

            Write-Host "[No output returned]"

        }
        else {

            $Output |
                Out-String |
                Write-Host
        }

        # ----------------------------------------------------
        # Save result
        # ----------------------------------------------------

        $Results.Add(
            [PSCustomObject]@{
                Computer = $Computer
                Status   = "SUCCESS"
                Command  = $Command
                Output   = ($Output | Out-String).Trim()
                Error    = ""
                Duration = "$([math]::Round($Duration.TotalSeconds, 2)) seconds"
                Time     = $StartTime
            }
        )

        Write-Host "Command completed successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host ""
        Write-Host "Remote command failed." `
            -ForegroundColor Red

        Write-Host "Error: $($_.Exception.Message)"

        $Results.Add(
            [PSCustomObject]@{
                Computer = $Computer
                Status   = "FAILED"
                Command  = $Command
                Output   = ""
                Error    = $_.Exception.Message
                Duration = ""
                Time     = Get-Date
            }
        )
    }
}

# ------------------------------------------------------------
# Export results
# ------------------------------------------------------------

if ($Results.Count -gt 0) {

    $Results |
        Export-Csv `
            -Path $ReportFile `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Host ""
    Write-Host "========================================"
    Write-Host "          EXECUTION COMPLETE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Computers processed : $($Computers.Count)"
    Write-Host "Successful          : $(($Results | Where-Object Status -eq 'SUCCESS').Count)"
    Write-Host "Failed              : $(($Results | Where-Object Status -eq 'FAILED').Count)"
    Write-Host "Report              : $ReportFile"
    Write-Host ""
}