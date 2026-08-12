<#
    Shared Folder Inventory
    -----------------------
    This script displays shared folders available on the
    current computer.

    Main concept:
    - SMB shares

    Cross-platform support:
    - Windows: Uses Get-SmbShare
    - Linux: Uses the "smbclient" command when available
    - macOS: Uses the "smbutil" command when available

    The script only inventories shares.
    It does NOT create, modify, or remove shares.

    Requires:
    - PowerShell 7+
#>

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Shared Folder Inventory"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Detect the operating system
# -------------------------------------------------------

if ($IsWindows) {

    # ===================================================
    # WINDOWS
    # ===================================================

    Write-Host "Operating System: Windows"
    Write-Host "Searching for SMB shares..."
    Write-Host ""

    try {

        # Get SMB shares configured on this computer.
        $shares = Get-SmbShare -ErrorAction Stop

        if ($shares.Count -eq 0) {

            Write-Host "No SMB shares were found."

        }
        else {

            foreach ($share in $shares) {

                Write-Host "-------------------------------------------"
                Write-Host "Name       : $($share.Name)"
                Write-Host "Path       : $($share.Path)"
                Write-Host "Description: $($share.Description)"
                Write-Host "Type       : $($share.ShareType)"
                Write-Host ""

            }

        }

        Write-Host "==========================================="
        Write-Host " Summary"
        Write-Host "==========================================="
        Write-Host "Shares Found: $($shares.Count)"
        Write-Host ""

    }
    catch {

        Write-Host "Unable to retrieve SMB shares."
        Write-Host $_.Exception.Message
    }

}
elseif ($IsLinux) {

    # ===================================================
    # LINUX
    # ===================================================

    Write-Host "Operating System: Linux"
    Write-Host ""

    # ---------------------------------------------------
    # Check whether smbclient is installed
    # ---------------------------------------------------

    $smbClient = Get-Command `
        smbclient `
        -ErrorAction SilentlyContinue

    if ($null -eq $smbClient) {

        Write-Host "The 'smbclient' command was not found."
        Write-Host ""
        Write-Host "In a Debian/Ubuntu Codespace, you can install it with:"
        Write-Host ""
        Write-Host "sudo apt update"
        Write-Host "sudo apt install smbclient"
        Write-Host ""

        exit
    }

    Write-Host "SMB client found."
    Write-Host ""
    Write-Host "To discover SMB shares on a remote server,"
    Write-Host "provide the server name or IP address."
    Write-Host ""

    $server = Read-Host "Enter SMB server name or IP address"

    # ---------------------------------------------------
    # Validate input
    # ---------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($server)) {

        Write-Host ""
        Write-Host "No server was specified."
        exit
    }

    # ---------------------------------------------------
    # Query the SMB server
    # ---------------------------------------------------

    Write-Host ""
    Write-Host "Querying SMB server: $server"
    Write-Host ""

    try {

        # -L lists the shares available on the server.
        # -N attempts the query without asking for a password.
        smbclient -L $server -N

    }
    catch {

        Write-Host ""
        Write-Host "Unable to query the SMB server."
        Write-Host $_.Exception.Message
    }

}
elseif ($IsMacOS) {

    # ===================================================
    # MACOS
    # ===================================================

    Write-Host "Operating System: macOS"
    Write-Host ""

    # macOS includes smbutil for SMB-related operations.
    $smbUtil = Get-Command `
        smbutil `
        -ErrorAction SilentlyContinue

    if ($null -eq $smbUtil) {

        Write-Host "The 'smbutil' command was not found."
        exit
    }

    Write-Host "SMB utility found."
    Write-Host ""

    $server = Read-Host "Enter SMB server name or IP address"

    if ([string]::IsNullOrWhiteSpace($server)) {

        Write-Host ""
        Write-Host "No server was specified."
        exit
    }

    Write-Host ""
    Write-Host "Querying SMB server: $server"
    Write-Host ""

    # Display SMB information for the specified server.
    smbutil view "//$server"

}
else {

    # ---------------------------------------------------
    # Unsupported operating system
    # ---------------------------------------------------

    Write-Host "Unsupported operating system."
    Write-Host ""
}
