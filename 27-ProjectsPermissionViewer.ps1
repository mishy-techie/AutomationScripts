<#
    Folder Permissions Viewer
    -------------------------
    This script displays permissions for a selected folder.

    Main concept:
    - NTFS permissions / filesystem permissions

    Cross-platform support:
    - Windows: Displays NTFS ACL information.
    - Linux/macOS: Displays the filesystem ACL information
      exposed through PowerShell.

    Features:
    - Accepts a folder path from the user
    - Checks whether the folder exists
    - Reads filesystem permissions using Get-Acl
    - Displays access rules
    - Shows the account, permissions, and access type

    Requires:
    - PowerShell 7+
#>

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Folder Permissions Viewer"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Detect the operating system
# -------------------------------------------------------

if ($IsWindows) {

    Write-Host "Operating System : Windows"
    Write-Host "Permission Model : NTFS / Windows ACL"

}
elseif ($IsLinux) {

    Write-Host "Operating System : Linux"
    Write-Host "Permission Model : POSIX / Linux filesystem ACL"

}
elseif ($IsMacOS) {

    Write-Host "Operating System : macOS"
    Write-Host "Permission Model : macOS filesystem permissions"

}
else {

    Write-Host "Operating System : Unknown"

}

Write-Host ""

# -------------------------------------------------------
# Ask for the folder path
# -------------------------------------------------------

$folderPath = Read-Host "Enter the folder path to inspect"

# -------------------------------------------------------
# Validate the path
# -------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($folderPath)) {

    Write-Host ""
    Write-Host "No folder path was entered."
    exit
}

if (-not (Test-Path -Path $folderPath -PathType Container)) {

    Write-Host ""
    Write-Host "The specified folder does not exist."
    exit
}

# -------------------------------------------------------
# Resolve the path
# -------------------------------------------------------

# Resolve-Path converts a relative path such as:
#
# ./Documents
#
# into its full filesystem path.
$resolvedPath = (Resolve-Path $folderPath).Path

Write-Host ""
Write-Host "Folder:"
Write-Host $resolvedPath
Write-Host ""

# -------------------------------------------------------
# Retrieve the Access Control List
# -------------------------------------------------------

try {

    # Get-Acl retrieves the security information associated
    # with the folder.
    $acl = Get-Acl -Path $resolvedPath -ErrorAction Stop

}
catch {

    Write-Host "Unable to read the folder permissions."
    Write-Host $_.Exception.Message
    exit
}

# -------------------------------------------------------
# Display owner
# -------------------------------------------------------

Write-Host "==========================================="
Write-Host " Folder Owner"
Write-Host "==========================================="

Write-Host $acl.Owner
Write-Host ""

# -------------------------------------------------------
# Display access rules
# -------------------------------------------------------

Write-Host "==========================================="
Write-Host " Access Rules"
Write-Host "==========================================="
Write-Host ""

foreach ($rule in $acl.Access) {

    Write-Host "-------------------------------------------"

    Write-Host "Identity       : $($rule.IdentityReference)"
    Write-Host "Access Type    : $($rule.AccessControlType)"
    Write-Host "Permissions    : $($rule.FileSystemRights)"

    # Inheritance determines whether the permission
    # is inherited from a parent folder.
    Write-Host "Inherited      : $($rule.IsInherited)"

    Write-Host ""

}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="

Write-Host "Folder         : $resolvedPath"
Write-Host "Owner          : $($acl.Owner)"
Write-Host "Access Rules   : $($acl.Access.Count)"

Write-Host ""
