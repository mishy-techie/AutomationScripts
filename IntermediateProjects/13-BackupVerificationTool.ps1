#requires -Version 7.0

<#
.SYNOPSIS
    Cross-platform Backup Verification Tool

.DESCRIPTION
    Validates a backup directory and generates a verification report.

    Checks:
      - Backup directory exists
      - Backup contains files
      - Backup size
      - Most recent backup file
      - Backup age
      - Optional SHA256 checksum verification

.NOTES
    Project: Backup Verification Tool
    Concept: Validation
    Language: PowerShell
    Platform: Windows, Linux, macOS, GitHub Codespaces
#>

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURATION
# ============================================================

# Change this to your actual backup location.
$BackupDirectory = Join-Path $PSScriptRoot "backup"

# How old can the newest backup be before a warning occurs?
$MaximumBackupAgeHours = 24

# Set to $true if you want to calculate SHA256 hashes.
$VerifyChecksums = $true

# Optional manifest file.
# If present, the script can compare stored checksums.
$ChecksumManifest = Join-Path $BackupDirectory "checksums.sha256"

# Reports are stored inside the project directory.
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
    "Backup-Verification-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"

# ============================================================
# HELPER FUNCTION
# ============================================================

function New-CheckResult {

    param (
        [string]$Name,
        [string]$Status,
        [string]$Message
    )

    [PSCustomObject]@{
        Check   = $Name
        Status  = $Status
        Message = $Message
    }
}

# ============================================================
# START
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "       BACKUP VERIFICATION TOOL"
Write-Host "========================================"
Write-Host ""

Write-Host "Backup directory:"
Write-Host $BackupDirectory
Write-Host ""

$Checks = [System.Collections.Generic.List[object]]::new()

# ============================================================
# 1. CHECK DIRECTORY
# ============================================================

Write-Host "[1/6] Checking backup directory..."

if (-not (Test-Path $BackupDirectory -PathType Container)) {

    Write-Host "  CRITICAL: Backup directory does not exist." `
        -ForegroundColor Red

    $Checks.Add(
        (New-CheckResult `
            -Name "Backup Directory" `
            -Status "CRITICAL" `
            -Message "Backup directory does not exist.")
    )

    # No reason to continue because there is nothing to verify.
    $OverallStatus = "CRITICAL"

}
else {

    Write-Host "  OK: Backup directory exists." `
        -ForegroundColor Green

    $Checks.Add(
        (New-CheckResult `
            -Name "Backup Directory" `
            -Status "OK" `
            -Message "Backup directory exists.")
    )

    $OverallStatus = "HEALTHY"
}

# ============================================================
# STOP IF DIRECTORY DOES NOT EXIST
# ============================================================

if (Test-Path $BackupDirectory -PathType Container) {

    # ========================================================
    # 2. FIND BACKUP FILES
    # ========================================================

    Write-Host "[2/6] Finding backup files..."

    $Files = @(
        Get-ChildItem `
            -Path $BackupDirectory `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -ne "checksums.sha256"
        }
    )

    $FileCount = $Files.Count

    if ($FileCount -eq 0) {

        Write-Host "  CRITICAL: No backup files found." `
            -ForegroundColor Red

        $Checks.Add(
            (New-CheckResult `
                -Name "Backup Files" `
                -Status "CRITICAL" `
                -Message "No backup files were found.")
        )

        $OverallStatus = "CRITICAL"
    }
    else {

        Write-Host "  OK: Found $FileCount backup file(s)." `
            -ForegroundColor Green

        $Checks.Add(
            (New-CheckResult `
                -Name "Backup Files" `
                -Status "OK" `
                -Message "Found $FileCount backup file(s).")
        )
    }

    # ========================================================
    # 3. CALCULATE BACKUP SIZE
    # ========================================================

    Write-Host "[3/6] Calculating backup size..."

    $TotalBytes = ($Files | Measure-Object -Property Length -Sum).Sum

    if ($null -eq $TotalBytes) {
        $TotalBytes = 0
    }

    $TotalGB = [math]::Round(
        $TotalBytes / 1GB,
        2
    )

    $TotalMB = [math]::Round(
        $TotalBytes / 1MB,
        2
    )

    Write-Host "  Backup size: $TotalMB MB"

    $Checks.Add(
        (New-CheckResult `
            -Name "Backup Size" `
            -Status "INFO" `
            -Message "$TotalMB MB ($TotalGB GB)")
    )

    # ========================================================
    # 4. CHECK BACKUP AGE
    # ========================================================

    Write-Host "[4/6] Checking backup age..."

    if ($FileCount -gt 0) {

        $NewestFile = $Files |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        $BackupAge = (Get-Date) - $NewestFile.LastWriteTime

        $BackupAgeHours = [math]::Round(
            $BackupAge.TotalHours,
            2
        )

        Write-Host "  Newest backup: $($NewestFile.Name)"
        Write-Host "  Backup age: $BackupAgeHours hours"

        if ($BackupAge.TotalHours -gt $MaximumBackupAgeHours) {

            Write-Host "  WARNING: Backup is too old." `
                -ForegroundColor Yellow

            $Checks.Add(
                (New-CheckResult `
                    -Name "Backup Age" `
                    -Status "WARNING" `
                    -Message "Newest backup is $BackupAgeHours hours old.")
            )

            if ($OverallStatus -eq "HEALTHY") {
                $OverallStatus = "WARNING"
            }
        }
        else {

            Write-Host "  OK: Backup is recent." `
                -ForegroundColor Green

            $Checks.Add(
                (New-CheckResult `
                    -Name "Backup Age" `
                    -Status "OK" `
                    -Message "Newest backup is $BackupAgeHours hours old.")
            )
        }

    }
    else {

        $Checks.Add(
            (New-CheckResult `
                -Name "Backup Age" `
                -Status "CRITICAL" `
                -Message "Cannot determine backup age.")
        )
    }

    # ========================================================
    # 5. CHECK FILE ACCESS
    # ========================================================

    Write-Host "[5/6] Testing backup file access..."

    $UnreadableFiles = [System.Collections.Generic.List[string]]::new()

    foreach ($File in $Files) {

        try {

            $Stream = [System.IO.File]::OpenRead(
                $File.FullName
            )

            $Stream.Close()
            $Stream.Dispose()

        }
        catch {

            $UnreadableFiles.Add(
                $File.FullName
            )
        }
    }

    if ($UnreadableFiles.Count -eq 0) {

        Write-Host "  OK: Backup files are readable." `
            -ForegroundColor Green

        $Checks.Add(
            (New-CheckResult `
                -Name "File Accessibility" `
                -Status "OK" `
                -Message "All backup files can be opened.")
        )
    }
    else {

        Write-Host "  CRITICAL: $($UnreadableFiles.Count) file(s) cannot be read." `
            -ForegroundColor Red

        $Checks.Add(
            (New-CheckResult `
                -Name "File Accessibility" `
                -Status "CRITICAL" `
                -Message "$($UnreadableFiles.Count) file(s) cannot be read.")
        )

        $OverallStatus = "CRITICAL"
    }

    # ========================================================
    # 6. OPTIONAL CHECKSUM VERIFICATION
    # ========================================================

    Write-Host "[6/6] Checking file integrity..."

    if (-not $VerifyChecksums) {

        Write-Host "  INFO: Checksum verification disabled."

        $Checks.Add(
            (New-CheckResult `
                -Name "Checksum Verification" `
                -Status "INFO" `
                -Message "Checksum verification is disabled.")
        )
    }
    elseif (-not (Test-Path $ChecksumManifest -PathType Leaf)) {

        Write-Host "  INFO: No checksum manifest found."

        $Checks.Add(
            (New-CheckResult `
                -Name "Checksum Verification" `
                -Status "INFO" `
                -Message "No checksum manifest found.")
        )
    }
    else {

        Write-Host "  Verifying SHA256 checksums..."

        $HashFailures = [System.Collections.Generic.List[string]]::new()
        $HashChecked = 0

        $ManifestLines = Get-Content `
            -Path $ChecksumManifest `
            -Encoding UTF8

        foreach ($Line in $ManifestLines) {

            if ([string]::IsNullOrWhiteSpace($Line)) {
                continue
            }

            if ($Line.Trim().StartsWith("#")) {
                continue
            }

            # Expected format:
            #
            # HASH  filename
            #
            # Example:
            # abc123...  database.zip

            if ($Line -match `
                '^([A-Fa-f0-9]{64})\s+\*?(.+)$') {

                $ExpectedHash = $Matches[1].ToUpperInvariant()
                $RelativePath = $Matches[2].Trim()

                $ExpectedFile = Join-Path `
                    $BackupDirectory `
                    $RelativePath

                if (-not (Test-Path $ExpectedFile -PathType Leaf)) {

                    $HashFailures.Add(
                        "$RelativePath - file missing"
                    )

                    continue
                }

                try {

                    $ActualHash = (
                        Get-FileHash `
                            -Path $ExpectedFile `
                            -Algorithm SHA256
                    ).Hash.ToUpperInvariant()

                    $HashChecked++

                    if ($ActualHash -ne $ExpectedHash) {

                        $HashFailures.Add(
                            "$RelativePath - checksum mismatch"
                        )
                    }
                }
                catch {

                    $HashFailures.Add(
                        "$RelativePath - unable to calculate checksum"
                    )
                }
            }
        }

        if ($HashFailures.Count -eq 0) {

            Write-Host "  OK: All checked files passed integrity verification." `
                -ForegroundColor Green

            $Checks.Add(
                (New-CheckResult `
                    -Name "Checksum Verification" `
                    -Status "OK" `
                    -Message "$HashChecked file(s) verified.")
            )
        }
        else {

            Write-Host "  CRITICAL: Integrity verification failed." `
                -ForegroundColor Red

            foreach ($Failure in $HashFailures) {
                Write-Host "    $Failure" -ForegroundColor Red
            }

            $Checks.Add(
                (New-CheckResult `
                    -Name "Checksum Verification" `
                    -Status "CRITICAL" `
                    -Message "$($HashFailures.Count) file(s) failed verification.")
            )

            $OverallStatus = "CRITICAL"
        }
    }
}

# ============================================================
# FINAL STATUS
# ============================================================

$CriticalChecks = @(
    $Checks |
        Where-Object Status -eq "CRITICAL"
).Count

$WarningChecks = @(
    $Checks |
        Where-Object Status -eq "WARNING"
).Count

if ($CriticalChecks -gt 0) {
    $OverallStatus = "CRITICAL"
}
elseif ($WarningChecks -gt 0) {
    $OverallStatus = "WARNING"
}
else {
    $OverallStatus = "HEALTHY"
}

# ============================================================
# BUILD REPORT
# ============================================================

$Report = [PSCustomObject]@{
    Tool              = "Backup Verification Tool"
    VerificationTime  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Computer          = [System.Environment]::MachineName
    OperatingSystem   = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    BackupDirectory   = $BackupDirectory
    FileCount         = if ($PSBoundParameters) { $FileCount } else { 0 }
    TotalSizeMB       = if ($PSBoundParameters) { $TotalMB } else { 0 }
    MaximumAgeHours   = $MaximumBackupAgeHours
    OverallStatus     = $OverallStatus
    Checks            = @($Checks)
}

# ============================================================
# EXPORT JSON
# ============================================================

$Report |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -Path $ReportFile `
        -Encoding UTF8

# ============================================================
# DISPLAY SUMMARY
# ============================================================

Write-Host ""
Write-Host "========================================"

switch ($OverallStatus) {

    "HEALTHY" {
        Write-Host "       BACKUP VERIFIED" `
            -ForegroundColor Green
    }

    "WARNING" {
        Write-Host "       BACKUP WARNING" `
            -ForegroundColor Yellow
    }

    "CRITICAL" {
        Write-Host "       BACKUP FAILED" `
            -ForegroundColor Red
    }
}

Write-Host "========================================"
Write-Host ""

Write-Host "Backup directory : $BackupDirectory"
Write-Host "Files checked    : $FileCount"
Write-Host "Backup size      : $TotalMB MB"
Write-Host "Overall status   : $OverallStatus"
Write-Host ""
Write-Host "Report:"
Write-Host $ReportFile
Write-Host ""