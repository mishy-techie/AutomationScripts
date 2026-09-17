#requires -Version 7.0

<#
.SYNOPSIS
    Cross-platform Log File Analyzer

.DESCRIPTION
    Analyzes a text log file and reports:
    - Total lines
    - Log levels
    - Errors
    - Warnings
    - Informational messages
    - Matching keywords
    - Recent log entries

.NOTES
    Project: Log File Analyzer
    Concept: Text parsing
    Language: PowerShell
    Platform: Windows, Linux, macOS, GitHub Codespaces
#>

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$DefaultLogFile = Join-Path $PSScriptRoot "sample.log"
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
    "Log-Analysis-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"

# ------------------------------------------------------------
# Select input file
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "          LOG FILE ANALYZER"
Write-Host "========================================"
Write-Host ""

$InputPath = Read-Host "Enter log file path, or press Enter for sample.log"

if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $InputPath = $DefaultLogFile
}

if (-not (Test-Path $InputPath -PathType Leaf)) {

    Write-Host ""
    Write-Host "Log file not found:" -ForegroundColor Red
    Write-Host $InputPath
    exit 1
}

# ------------------------------------------------------------
# Read log file
# ------------------------------------------------------------

try {
    $Lines = Get-Content `
        -Path $InputPath `
        -Encoding UTF8
}
catch {
    Write-Host "Unable to read log file." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# ------------------------------------------------------------
# Initialize counters
# ------------------------------------------------------------

$LevelCounts = @{
    TRACE   = 0
    DEBUG   = 0
    INFO    = 0
    NOTICE  = 0
    WARN    = 0
    WARNING = 0
    ERROR   = 0
    CRITICAL = 0
    FATAL   = 0
    UNKNOWN = 0
}

$KeywordCounts = @{
    timeout    = 0
    connection = 0
    failed     = 0
    denied     = 0
    exception  = 0
}

$ErrorEntries = [System.Collections.Generic.List[string]]::new()
$WarningEntries = [System.Collections.Generic.List[string]]::new()

# ------------------------------------------------------------
# Analyze each line
# ------------------------------------------------------------

foreach ($Line in $Lines) {

    $UpperLine = $Line.ToUpperInvariant()

    # Detect explicit log level
    $LevelMatch = [regex]::Match(
        $Line,
        '(?i)\b(TRACE|DEBUG|INFO|NOTICE|WARN|WARNING|ERROR|CRITICAL|FATAL)\b'
    )

    if ($LevelMatch.Success) {

        $Level = $LevelMatch.Groups[1].Value.ToUpperInvariant()

        if ($LevelCounts.ContainsKey($Level)) {
            $LevelCounts[$Level]++
        }
        else {
            $LevelCounts["UNKNOWN"]++
        }
    }
    else {

        # Infer a level from common words
        if ($UpperLine -match "\b(ERROR|FAILED|FAILURE|EXCEPTION)\b") {
            $LevelCounts["ERROR"]++
        }
        elseif ($UpperLine -match "\b(WARN|WARNING)\b") {
            $LevelCounts["WARNING"]++
        }
        elseif ($UpperLine -match "\b(INFO|STARTED|COMPLETED|SUCCESS)\b") {
            $LevelCounts["INFO"]++
        }
        else {
            $LevelCounts["UNKNOWN"]++
        }
    }

    # Store error and warning lines
    if ($UpperLine -match "\b(ERROR|CRITICAL|FATAL|FAILED|FAILURE|EXCEPTION)\b") {
        $ErrorEntries.Add($Line)
    }

    if ($UpperLine -match "\b(WARN|WARNING)\b") {
        $WarningEntries.Add($Line)
    }

    # Count keywords
    foreach ($Keyword in @($KeywordCounts.Keys)) {

        if ($UpperLine.Contains($Keyword.ToUpperInvariant())) {
            $KeywordCounts[$Keyword]++
        }
    }
}

# ------------------------------------------------------------
# Build analysis report
# ------------------------------------------------------------

$Analysis = [PSCustomObject]@{
    File           = (Resolve-Path $InputPath).Path
    AnalyzedAt     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalLines     = $Lines.Count
    LevelCounts    = $LevelCounts
    KeywordCounts  = $KeywordCounts
    ErrorCount     = $ErrorEntries.Count
    WarningCount   = $WarningEntries.Count
    ErrorEntries   = @($ErrorEntries)
    WarningEntries = @($WarningEntries)
    RecentEntries  = @(
        $Lines |
            Select-Object -Last 10
    )
}

# ------------------------------------------------------------
# Display summary
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "             ANALYSIS SUMMARY"
Write-Host "========================================"
Write-Host ""

Write-Host "File         : $($Analysis.File)"
Write-Host "Total lines  : $($Analysis.TotalLines)"
Write-Host "Errors       : $($Analysis.ErrorCount)"
Write-Host "Warnings     : $($Analysis.WarningCount)"
Write-Host ""

Write-Host "Log levels:"
foreach ($Level in $LevelCounts.Keys | Sort-Object) {
    Write-Host ("  {0,-10}: {1}" -f $Level, $LevelCounts[$Level])
}

Write-Host ""
Write-Host "Keywords:"

foreach ($Keyword in $KeywordCounts.Keys | Sort-Object) {
    Write-Host ("  {0,-10}: {1}" -f $Keyword, $KeywordCounts[$Keyword])
}

# ------------------------------------------------------------
# Export report
# ------------------------------------------------------------

$Analysis |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -Path $ReportFile `
        -Encoding UTF8

Write-Host ""
Write-Host "Report saved to:"
Write-Host $ReportFile -ForegroundColor Green
Write-Host ""