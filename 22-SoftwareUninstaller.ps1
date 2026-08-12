<#
    Software Uninstaller
    --------------------
    This script searches the Windows Registry for an installed
    application and displays its uninstall command.

    The user can then choose whether to run the uninstall command.

    Main concepts:
    - Windows Registry
    - Uninstall commands
    - User input
    - Conditional logic
    - Process execution

    Requires:
    - PowerShell 7+
    - Windows
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# The Registry uninstall locations used by this script
# only exist on Windows.
if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Software Uninstaller"
    Write-Host "==========================================="
    Write-Host ""

    Write-Host "This script requires Windows."
    Write-Host "Windows Registry uninstall entries are not"
    Write-Host "available on Linux or macOS."

    Write-Host ""
    exit
}

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Software Uninstaller"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Ask the user for the software name
# -------------------------------------------------------

$softwareName = Read-Host "Enter the name of the software to find"

# Check whether the user entered anything.
if ([string]::IsNullOrWhiteSpace($softwareName)) {

    Write-Host ""
    Write-Host "No software name was entered."
    exit
}

# -------------------------------------------------------
# Registry locations containing uninstall information
# -------------------------------------------------------

$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Store matching applications here.
$matches = @()

# -------------------------------------------------------
# Search the Registry
# -------------------------------------------------------

foreach ($path in $registryPaths) {

    # Check whether the Registry path exists.
    if (-not (Test-Path $path)) {
        continue
    }

    # Get each application's Registry entry.
    $applications = Get-ChildItem `
        -Path $path `
        -ErrorAction SilentlyContinue

    foreach ($application in $applications) {

        try {

            # Read the application's Registry properties.
            $properties = Get-ItemProperty `
                -Path $application.PSPath `
                -ErrorAction Stop

            # Ignore entries without a display name.
            if ([string]::IsNullOrWhiteSpace(
                $properties.DisplayName
            )) {
                continue
            }

            # Check whether the application name contains
            # the text entered by the user.
            if ($properties.DisplayName -like "*$softwareName*") {

                $matches += [PSCustomObject]@{
                    Name             = $properties.DisplayName
                    Version          = $properties.DisplayVersion
                    Publisher        = $properties.Publisher
                    UninstallCommand = $properties.UninstallString
                }

            }

        }
        catch {

            # Some Registry entries may not be accessible.
            continue
        }
    }
}

# -------------------------------------------------------
# Check whether a match was found
# -------------------------------------------------------

if ($matches.Count -eq 0) {

    Write-Host ""
    Write-Host "No matching software was found."
    exit
}

# -------------------------------------------------------
# Display matching software
# -------------------------------------------------------

Write-Host ""
Write-Host "Software Found:"
Write-Host ""

for ($i = 0; $i -lt $matches.Count; $i++) {

    Write-Host "[$($i + 1)] $($matches[$i].Name)"
    Write-Host "    Version  : $($matches[$i].Version)"
    Write-Host "    Publisher: $($matches[$i].Publisher)"
    Write-Host ""

}

# -------------------------------------------------------
# Select an application
# -------------------------------------------------------

if ($matches.Count -eq 1) {

    $selectedIndex = 0

}
else {

    $selection = Read-Host "Enter the number of the application to uninstall"

    # Make sure the input is a valid number.
    if (-not [int]::TryParse($selection, [ref]$selectedNumber)) {

        Write-Host "Invalid selection."
        exit
    }

    # Convert the user's number to an array index.
    $selectedIndex = $selectedNumber - 1

    # Make sure the selected number is within range.
    if ($selectedIndex -lt 0 -or
        $selectedIndex -ge $matches.Count) {

        Write-Host "Selection is out of range."
        exit
    }
}

# Get the selected application.
$selectedSoftware = $matches[$selectedIndex]

# -------------------------------------------------------
# Display uninstall information
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Selected Software"
Write-Host "==========================================="
Write-Host "Name   : $($selectedSoftware.Name)"
Write-Host "Version: $($selectedSoftware.Version)"
Write-Host ""

if ([string]::IsNullOrWhiteSpace(
    $selectedSoftware.UninstallCommand
)) {

    Write-Host "No uninstall command was found."
    exit
}

Write-Host "Uninstall command:"
Write-Host $selectedSoftware.UninstallCommand
Write-Host ""

# -------------------------------------------------------
# Ask for confirmation
# -------------------------------------------------------

$confirmation = Read-Host "Do you want to run this command? (Y/N)"

if ($confirmation -notmatch "^[Yy]$") {

    Write-Host ""
    Write-Host "Uninstallation cancelled."
    exit
}

# -------------------------------------------------------
# Execute the uninstall command
# -------------------------------------------------------

try {

    Write-Host ""
    Write-Host "Starting uninstaller..."
    Write-Host ""

    # Start the uninstall command.
    #
    # The uninstall command comes from the Registry.
    # We do not automatically modify or construct it.
    Start-Process `
        -FilePath "cmd.exe" `
        -ArgumentList "/c", $selectedSoftware.UninstallCommand `
        -Wait `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "Uninstaller completed."

}
catch {

    Write-Host ""
    Write-Host "Unable to start the uninstaller."
    Write-Host $_.Exception.Message
}

# -------------------------------------------------------
# Final message
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Operation Complete"
Write-Host "==========================================="
Write-Host ""
