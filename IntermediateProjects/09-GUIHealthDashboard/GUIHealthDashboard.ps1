#requires -Version 7.0

<#
.SYNOPSIS
    GUI Health Dashboard

.DESCRIPTION
    Displays basic Windows health information in a graphical dashboard.

.NOTES
    Project: GUI Health Dashboard
    Concept: GUI controls
    Language: PowerShell
    Platform: Windows
#>

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Windows check
# ------------------------------------------------------------

if (-not $IsWindows) {
    Write-Host ""
    Write-Host "This application requires Windows." -ForegroundColor Yellow
    Write-Host "GitHub Codespaces runs Linux, so test this script on Windows."
    Write-Host ""
    exit 1
}

# ------------------------------------------------------------
# Load Windows Forms
# ------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ------------------------------------------------------------
# Health check functions
# ------------------------------------------------------------

function Get-CPUHealth {

    try {
        $CPU = Get-CimInstance Win32_Processor |
            Measure-Object -Property LoadPercentage -Average

        $Usage = [math]::Round($CPU.Average, 1)

        if ($Usage -ge 90) {
            return [PSCustomObject]@{
                Name   = "CPU Usage"
                Value  = "$Usage%"
                Status = "CRITICAL"
            }
        }
        elseif ($Usage -ge 75) {
            return [PSCustomObject]@{
                Name   = "CPU Usage"
                Value  = "$Usage%"
                Status = "WARNING"
            }
        }
        else {
            return [PSCustomObject]@{
                Name   = "CPU Usage"
                Value  = "$Usage%"
                Status = "OK"
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Name   = "CPU Usage"
            Value  = "Unavailable"
            Status = "WARNING"
        }
    }
}

function Get-MemoryHealth {

    try {
        $OS = Get-CimInstance Win32_OperatingSystem

        $Total = $OS.TotalVisibleMemorySize
        $Free = $OS.FreePhysicalMemory

        $UsedPercent = [math]::Round(
            (($Total - $Free) / $Total) * 100,
            1
        )

        if ($UsedPercent -ge 90) {
            $Status = "CRITICAL"
        }
        elseif ($UsedPercent -ge 75) {
            $Status = "WARNING"
        }
        else {
            $Status = "OK"
        }

        return [PSCustomObject]@{
            Name   = "Memory Usage"
            Value  = "$UsedPercent%"
            Status = $Status
        }
    }
    catch {
        return [PSCustomObject]@{
            Name   = "Memory Usage"
            Value  = "Unavailable"
            Status = "WARNING"
        }
    }
}

function Get-DiskHealth {

    try {
        $Disk = Get-CimInstance Win32_LogicalDisk `
            -Filter "DeviceID='C:'"

        $FreePercent = [math]::Round(
            ($Disk.FreeSpace / $Disk.Size) * 100,
            1
        )

        if ($FreePercent -lt 10) {
            $Status = "CRITICAL"
        }
        elseif ($FreePercent -lt 20) {
            $Status = "WARNING"
        }
        else {
            $Status = "OK"
        }

        return [PSCustomObject]@{
            Name   = "Disk Free Space"
            Value  = "$FreePercent%"
            Status = $Status
        }
    }
    catch {
        return [PSCustomObject]@{
            Name   = "Disk Free Space"
            Value  = "Unavailable"
            Status = "WARNING"
        }
    }
}

function Get-InternetHealth {

    try {
        $Connected = Test-Connection `
            -TargetName "1.1.1.1" `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        if ($Connected) {
            return [PSCustomObject]@{
                Name   = "Internet"
                Value  = "Connected"
                Status = "OK"
            }
        }
        else {
            return [PSCustomObject]@{
                Name   = "Internet"
                Value  = "Offline"
                Status = "CRITICAL"
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Name   = "Internet"
            Value  = "Unknown"
            Status = "WARNING"
        }
    }
}

function Get-UptimeHealth {

    try {
        $OS = Get-CimInstance Win32_OperatingSystem

        $Uptime = (Get-Date) - $OS.LastBootUpTime

        $Text = "{0}d {1}h {2}m" -f `
            $Uptime.Days,
            $Uptime.Hours,
            $Uptime.Minutes

        if ($Uptime.Days -ge 14) {
            $Status = "WARNING"
        }
        else {
            $Status = "OK"
        }

        return [PSCustomObject]@{
            Name   = "System Uptime"
            Value  = $Text
            Status = $Status
        }
    }
    catch {
        return [PSCustomObject]@{
            Name   = "System Uptime"
            Value  = "Unavailable"
            Status = "WARNING"
        }
    }
}

# ------------------------------------------------------------
# Collect all health information
# ------------------------------------------------------------

function Get-HealthData {

    return @(
        Get-CPUHealth
        Get-MemoryHealth
        Get-DiskHealth
        Get-InternetHealth
        Get-UptimeHealth
    )
}

# ------------------------------------------------------------
# Create main form
# ------------------------------------------------------------

$Form = New-Object System.Windows.Forms.Form

$Form.Text = "PC Health Dashboard"
$Form.Size = New-Object System.Drawing.Size(800, 600)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# ------------------------------------------------------------
# Title
# ------------------------------------------------------------

$Title = New-Object System.Windows.Forms.Label

$Title.Text = "PC HEALTH DASHBOARD"
$Title.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    20,
    [System.Drawing.FontStyle]::Bold
)

$Title.AutoSize = $true
$Title.Location = New-Object System.Drawing.Point(250, 20)

$Form.Controls.Add($Title)

# ------------------------------------------------------------
# Overall status
# ------------------------------------------------------------

$OverallLabel = New-Object System.Windows.Forms.Label

$OverallLabel.Text = "Overall Status: Checking..."
$OverallLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    14,
    [System.Drawing.FontStyle]::Bold
)

$OverallLabel.AutoSize = $true
$OverallLabel.Location = New-Object System.Drawing.Point(250, 65)

$Form.Controls.Add($OverallLabel)

# ------------------------------------------------------------
# Health list
# ------------------------------------------------------------

$HealthList = New-Object System.Windows.Forms.ListView

$HealthList.Location = New-Object System.Drawing.Point(40, 120)
$HealthList.Size = New-Object System.Drawing.Size(700, 300)

$HealthList.View = "Details"
$HealthList.FullRowSelect = $true
$HealthList.GridLines = $true

[void]$HealthList.Columns.Add("Health Check", 250)
[void]$HealthList.Columns.Add("Value", 200)
[void]$HealthList.Columns.Add("Status", 150)

$Form.Controls.Add($HealthList)

# ------------------------------------------------------------
# Last updated label
# ------------------------------------------------------------

$UpdatedLabel = New-Object System.Windows.Forms.Label

$UpdatedLabel.Text = "Last Updated: Never"
$UpdatedLabel.AutoSize = $true
$UpdatedLabel.Location = New-Object System.Drawing.Point(40, 440)

$Form.Controls.Add($UpdatedLabel)

# ------------------------------------------------------------
# Refresh button
# ------------------------------------------------------------

$RefreshButton = New-Object System.Windows.Forms.Button

$RefreshButton.Text = "Refresh"
$RefreshButton.Size = New-Object System.Drawing.Size(130, 45)
$RefreshButton.Location = New-Object System.Drawing.Point(40, 480)

$Form.Controls.Add($RefreshButton)

# ------------------------------------------------------------
# Exit button
# ------------------------------------------------------------

$ExitButton = New-Object System.Windows.Forms.Button

$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(130, 45)
$ExitButton.Location = New-Object System.Drawing.Point(190, 480)

$Form.Controls.Add($ExitButton)

# ------------------------------------------------------------
# Update dashboard
# ------------------------------------------------------------

function Update-Dashboard {

    $HealthData = Get-HealthData

    $HealthList.Items.Clear()

    foreach ($Check in $HealthData) {

        $Item = New-Object System.Windows.Forms.ListViewItem(
            $Check.Name
        )

        [void]$Item.SubItems.Add($Check.Value)
        [void]$Item.SubItems.Add($Check.Status)

        [void]$HealthList.Items.Add($Item)
    }

    $Critical = @(
        $HealthData |
        Where-Object Status -eq "CRITICAL"
    ).Count

    $Warning = @(
        $HealthData |
        Where-Object Status -eq "WARNING"
    ).Count

    if ($Critical -gt 0) {
        $OverallLabel.Text = "Overall Status: CRITICAL"
    }
    elseif ($Warning -gt 0) {
        $OverallLabel.Text = "Overall Status: WARNING"
    }
    else {
        $OverallLabel.Text = "Overall Status: HEALTHY"
    }

    $UpdatedLabel.Text = "Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

# ------------------------------------------------------------
# Button events
# ------------------------------------------------------------

$RefreshButton.Add_Click({

    Update-Dashboard

})

$ExitButton.Add_Click({

    $Form.Close()

})

# ------------------------------------------------------------
# Initial dashboard load
# ------------------------------------------------------------

$Form.Add_Shown({

    Update-Dashboard

})

# ------------------------------------------------------------
# Start application
# ------------------------------------------------------------

[System.Windows.Forms.Application]::Run($Form)