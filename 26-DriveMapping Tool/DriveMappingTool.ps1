<#
    Drive Mapping Tool
    ------------------
    Maps and removes network drives.

    Main concepts:
    - Network drives
    - User input
    - Parameters
    - Conditional logic
    - Error handling

    Cross-platform notes:
    - Windows: Uses New-PSDrive for persistent drive mappings.
    - Linux/macOS: Network shares are mounted differently, so this
      script reports that drive-letter mapping is Windows-specific.
    - The accompanying .bat launcher is Windows-only.

    Requires:
    - PowerShell 7+
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

if (-not $IsWindows) {
    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Drive Mapping Tool"
    Write-Host "==========================================="
    Write-Host ""
    Write-Host "Drive-letter network mapping is Windows-specific."
    Write-Host "Use the PowerShell script on Windows for this project."
    Write-Host ""
    exit
}

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Drive Mapping Tool"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Display current mapped drives
# -------------------------------------------------------

Write-Host "Current mapped drives:"
Write-Host ""

try {
    Get-PSDrive -PSProvider FileSystem |
        Where-Object { $_.DisplayRoot -like "\\*" } |
        Select-Object Name, Root, DisplayRoot |
        Format-Table -AutoSize
}
catch {
    Write-Host "Unable to retrieve mapped drives."
    Write-Host $_.Exception.Message
}

Write-Host ""

# -------------------------------------------------------
# Select an operation
# -------------------------------------------------------

Write-Host "Choose an operation:"
Write-Host "1. Map a network drive"
Write-Host "2. Remove a mapped drive"
Write-Host "3. Exit"
Write-Host ""

$choice = Read-Host "Enter your choice"

# -------------------------------------------------------
# Map a network drive
# -------------------------------------------------------

if ($choice -eq "1") {

    Write-Host ""
    Write-Host "----- Map Network Drive -----"
    Write-Host ""

    # Ask the user for the drive letter.
    $driveLetter = Read-Host "Enter drive letter (example: Z)"

    # Remove a trailing colon if the user entered one.
    $driveLetter = $driveLetter.Trim().TrimEnd(":")

    # Convert the drive letter to uppercase.
    $driveLetter = $driveLetter.ToUpper()

    # Validate the drive letter.
    if ($driveLetter -notmatch "^[A-Z]$") {
        Write-Host "Invalid drive letter."
        exit
    }

    # Ask for the UNC network path.
    # Example: \\server\shared
    $networkPath = Read-Host "Enter network path (example: \\server\shared)"

    if ([string]::IsNullOrWhiteSpace($networkPath)) {
        Write-Host "A network path is required."
        exit
    }

    # Check whether the requested drive letter is already used.
    if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
        Write-Host "Drive $driveLetter`: is already in use."
        exit
    }

    try {

        # Create a persistent network drive mapping.
        #
        # -Persist makes the mapping visible as a Windows
        # network drive and attempts to retain it across logins.
        New-PSDrive `
            -Name $driveLetter `
            -PSProvider FileSystem `
            -Root $networkPath `
            -Persist `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "Drive mapped successfully."
        Write-Host "Drive : $driveLetter`:"
        Write-Host "Path  : $networkPath"

    }
    catch {

        Write-Host ""
        Write-Host "Unable to map the network drive."
        Write-Host $_.Exception.Message
    }
}

# -------------------------------------------------------
# Remove a mapped drive
# -------------------------------------------------------

elseif ($choice -eq "2") {

    Write-Host ""
    Write-Host "----- Remove Network Drive -----"
    Write-Host ""

    $driveLetter = Read-Host "Enter drive letter to remove"

    $driveLetter = $driveLetter.Trim().TrimEnd(":")
    $driveLetter = $driveLetter.ToUpper()

    # Validate the drive letter.
    if ($driveLetter -notmatch "^[A-Z]$") {
        Write-Host "Invalid drive letter."
        exit
    }

    # Check whether the drive exists.
    $drive = Get-PSDrive `
        -Name $driveLetter `
        -ErrorAction SilentlyContinue

    if ($null -eq $drive) {
        Write-Host "Drive $driveLetter`: was not found."
        exit
    }

    # Ask for confirmation before removing the mapping.
    $confirmation = Read-Host "Remove drive $driveLetter`: ? (Y/N)"

    if ($confirmation -notmatch "^[Yy]$") {
        Write-Host "Operation cancelled."
        exit
    }

    try {

        Remove-PSDrive `
            -Name $driveLetter `
            -Force `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "Drive $driveLetter`: removed successfully."

    }
    catch {

        Write-Host ""
        Write-Host "Unable to remove the network drive."
        Write-Host $_.Exception.Message
    }
}

# -------------------------------------------------------
# Exit
# -------------------------------------------------------

elseif ($choice -eq "3") {

    Write-Host ""
    Write-Host "Exiting..."
    exit
}

# -------------------------------------------------------
# Invalid selection
# -------------------------------------------------------

else {

    Write-Host ""
    Write-Host "Invalid choice."
}

Write-Host ""
