```powershell
#requires -Version 7.0

<#
.SYNOPSIS
    Email Report Sender

.DESCRIPTION
    Sends an HTML health report through an SMTP server.

    SMTP credentials are read from environment variables:

        SMTP_SERVER
        SMTP_PORT
        SMTP_USERNAME
        SMTP_PASSWORD
        REPORT_EMAIL_TO
        REPORT_EMAIL_FROM

.NOTES
    Project : Email Report Sender
    Concept : SMTP
    Language: PowerShell 7+
#>

# =========================================================
# CONFIGURATION
# =========================================================

$ReportDirectory = Join-Path $HOME "PC-Health-Reports"

$SMTPServer = $env:SMTP_SERVER
$SMTPPort   = $env:SMTP_PORT
$SMTPUser   = $env:SMTP_USERNAME
$SMTPPass   = $env:SMTP_PASSWORD

$EmailTo    = $env:REPORT_EMAIL_TO
$EmailFrom  = $env:REPORT_EMAIL_FROM

# Default SMTP port if one was not supplied
if (-not $SMTPPort) {
    $SMTPPort = 587
}

# =========================================================
# VALIDATE CONFIGURATION
# =========================================================

$MissingSettings = @()

if (-not $SMTPServer) {
    $MissingSettings += "SMTP_SERVER"
}

if (-not $SMTPUser) {
    $MissingSettings += "SMTP_USERNAME"
}

if (-not $SMTPPass) {
    $MissingSettings += "SMTP_PASSWORD"
}

if (-not $EmailTo) {
    $MissingSettings += "REPORT_EMAIL_TO"
}

if (-not $EmailFrom) {
    $MissingSettings += "REPORT_EMAIL_FROM"
}

if ($MissingSettings.Count -gt 0) {

    Write-Host ""
    Write-Host "Missing SMTP configuration:" `
        -ForegroundColor Red

    $MissingSettings |
        ForEach-Object {
            Write-Host " - $_" -ForegroundColor Yellow
        }

    Write-Host ""
    Write-Host "Set the required environment variables and try again."
    exit 1
}

# =========================================================
# FIND LATEST HEALTH REPORT
# =========================================================

if (-not (Test-Path $ReportDirectory)) {

    Write-Host "Report directory does not exist:" `
        -ForegroundColor Red

    Write-Host $ReportDirectory

    exit 1
}

$LatestReport = Get-ChildItem `
    -Path $ReportDirectory `
    -Filter "*.html" `
    -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $LatestReport) {

    Write-Host ""
    Write-Host "No HTML health report was found." `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "Run 05-HTMLReportGenerator.ps1 first."

    exit 1
}

# =========================================================
# READ REPORT
# =========================================================

$ReportContent = Get-Content `
    -Path $LatestReport.FullName `
    -Raw

# Determine status from the HTML report
if ($ReportContent -match "Overall System Health:\s*CRITICAL") {

    $HealthStatus = "CRITICAL"
}
elseif ($ReportContent -match "Overall System Health:\s*WARNING") {

    $HealthStatus = "WARNING"
}
else {

    $HealthStatus = "HEALTHY"
}

# =========================================================
# CREATE EMAIL
# =========================================================

$Subject = "PC Health Report - $env:COMPUTERNAME - $HealthStatus"

$EmailBody = @"
Hello,

Attached is the latest PC Health Report.

Computer:
$([System.Environment]::MachineName)

Health Status:
$HealthStatus

Report Generated:
$(Get-Date)

The complete HTML report is attached to this email.

Regards,
PowerShell Automation
"@

# =========================================================
# CREATE SMTP CLIENT
# =========================================================

try {

    $SecurePassword = ConvertTo-SecureString `
        $SMTPPass `
        -AsPlainText `
        -Force

    $Credential = [System.Management.Automation.PSCredential]::new(
        $SMTPUser,
        $SecurePassword
    )

    $MailMessage = [System.Net.Mail.MailMessage]::new()

    $MailMessage.From = $EmailFrom
    $MailMessage.To.Add($EmailTo)

    $MailMessage.Subject = $Subject
    $MailMessage.Body = $EmailBody
    $MailMessage.IsBodyHtml = $false

    # Attach HTML report
    $Attachment = [System.Net.Mail.Attachment]::new(
        $LatestReport.FullName
    )

    $MailMessage.Attachments.Add($Attachment)

    $SMTP = [System.Net.Mail.SmtpClient]::new(
        $SMTPServer,
        [int]$SMTPPort
    )

    $SMTP.EnableSsl = $true
    $SMTP.Credentials = $Credential

    # =====================================================
    # SEND EMAIL
    # =====================================================

    Write-Host ""
    Write-Host "========================================" `
        -ForegroundColor Cyan

    Write-Host "       EMAIL REPORT SENDER" `
        -ForegroundColor Cyan

    Write-Host "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "SMTP Server : $SMTPServer"
    Write-Host "SMTP Port   : $SMTPPort"
    Write-Host "From        : $EmailFrom"
    Write-Host "To          : $EmailTo"
    Write-Host "Report      : $($LatestReport.Name)"
    Write-Host "Health      : $HealthStatus"

    Write-Host ""
    Write-Host "Sending email..." `
        -ForegroundColor Yellow

    $SMTP.Send($MailMessage)

    Write-Host ""
    Write-Host "Email sent successfully!" `
        -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "Failed to send email." `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "Error:"
    Write-Host $_.Exception.Message `
        -ForegroundColor Yellow

    exit 1
}
finally {

    if ($Attachment) {
        $Attachment.Dispose()
    }

    if ($MailMessage) {
        $MailMessage.Dispose()
    }

    if ($SMTP) {
        $SMTP.Dispose()
    }
}

Write-Host ""
Write-Host "========================================" `
    -ForegroundColor Green

Write-Host "EMAIL REPORT COMPLETE" `
    -ForegroundColor Green

Write-Host "========================================" `
    -ForegroundColor Green
```
