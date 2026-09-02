#requires -Version 7.0

<#
.SYNOPSIS
    GUI System Information Tool

.DESCRIPTION
    Displays basic Windows system information using
    a Windows Forms graphical interface.

.NOTES
    Project: GUI System Information Tool
    Concept: Windows Forms
    Language: PowerShell
#>

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Check operating system
# ------------------------------------------------------------

if (-not $IsWindows) {
    Write-Host ""
    Write-Host "This application requires Windows." -ForegroundColor Yellow
    Write-Host "Windows Forms is not available in your GitHub Codespace/Linux environment."
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
# Get system information
# ------------------------------------------------------------

function Get-SystemInformation {

    $Computer = Get-CimInstance Win32_ComputerSystem
    $OS = Get-CimInstance Win32_OperatingSystem
    $BIOS = Get-CimInstance Win32_BIOS
    $CPU = Get-CimInstance Win32_Processor |
        Select-Object -First 1

    $MemoryGB = [math]::Round(
        $Computer.TotalPhysicalMemory / 1GB,
        2
    )

    $Uptime = (Get-Date) - $OS.LastBootUpTime

    $DiskInfo = Get-CimInstance Win32_LogicalDisk `
        -Filter "DriveType=3" |
        ForEach-Object {

            $TotalGB = [math]::Round(
                $_.Size / 1GB,
                2
            )

            $FreeGB = [math]::Round(
                $_.FreeSpace / 1GB,
                2
            )

            [PSCustomObject]@{
                Drive      = $_.DeviceID
                TotalGB    = $TotalGB
                FreeGB     = $FreeGB
                FreePercent = if ($_.Size -gt 0) {
                    [math]::Round(
                        ($_.FreeSpace / $_.Size) * 100,
                        1
                    )
                }
                else {
                    0
                }
            }
        }

    return [PSCustomObject]@{
        ComputerName = $Computer.Name
        Manufacturer = $Computer.Manufacturer
        Model        = $Computer.Model
        OperatingSystem = $OS.Caption
        OSVersion    = $OS.Version
        Architecture = $OS.OSArchitecture
        CPU          = $CPU.Name
        Cores        = $CPU.NumberOfCores
        LogicalProcessors = $CPU.NumberOfLogicalProcessors
        MemoryGB     = $MemoryGB
        BIOSVersion  = $BIOS.SMBIOSBIOSVersion
        LastBoot     = $OS.LastBootUpTime
        Uptime       = "{0} days, {1} hours, {2} minutes" -f `
            $Uptime.Days,
            $Uptime.Hours,
            $Uptime.Minutes
        Disks        = $DiskInfo
    }
}

# ------------------------------------------------------------
# Create main form
# ------------------------------------------------------------

$Form = New-Object System.Windows.Forms.Form

$Form.Text = "System Information Tool"
$Form.Size = New-Object System.Drawing.Size(850, 650)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# ------------------------------------------------------------
# Title
# ------------------------------------------------------------

$TitleLabel = New-Object System.Windows.Forms.Label

$TitleLabel.Text = "Windows System Information"
$TitleLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    18,
    [System.Drawing.FontStyle]::Bold
)

$TitleLabel.AutoSize = $true
$TitleLabel.Location = New-Object System.Drawing.Point(25, 20)

$Form.Controls.Add($TitleLabel)

# ------------------------------------------------------------
# System information display
# ------------------------------------------------------------

$InfoBox = New-Object System.Windows.Forms.TextBox

$InfoBox.Location = New-Object System.Drawing.Point(25, 65)
$InfoBox.Size = New-Object System.Drawing.Size(790, 380)

$InfoBox.Multiline = $true
$InfoBox.ScrollBars = "Vertical"
$InfoBox.ReadOnly = $true

$InfoBox.Font = New-Object System.Drawing.Font(
    "Consolas",
    10
)

$Form.Controls.Add($InfoBox)

# ------------------------------------------------------------
# Status label
# ------------------------------------------------------------

$StatusLabel = New-Object System.Windows.Forms.Label

$StatusLabel.Text = "Status: Ready"
$StatusLabel.AutoSize = $true

$StatusLabel.Location = New-Object System.Drawing.Point(25, 465)

$Form.Controls.Add($StatusLabel)

# ------------------------------------------------------------
# Refresh button
# ------------------------------------------------------------

$RefreshButton = New-Object System.Windows.Forms.Button

$RefreshButton.Text = "Refresh"
$RefreshButton.Size = New-Object System.Drawing.Size(120, 40)
$RefreshButton.Location = New-Object System.Drawing.Point(25, 500)

$Form.Controls.Add($RefreshButton)

# ------------------------------------------------------------
# Export button
# ------------------------------------------------------------

$ExportButton = New-Object System.Windows.Forms.Button

$ExportButton.Text = "Export Report"
$ExportButton.Size = New-Object System.Drawing.Size(120, 40)
$ExportButton.Location = New-Object System.Drawing.Point(160, 500)

$Form.Controls.Add($ExportButton)

# ------------------------------------------------------------
# Close button
# ------------------------------------------------------------

$CloseButton = New-Object System.Windows.Forms.Button

$CloseButton.Text = "Close"
$CloseButton.Size = New-Object System.Drawing.Size(120, 40)
$CloseButton.Location = New-Object System.Drawing.Point(295, 500)

$Form.Controls.Add($CloseButton)

# ------------------------------------------------------------
# Function to display information
# ------------------------------------------------------------

function Update-SystemInformation {

    try {

        $StatusLabel.Text = "Status: Collecting information..."

        $Info = Get-SystemInformation

        $Output = @"

========================================
       WINDOWS SYSTEM INFORMATION
========================================

COMPUTER
----------------------------------------
Computer Name       : $($Info.ComputerName)
Manufacturer        : $($Info.Manufacturer)
Model               : $($Info.Model)

OPERATING SYSTEM
----------------------------------------
Operating System    : $($Info.OperatingSystem)
Version             : $($Info.OSVersion)
Architecture        : $($Info.Architecture)

PROCESSOR
----------------------------------------
CPU                 : $($Info.CPU)
CPU Cores           : $($Info.Cores)
Logical Processors  : $($Info.LogicalProcessors)

MEMORY
----------------------------------------
Total Memory        : $($Info.MemoryGB) GB

BIOS
----------------------------------------
BIOS Version        : $($Info.BIOSVersion)

SYSTEM
----------------------------------------
Last Boot           : $($Info.LastBoot)
Uptime              : $($Info.Uptime)

DISKS
----------------------------------------
"@

        foreach ($Disk in $Info.Disks) {

            $Output += @"

Drive               : $($Disk.Drive)
Total Space         : $($Disk.TotalGB) GB
Free Space          : $($Disk.FreeGB) GB
Free Percentage     : $($Disk.FreePercent)%

"@
        }

        $Output += @"
========================================
"@

        $InfoBox.Text = $Output

        $StatusLabel.Text = "Status: Information updated"

    }
    catch {

        $StatusLabel.Text = "Status: Error"

        [System.Windows.Forms.MessageBox]::Show(
            "Unable to retrieve system information.`n`n$($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# ------------------------------------------------------------
# Refresh button event
# ------------------------------------------------------------

$RefreshButton.Add_Click({

    Update-SystemInformation

})

# ------------------------------------------------------------
# Export button event
# ------------------------------------------------------------

$ExportButton.Add_Click({

    try {

        $SaveDialog = New-Object System.Windows.Forms.SaveFileDialog

        $SaveDialog.Title = "Save System Information"
        $SaveDialog.Filter = "Text Files (*.txt)|*.txt"
        $SaveDialog.FileName = "System-Information-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"

        if ($SaveDialog.ShowDialog() -eq "OK") {

            $InfoBox.Text |
                Out-File `
                    -FilePath $SaveDialog.FileName `
                    -Encoding utf8

            [System.Windows.Forms.MessageBox]::Show(
                "Report exported successfully.`n`n$($SaveDialog.FileName)",
                "Export Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            $StatusLabel.Text = "Status: Report exported"
        }
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            "Export failed.`n`n$($_.Exception.Message)",
            "Export Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# ------------------------------------------------------------
# Close button event
# ------------------------------------------------------------

$CloseButton.Add_Click({

    $Form.Close()

})

# ------------------------------------------------------------
# Load information when application starts
# ------------------------------------------------------------

$Form.Add_Shown({

    Update-SystemInformation

})

# ------------------------------------------------------------
# Start GUI
# ------------------------------------------------------------

[System.Windows.Forms.Application]::Run($Form)