#requires -Version 7.0

<#
    Project: USB Device Audit
    Concept: Device Enumeration
    Language: PowerShell 7+

    Cross-platform support:
      Windows : Get-PnpDevice
      Linux   : lsusb
      macOS   : system_profiler
      Codespaces/Linux containers: lsusb when available

    Output:
      - Console table
      - JSON report
#>

$ErrorActionPreference = "Stop"

$ReportDirectory = Join-Path $PSScriptRoot "reports"
$ReportFile = Join-Path $ReportDirectory "usb-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "          USB DEVICE AUDIT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Devices = @()

# ------------------------------------------------------------
# Windows
# ------------------------------------------------------------

if ($IsWindows) {

    Write-Host "Operating system: Windows" -ForegroundColor Green
    Write-Host "Enumerating USB devices..." -ForegroundColor Yellow
    Write-Host ""

    if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {

        try {

            $PnpDevices = Get-PnpDevice -PresentOnly -ErrorAction Stop |
                Where-Object {
                    $_.InstanceId -like "USB\*" -or
                    $_.Class -eq "USB"
                }

            foreach ($Device in $PnpDevices) {

                $Devices += [PSCustomObject]@{
                    Name         = $Device.FriendlyName
                    Manufacturer = $Device.Manufacturer
                    Status       = $Device.Status
                    Class        = $Device.Class
                    InstanceId   = $Device.InstanceId
                    Source       = "Windows PnP"
                }
            }

        }
        catch {
            Write-Warning "Unable to enumerate Windows USB devices: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Get-PnpDevice is not available."
    }
}

# ------------------------------------------------------------
# Linux
# ------------------------------------------------------------

elseif ($IsLinux) {

    Write-Host "Operating system: Linux" -ForegroundColor Green
    Write-Host "Enumerating USB devices..." -ForegroundColor Yellow
    Write-Host ""

    if (Get-Command lsusb -ErrorAction SilentlyContinue) {

        try {

            $UsbOutput = & lsusb 2>$null

            foreach ($Line in $UsbOutput) {

                if ([string]::IsNullOrWhiteSpace($Line)) {
                    continue
                }

                $Bus = ""
                $DeviceNumber = ""
                $VendorId = ""
                $ProductId = ""
                $Description = $Line

                if ($Line -match '^Bus\s+(\d+)\s+Device\s+(\d+):\s+ID\s+([0-9a-fA-F]{4}):([0-9a-fA-F]{4})\s+(.+)$') {

                    $Bus = $Matches[1]
                    $DeviceNumber = $Matches[2]
                    $VendorId = $Matches[3]
                    $ProductId = $Matches[4]
                    $Description = $Matches[5]
                }

                $Devices += [PSCustomObject]@{
                    Name         = $Description
                    Manufacturer = ""
                    Status       = "Present"
                    Class        = "USB"
                    InstanceId   = "Bus $Bus / Device $DeviceNumber"
                    VendorId     = $VendorId
                    ProductId    = $ProductId
                    Source       = "Linux lsusb"
                }
            }

        }
        catch {
            Write-Warning "Unable to execute lsusb: $($_.Exception.Message)"
        }
    }
    else {

        Write-Warning "lsusb is not installed."

        Write-Host ""
        Write-Host "On Debian/Ubuntu-based systems you can install it with:" -ForegroundColor Yellow
        Write-Host "sudo apt install usbutils" -ForegroundColor Gray
    }
}

# ------------------------------------------------------------
# macOS
# ------------------------------------------------------------

elseif ($IsMacOS) {

    Write-Host "Operating system: macOS" -ForegroundColor Green
    Write-Host "Enumerating USB devices..." -ForegroundColor Yellow
    Write-Host ""

    if (Get-Command system_profiler -ErrorAction SilentlyContinue) {

        try {

            $UsbOutput = & system_profiler SPUSBDataType 2>$null

            $CurrentDevice = $null

            foreach ($Line in $UsbOutput) {

                if ([string]::IsNullOrWhiteSpace($Line)) {
                    continue
                }

                # Device names in system_profiler output generally
                # appear as indented entries followed by a colon.
                if ($Line -match '^\s{8}(.+):\s*$') {

                    if ($CurrentDevice) {
                        $Devices += $CurrentDevice
                    }

                    $CurrentDevice = [PSCustomObject]@{
                        Name         = $Matches[1].Trim()
                        Manufacturer = ""
                        Status       = "Present"
                        Class        = "USB"
                        InstanceId   = ""
                        Source       = "macOS system_profiler"
                    }
                }
                elseif ($CurrentDevice -and $Line -match '^\s+Manufacturer:\s*(.+)$') {
                    $CurrentDevice.Manufacturer = $Matches[1].Trim()
                }
                elseif ($CurrentDevice -and $Line -match '^\s+Product ID:\s*(.+)$') {
                    $CurrentDevice.ProductId = $Matches[1].Trim()
                }
                elseif ($CurrentDevice -and $Line -match '^\s+Vendor ID:\s*(.+)$') {
                    $CurrentDevice.VendorId = $Matches[1].Trim()
                }
            }

            if ($CurrentDevice) {
                $Devices += $CurrentDevice
            }
        }
        catch {
            Write-Warning "Unable to enumerate macOS USB devices: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "system_profiler is not available."
    }
}

# ------------------------------------------------------------
# Unknown operating system
# ------------------------------------------------------------

else {

    Write-Warning "Unsupported operating system."
}

# ------------------------------------------------------------
# Display results
# ------------------------------------------------------------

Write-Host ""
Write-Host "USB Devices Found: $($Devices.Count)" -ForegroundColor Cyan
Write-Host ""

if ($Devices.Count -gt 0) {

    $Devices |
        Select-Object Name, Manufacturer, Status, Class, InstanceId |
        Format-Table -AutoSize
}
else {

    Write-Host "No USB devices were detected." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Create summary
# ------------------------------------------------------------

$Summary = [PSCustomObject]@{
    ComputerName = [System.Environment]::MachineName
    OperatingSystem = if ($IsWindows) {
        "Windows"
    }
    elseif ($IsLinux) {
        "Linux"
    }
    elseif ($IsMacOS) {
        "macOS"
    }
    else {
        "Unknown"
    }

    AuditTime = Get-Date
    DeviceCount = $Devices.Count
    Devices = $Devices
}

# ------------------------------------------------------------
# Export JSON
# ------------------------------------------------------------

$Summary |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path $ReportFile -Encoding UTF8

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "USB AUDIT COMPLETE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Devices found : $($Devices.Count)"
Write-Host "Report        : $ReportFile"
Write-Host ""