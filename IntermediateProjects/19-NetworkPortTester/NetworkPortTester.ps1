#requires -Version 7.0

<#
    Project: Network Port Tester
    Concept: TCP Connections
    Language: PowerShell 7+

    Cross-platform:
      Windows / Linux / macOS / GitHub Codespaces

    Usage:
      pwsh ./19-NetworkPortTester.ps1

    Examples:
      localhost
      example.com
      192.168.1.10

    You can test:
      - A single port
      - Multiple ports
      - A port range

    Examples:
      80
      80,443,22
      20-25
#>

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$TimeoutMilliseconds = 2000

$ReportDirectory = Join-Path $PSScriptRoot "reports"

$ReportFile = Join-Path `
    $ReportDirectory `
    "port-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

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
Write-Host "           NETWORK PORT TESTER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Get target
# ------------------------------------------------------------

$Target = Read-Host "Enter hostname or IP address"

if ([string]::IsNullOrWhiteSpace($Target)) {

    Write-Host "No target specified." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Get ports
# ------------------------------------------------------------

$PortInput = Read-Host "Enter port(s), e.g. 80 or 80,443 or 20-25"

if ([string]::IsNullOrWhiteSpace($PortInput)) {

    Write-Host "No ports specified." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Parse ports
# ------------------------------------------------------------

$Ports = [System.Collections.Generic.List[int]]::new()

foreach ($Part in $PortInput.Split(",")) {

    $Part = $Part.Trim()

    if ($Part -match '^(\d+)-(\d+)$') {

        $StartPort = [int]$Matches[1]
        $EndPort = [int]$Matches[2]

        if ($StartPort -gt $EndPort) {
            $Temp = $StartPort
            $StartPort = $EndPort
            $EndPort = $Temp
        }

        for ($Port = $StartPort; $Port -le $EndPort; $Port++) {

            if ($Port -ge 1 -and $Port -le 65535) {
                $Ports.Add($Port)
            }
        }
    }
    elseif ($Part -match '^\d+$') {

        $Port = [int]$Part

        if ($Port -ge 1 -and $Port -le 65535) {
            $Ports.Add($Port)
        }
    }
}

$Ports = @($Ports | Sort-Object -Unique)

if ($Ports.Count -eq 0) {

    Write-Host "No valid ports were supplied." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Test TCP connection
# ------------------------------------------------------------

function Test-TcpPort {
    param(
        [Parameter(Mandatory)]
        [string]$Computer,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [int]$Timeout
    )

    $Client = [System.Net.Sockets.TcpClient]::new()

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        $ConnectTask = $Client.ConnectAsync($Computer, $Port)

        $Connected = $ConnectTask.Wait($Timeout)

        $Stopwatch.Stop()

        if ($Connected -and $Client.Connected) {

            return [PSCustomObject]@{
                Target       = $Computer
                Port         = $Port
                Status       = "OPEN"
                ResponseTime = $Stopwatch.ElapsedMilliseconds
                Error        = ""
            }
        }

        return [PSCustomObject]@{
            Target       = $Computer
            Port         = $Port
            Status       = "CLOSED/FILTERED"
            ResponseTime = $Stopwatch.ElapsedMilliseconds
            Error        = ""
        }
    }
    catch {

        $Stopwatch.Stop()

        return [PSCustomObject]@{
            Target       = $Computer
            Port         = $Port
            Status       = "UNREACHABLE/ERROR"
            ResponseTime = $Stopwatch.ElapsedMilliseconds
            Error        = $_.Exception.Message
        }
    }
    finally {

        $Client.Dispose()
    }
}

# ------------------------------------------------------------
# Run tests
# ------------------------------------------------------------

Write-Host ""
Write-Host "Target : $Target"
Write-Host "Ports  : $($Ports -join ', ')"
Write-Host "Timeout: $TimeoutMilliseconds ms"
Write-Host ""

$Results = @()

foreach ($Port in $Ports) {

    Write-Host "Testing TCP $Target`:$Port ..." -NoNewline

    $Result = Test-TcpPort `
        -Computer $Target `
        -Port $Port `
        -Timeout $TimeoutMilliseconds

    $Results += $Result

    if ($Result.Status -eq "OPEN") {

        Write-Host " OPEN ($($Result.ResponseTime) ms)" `
            -ForegroundColor Green
    }
    elseif ($Result.Status -eq "CLOSED/FILTERED") {

        Write-Host " CLOSED/FILTERED" `
            -ForegroundColor Yellow
    }
    else {

        Write-Host " ERROR" `
            -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Display table
# ------------------------------------------------------------

Write-Host ""
Write-Host "Results" -ForegroundColor Cyan
Write-Host "-------"

$Results |
    Select-Object Target, Port, Status, ResponseTime |
    Format-Table -AutoSize

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

$OpenCount = @(
    $Results |
        Where-Object Status -eq "OPEN"
).Count

$ClosedCount = @(
    $Results |
        Where-Object Status -eq "CLOSED/FILTERED"
).Count

$ErrorCount = @(
    $Results |
        Where-Object Status -eq "UNREACHABLE/ERROR"
).Count

Write-Host ""
Write-Host "Open ports        : $OpenCount"
Write-Host "Closed/filtered   : $ClosedCount"
Write-Host "Errors            : $ErrorCount"

# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

$Report = [PSCustomObject]@{
    ComputerName = [System.Environment]::MachineName
    AuditTime    = Get-Date
    Target       = $Target
    Ports        = $Ports
    TimeoutMs    = $TimeoutMilliseconds

    Summary = [PSCustomObject]@{
        Open          = $OpenCount
        ClosedFiltered = $ClosedCount
        Errors        = $ErrorCount
    }

    Results = $Results
}

# ------------------------------------------------------------
# Export JSON
# ------------------------------------------------------------

$Report |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -Path $ReportFile `
        -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "          PORT TEST COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Report: $ReportFile"
Write-Host ""