#requires -Version 7.0

<#
    Project: Certificate Expiration Checker
    Concept: Certificates
    Language: PowerShell 7+

    Cross-platform:
      Windows / Linux / macOS / GitHub Codespaces

    Checks:
      - Certificate subject
      - Issuer
      - Thumbprint
      - Valid from
      - Expiration date
      - Days remaining
      - Expiration status

    Supported certificate files:
      .cer
      .crt
      .pem
      .pfx

    Usage:
      pwsh ./16-CertificateExpirationChecker.ps1

      pwsh ./16-CertificateExpirationChecker.ps1 -CertificatePath ./certificate.crt
#>

param(
    [string]$CertificatePath
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$WarningDays = 30
$CriticalDays = 7

$ReportDirectory = Join-Path $PSScriptRoot "reports"

$ReportFile = Join-Path `
    $ReportDirectory `
    "certificate-expiration-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

New-Item `
    -ItemType Directory `
    -Path $ReportDirectory `
    -Force |
    Out-Null

# ------------------------------------------------------------
# Helper: Determine certificate status
# ------------------------------------------------------------

function Get-CertificateStatus {
    param(
        [Parameter(Mandatory)]
        [datetime]$NotAfter
    )

    $DaysRemaining = ($NotAfter - (Get-Date)).TotalDays

    if ($DaysRemaining -lt 0) {
        return "EXPIRED"
    }

    if ($DaysRemaining -le $CriticalDays) {
        return "CRITICAL"
    }

    if ($DaysRemaining -le $WarningDays) {
        return "WARNING"
    }

    return "HEALTHY"
}

# ------------------------------------------------------------
# Helper: Load certificate
# ------------------------------------------------------------

function Get-CertificateFromFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    switch ($Extension) {

        ".pfx" {
            Write-Host ""
            Write-Host "PFX certificates may require a password." -ForegroundColor Yellow

            $Password = Read-Host "Enter PFX password" -AsSecureString

            return [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                $Path,
                $Password
            )
        }

        ".pem" {
            return [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($Path)
        }

        default {
            return [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Path)
        }
    }
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "      CERTIFICATE EXPIRATION CHECKER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Get certificate path
# ------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($CertificatePath)) {

    $CertificatePath = Read-Host "Enter certificate file path"
}

if ([string]::IsNullOrWhiteSpace($CertificatePath)) {

    Write-Host "No certificate path was provided." -ForegroundColor Red
    exit 1
}

# Expand relative paths

$CertificatePath = [System.IO.Path]::GetFullPath(
    $CertificatePath,
    (Get-Location).Path
)

# ------------------------------------------------------------
# Verify file
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $CertificatePath -PathType Leaf)) {

    Write-Host ""
    Write-Host "Certificate file not found:" -ForegroundColor Red
    Write-Host $CertificatePath -ForegroundColor Yellow
    exit 1
}

Write-Host "Certificate:" -ForegroundColor Yellow
Write-Host $CertificatePath
Write-Host ""

# ------------------------------------------------------------
# Load certificate
# ------------------------------------------------------------

try {

    $Certificate = Get-CertificateFromFile -Path $CertificatePath
}
catch {

    Write-Host ""
    Write-Host "Unable to load certificate." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Certificate information
# ------------------------------------------------------------

$Now = Get-Date

$DaysRemaining = [math]::Floor(
    ($Certificate.NotAfter - $Now).TotalDays
)

$Status = Get-CertificateStatus -NotAfter $Certificate.NotAfter

# ------------------------------------------------------------
# Display certificate details
# ------------------------------------------------------------

Write-Host "Subject        : $($Certificate.Subject)"
Write-Host "Issuer         : $($Certificate.Issuer)"
Write-Host "Thumbprint     : $($Certificate.Thumbprint)"
Write-Host "Valid From     : $($Certificate.NotBefore)"
Write-Host "Expires        : $($Certificate.NotAfter)"
Write-Host "Days Remaining : $DaysRemaining"
Write-Host ""

switch ($Status) {

    "HEALTHY" {
        Write-Host "Status: HEALTHY" -ForegroundColor Green
    }

    "WARNING" {
        Write-Host "Status: WARNING" -ForegroundColor Yellow
    }

    "CRITICAL" {
        Write-Host "Status: CRITICAL" -ForegroundColor Red
    }

    "EXPIRED" {
        Write-Host "Status: EXPIRED" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Additional certificate information
# ------------------------------------------------------------

$HasPrivateKey = $Certificate.HasPrivateKey

$SignatureAlgorithm = $Certificate.SignatureAlgorithm.FriendlyName

$PublicKeyAlgorithm = $Certificate.PublicKey.Oid.FriendlyName

$SerialNumber = $Certificate.SerialNumber

# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

$Report = [PSCustomObject]@{
    ComputerName       = [System.Environment]::MachineName
    AuditTime          = $Now

    CertificatePath    = $CertificatePath

    Subject            = $Certificate.Subject
    Issuer             = $Certificate.Issuer
    Thumbprint         = $Certificate.Thumbprint
    SerialNumber       = $SerialNumber

    ValidFrom          = $Certificate.NotBefore
    Expires            = $Certificate.NotAfter

    DaysRemaining      = $DaysRemaining
    Status             = $Status

    HasPrivateKey      = $HasPrivateKey
    SignatureAlgorithm = $SignatureAlgorithm
    PublicKeyAlgorithm = $PublicKeyAlgorithm
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
# Summary
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       CERTIFICATE CHECK COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status : $Status"
Write-Host "Report : $ReportFile"
Write-Host ""