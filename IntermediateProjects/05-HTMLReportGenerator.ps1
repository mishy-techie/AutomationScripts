#requires -Version 7.0

<#
.SYNOPSIS
    Cross-Platform HTML Health Report Generator

.DESCRIPTION
    Collects basic system-health information and generates
    a formatted HTML report.

    Designed to work in:
      - GitHub Codespaces / Linux
      - Windows
      - macOS

.NOTES
    Project : HTML Report Generator
    Concept : HTML Generation
    PowerShell: 7+
#>

# =========================================================
# CONFIGURATION
# =========================================================

$ReportDirectory = Join-Path $HOME "PC-Health-Reports"

# Create report directory
if (-not (Test-Path -Path $ReportDirectory)) {

    New-Item `
        -Path $ReportDirectory `
        -ItemType Directory `
        -Force |
        Out-Null
}

$ComputerName = [System.Environment]::MachineName
$ReportDate   = Get-Date

# =========================================================
# RESULTS COLLECTION
# =========================================================

$Results = [System.Collections.Generic.List[object]]::new()

function Add-HealthResult {

    param (
        [Parameter(Mandatory)]
        [string]$Check,

        [Parameter(Mandatory)]
        [ValidateSet("OK", "WARNING", "CRITICAL", "INFO")]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Details
    )

    $Results.Add(
        [PSCustomObject]@{
            Check   = $Check
            Status  = $Status
            Details = $Details
        }
    )
}

# =========================================================
# HTML ENCODING
# =========================================================

function ConvertTo-HtmlSafe {

    param (
        [AllowNull()]
        [string]$Text
    )

    if ($null -eq $Text) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode($Text)
}

# =========================================================
# OPERATING SYSTEM
# =========================================================

if ($IsWindows) {

    try {

        $OS = Get-CimInstance `
            -ClassName Win32_OperatingSystem `
            -ErrorAction Stop

        $OSName = $OS.Caption
        $OSVersion = $OS.Version

        Add-HealthResult `
            -Check "Operating System" `
            -Status "OK" `
            -Details "$OSName (Version $OSVersion)"
    }
    catch {

        Add-HealthResult `
            -Check "Operating System" `
            -Status "INFO" `
            -Details "Windows detected, but OS information was unavailable."
    }
}
elseif ($IsLinux) {

    try {

        $OSName = ""

        if (Test-Path "/etc/os-release") {

            $OSInfo = Get-Content "/etc/os-release"

            $PrettyName = $OSInfo |
                Where-Object { $_ -match '^PRETTY_NAME=' }

            if ($PrettyName) {

                $OSName = $PrettyName -replace '^PRETTY_NAME=', ''
                $OSName = $OSName.Trim('"')
            }
        }

        if (-not $OSName) {

            $OSName =
                [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        }

        Add-HealthResult `
            -Check "Operating System" `
            -Status "OK" `
            -Details $OSName
    }
    catch {

        Add-HealthResult `
            -Check "Operating System" `
            -Status "INFO" `
            -Details "Linux detected."
    }
}
elseif ($IsMacOS) {

    Add-HealthResult `
        -Check "Operating System" `
        -Status "OK" `
        -Details "macOS"
}
else {

    Add-HealthResult `
        -Check "Operating System" `
        -Status "INFO" `
        -Details "Unknown operating system."
}

# =========================================================
# POWERSHELL VERSION
# =========================================================

$PowerShellVersion = $PSVersionTable.PSVersion.ToString()

Add-HealthResult `
    -Check "PowerShell Version" `
    -Status "OK" `
    -Details $PowerShellVersion

# =========================================================
# CPU INFORMATION
# =========================================================

if ($IsLinux) {

    try {

        $CPUInfo = Get-Content "/proc/cpuinfo"

        $CPUModel = $CPUInfo |
            Where-Object { $_ -match '^model name' } |
            Select-Object -First 1

        if ($CPUModel) {

            $CPUModel = $CPUModel -replace '^.*:\s*', ''

            $CPUCount = (
                $CPUInfo |
                Where-Object { $_ -match '^processor\s*:' }
            ).Count

            Add-HealthResult `
                -Check "CPU" `
                -Status "OK" `
                -Details "$CPUModel ($CPUCount logical processors)"
        }
        else {

            Add-HealthResult `
                -Check "CPU" `
                -Status "INFO" `
                -Details "CPU model unavailable."
        }
    }
    catch {

        Add-HealthResult `
            -Check "CPU" `
            -Status "INFO" `
            -Details "CPU information unavailable."
    }
}
elseif ($IsWindows) {

    try {

        $CPU = Get-CimInstance `
            -ClassName Win32_Processor `
            -ErrorAction Stop

        $CPUDetails = $CPU |
            ForEach-Object {
                "$($_.Name) - $($_.NumberOfLogicalProcessors) logical processors"
            }

        Add-HealthResult `
            -Check "CPU" `
            -Status "OK" `
            -Details ($CPUDetails -join "; ")
    }
    catch {

        Add-HealthResult `
            -Check "CPU" `
            -Status "INFO" `
            -Details "CPU information unavailable."
    }
}
elseif ($IsMacOS) {

    try {

        $CPUModel = & sysctl -n machdep.cpu.brand_string 2>$null
        $CPUCount = & sysctl -n hw.logicalcpu 2>$null

        Add-HealthResult `
            -Check "CPU" `
            -Status "OK" `
            -Details "$CPUModel ($CPUCount logical processors)"
    }
    catch {

        Add-HealthResult `
            -Check "CPU" `
            -Status "INFO" `
            -Details "CPU information unavailable."
    }
}

# =========================================================
# MEMORY
# =========================================================

if ($IsLinux) {

    try {

        $MemoryInfo = Get-Content "/proc/meminfo"

        $TotalKB = (
            $MemoryInfo |
            Where-Object { $_ -match '^MemTotal:' }
        ) -replace '[^\d]', ''

        $AvailableKB = (
            $MemoryInfo |
            Where-Object { $_ -match '^MemAvailable:' }
        ) -replace '[^\d]', ''

        $TotalGB = [double]$TotalKB / 1MB
        $AvailableGB = [double]$AvailableKB / 1MB

        $UsedGB = $TotalGB - $AvailableGB

        $MemoryPercent = [math]::Round(
            ($UsedGB / $TotalGB) * 100,
            1
        )

        if ($MemoryPercent -lt 80) {
            $MemoryStatus = "OK"
        }
        elseif ($MemoryPercent -lt 90) {
            $MemoryStatus = "WARNING"
        }
        else {
            $MemoryStatus = "CRITICAL"
        }

        Add-HealthResult `
            -Check "Memory Usage" `
            -Status $MemoryStatus `
            -Details "$MemoryPercent% used ($([math]::Round($UsedGB, 2)) GB / $([math]::Round($TotalGB, 2)) GB)"
    }
    catch {

        Add-HealthResult `
            -Check "Memory Usage" `
            -Status "INFO" `
            -Details "Memory information unavailable."
    }
}
elseif ($IsWindows) {

    try {

        $OS = Get-CimInstance Win32_OperatingSystem

        $TotalGB = $OS.TotalVisibleMemorySize / 1MB
        $FreeGB = $OS.FreePhysicalMemory / 1MB
        $UsedGB = $TotalGB - $FreeGB

        $MemoryPercent = [math]::Round(
            ($UsedGB / $TotalGB) * 100,
            1
        )

        if ($MemoryPercent -lt 80) {
            $MemoryStatus = "OK"
        }
        elseif ($MemoryPercent -lt 90) {
            $MemoryStatus = "WARNING"
        }
        else {
            $MemoryStatus = "CRITICAL"
        }

        Add-HealthResult `
            -Check "Memory Usage" `
            -Status $MemoryStatus `
            -Details "$MemoryPercent% used ($([math]::Round($UsedGB, 2)) GB / $([math]::Round($TotalGB, 2)) GB)"
    }
    catch {

        Add-HealthResult `
            -Check "Memory Usage" `
            -Status "INFO" `
            -Details "Memory information unavailable."
    }
}
else {

    Add-HealthResult `
        -Check "Memory Usage" `
        -Status "INFO" `
        -Details "Memory monitoring is not implemented for this platform."
}

# =========================================================
# DISK SPACE
# =========================================================

try {

    $Drives = Get-PSDrive -PSProvider FileSystem

    foreach ($Drive in $Drives) {

        $TotalBytes = $Drive.Used + $Drive.Free

        if ($TotalBytes -gt 0) {

            $FreePercent = [math]::Round(
                ($Drive.Free / $TotalBytes) * 100,
                1
            )

            $FreeGB = [math]::Round(
                $Drive.Free / 1GB,
                2
            )

            $TotalGB = [math]::Round(
                $TotalBytes / 1GB,
                2
            )

            if ($FreePercent -gt 20) {
                $DiskStatus = "OK"
            }
            elseif ($FreePercent -gt 10) {
                $DiskStatus = "WARNING"
            }
            else {
                $DiskStatus = "CRITICAL"
            }

            Add-HealthResult `
                -Check "Disk $($Drive.Name)" `
                -Status $DiskStatus `
                -Details "$FreeGB GB free of $TotalGB GB ($FreePercent% free)"
        }
    }
}
catch {

    Add-HealthResult `
        -Check "Disk Space" `
        -Status "INFO" `
        -Details "Disk information unavailable."
}

# =========================================================
# SYSTEM UPTIME
# =========================================================

try {

    if ($IsLinux) {

        $UptimeSeconds = (
            Get-Content "/proc/uptime"
        ).Split()[0]

        $Uptime = [TimeSpan]::FromSeconds(
            [double]$UptimeSeconds
        )
    }
    elseif ($IsWindows) {

        $Uptime = (
            Get-Date
        ) - (
            (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        )
    }
    elseif ($IsMacOS) {

        $BootTime = & sysctl -n kern.boottime 2>$null

        if ($BootTime -match 'sec\s*=\s*(\d+)') {

            $BootDate = [DateTimeOffset]::FromUnixTimeSeconds(
                [long]$Matches[1]
            ).LocalDateTime

            $Uptime = (Get-Date) - $BootDate
        }
    }

    if ($null -ne $Uptime) {

        if ($Uptime.Days -lt 7) {
            $UptimeStatus = "OK"
        }
        else {
            $UptimeStatus = "WARNING"
        }

        Add-HealthResult `
            -Check "System Uptime" `
            -Status $UptimeStatus `
            -Details "$($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes"
    }
}
catch {

    Add-HealthResult `
        -Check "System Uptime" `
        -Status "INFO" `
        -Details "Uptime information unavailable."
}

# =========================================================
# INTERNET CONNECTIVITY
# =========================================================

try {

    $Internet = Test-Connection `
        -TargetName "1.1.1.1" `
        -Count 1 `
        -Quiet `
        -ErrorAction SilentlyContinue

    if ($Internet) {

        Add-HealthResult `
            -Check "Internet Connectivity" `
            -Status "OK" `
            -Details "Internet connection available."
    }
    else {

        Add-HealthResult `
            -Check "Internet Connectivity" `
            -Status "CRITICAL" `
            -Details "Unable to reach 1.1.1.1."
    }
}
catch {

    Add-HealthResult `
        -Check "Internet Connectivity" `
        -Status "WARNING" `
        -Details "Connectivity test failed."
}

# =========================================================
# GITHUB CODESPACES DETECTION
# =========================================================

if ($env:CODESPACES -eq "true") {

    Add-HealthResult `
        -Check "GitHub Codespaces" `
        -Status "INFO" `
        -Details "Running inside GitHub Codespaces."
}

# =========================================================
# OVERALL HEALTH
# =========================================================

$CriticalCount = @(
    $Results |
        Where-Object { $_.Status -eq "CRITICAL" }
).Count

$WarningCount = @(
    $Results |
        Where-Object { $_.Status -eq "WARNING" }
).Count

if ($CriticalCount -gt 0) {

    $OverallStatus = "CRITICAL"
}
elseif ($WarningCount -gt 0) {

    $OverallStatus = "WARNING"
}
else {

    $OverallStatus = "HEALTHY"
}

# =========================================================
# BUILD HTML TABLE
# =========================================================

$Rows = foreach ($Result in $Results) {

    $Check   = ConvertTo-HtmlSafe $Result.Check
    $Status  = ConvertTo-HtmlSafe $Result.Status
    $Details = ConvertTo-HtmlSafe $Result.Details

    $CSSClass = switch ($Result.Status) {

        "OK" {
            "ok"
        }

        "WARNING" {
            "warning"
        }

        "CRITICAL" {
            "critical"
        }

        default {
            "info"
        }
    }

@"
<tr>
    <td>$Check</td>
    <td class="$CSSClass">$Status</td>
    <td>$Details</td>
</tr>
"@
}

$RowsHtml = $Rows -join "`n"

$OverallCSSClass = switch ($OverallStatus) {

    "HEALTHY" {
        "ok"
    }

    "WARNING" {
        "warning"
    }

    "CRITICAL" {
        "critical"
    }

    default {
        "info"
    }
}

# =========================================================
# HTML DOCUMENT
# =========================================================

$SafeComputerName = ConvertTo-HtmlSafe $ComputerName
$SafeDate         = ConvertTo-HtmlSafe $ReportDate.ToString()

$HTML = @"
<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
PC Health Report - $SafeComputerName
</title>

<style>

* {
    box-sizing: border-box;
}

body {

    font-family:
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        Arial,
        sans-serif;

    background: #f4f6f8;

    margin: 0;

    padding: 40px;

    color: #333;
}

.container {

    max-width: 1000px;

    margin: auto;

    background: white;

    padding: 30px;

    border-radius: 12px;

    box-shadow:
        0 4px 12px rgba(0,0,0,0.08);
}

h1 {

    margin-bottom: 5px;
}

.subtitle {

    color: #666;

    line-height: 1.6;

    margin-bottom: 30px;
}

.summary {

    padding: 20px;

    border-radius: 8px;

    margin-bottom: 30px;

    font-size: 20px;

    font-weight: bold;
}

table {

    width: 100%;

    border-collapse: collapse;

    margin-top: 15px;
}

th {

    background: #333;

    color: white;

    padding: 14px;

    text-align: left;
}

td {

    padding: 13px;

    border-bottom: 1px solid #ddd;
}

tr:hover {

    background: #f8f8f8;
}

.ok {

    color: #16803c;

    font-weight: bold;
}

.warning {

    color: #b26a00;

    font-weight: bold;
}

.critical {

    color: #c62828;

    font-weight: bold;
}

.info {

    color: #555;

    font-weight: bold;
}

.footer {

    margin-top: 30px;

    padding-top: 15px;

    border-top: 1px solid #ddd;

    color: #777;

    font-size: 13px;
}

@media (max-width: 700px) {

    body {

        padding: 10px;
    }

    .container {

        padding: 15px;
    }

    table {

        font-size: 13px;
    }

    th,
    td {

        padding: 8px;
    }
}

</style>

</head>

<body>

<div class="container">

<h1>
PC Health Report
</h1>

<div class="subtitle">

<strong>Computer:</strong>
$SafeComputerName

<br>

<strong>Generated:</strong>
$SafeDate

<br>

<strong>PowerShell:</strong>
$PowerShellVersion

</div>

<div class="summary $OverallCSSClass">

Overall System Health:
$OverallStatus

</div>

<h2>
Health Checks
</h2>

<table>

<thead>

<tr>

<th>
Check
</th>

<th>
Status
</th>

<th>
Details
</th>

</tr>

</thead>

<tbody>

$RowsHtml

</tbody>

</table>

<div class="footer">

Generated automatically by
PowerShell 7.

<br>

Environment:
$($PSVersionTable.OS)

</div>

</div>

</body>

</html>
"@

# =========================================================
# SAVE REPORT
# =========================================================

$ReportFile = Join-Path `
    $ReportDirectory `
    "PC-Health-$($ReportDate.ToString('yyyy-MM-dd-HHmmss')).html"

$HTML |
    Out-File `
        -FilePath $ReportFile `
        -Encoding UTF8

# =========================================================
# CONSOLE OUTPUT
# =========================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "       HTML REPORT GENERATED            " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Computer : " -NoNewline
Write-Host $ComputerName -ForegroundColor Cyan

Write-Host "Status   : " -NoNewline

switch ($OverallStatus) {

    "HEALTHY" {
        Write-Host $OverallStatus -ForegroundColor Green
    }

    "WARNING" {
        Write-Host $OverallStatus -ForegroundColor Yellow
    }

    "CRITICAL" {
        Write-Host $OverallStatus -ForegroundColor Red
    }
}

Write-Host "Report   : " -NoNewline
Write-Host $ReportFile -ForegroundColor Cyan

Write-Host ""
Write-Host "Checks performed : $($Results.Count)"
Write-Host "Warnings         : $WarningCount"
Write-Host "Critical issues  : $CriticalCount"

# =========================================================
# BROWSER HANDLING
# =========================================================

if ($IsWindows) {

    try {

        Start-Process `
            -FilePath $ReportFile `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "Report opened in your default browser." `
            -ForegroundColor Green
    }
    catch {

        Write-Host ""
        Write-Host "Report created successfully." `
            -ForegroundColor Green

        Write-Host "Could not automatically open the browser." `
            -ForegroundColor Yellow
    }
}
elseif ($IsMacOS) {

    try {

        & open $ReportFile

        Write-Host ""
        Write-Host "Report opened in your default browser." `
            -ForegroundColor Green
    }
    catch {

        Write-Host ""
        Write-Host "Report created successfully." `
            -ForegroundColor Green

        Write-Host "Open the report manually:" `
            -ForegroundColor Yellow

        Write-Host $ReportFile `
            -ForegroundColor Cyan
    }
}
elseif ($IsLinux) {

    Write-Host ""
    Write-Host "Linux/Codespaces environment detected." `
        -ForegroundColor Yellow

    Write-Host "The report was NOT launched automatically." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Report location:" `
        -ForegroundColor Yellow

    Write-Host $ReportFile `
        -ForegroundColor Cyan

    Write-Host ""
    Write-Host "Open the generated HTML file from the" `
        -ForegroundColor Gray

    Write-Host "VS Code Explorer or download/open it locally." `
        -ForegroundColor Gray
}
