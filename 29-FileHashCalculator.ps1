<#
    File Hash Calculator
    ---------------------
    Calculates a cryptographic hash for a selected file.

    Main concept:
    - Cryptographic hashing

    Features:
    - Cross-platform
    - Supports SHA256, SHA384, SHA512, SHA1, and MD5
    - Validates the file path
    - Allows the user to select a hashing algorithm
    - Displays the calculated hash

    Requires:
    - PowerShell 7+
#>

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " File Hash Calculator"
Write-Host "==========================================="
Write-Host ""

# -------------------------------------------------------
# Ask for the file path
# -------------------------------------------------------

$filePath = Read-Host "Enter the path to the file"

# Check whether the user entered a path.
if ([string]::IsNullOrWhiteSpace($filePath)) {

    Write-Host ""
    Write-Host "No file path was entered."
    exit
}

# -------------------------------------------------------
# Validate the file
# -------------------------------------------------------

if (-not (Test-Path -Path $filePath -PathType Leaf)) {

    Write-Host ""
    Write-Host "The specified file does not exist."
    exit
}

# Convert the path to its full/absolute path.
$resolvedPath = (Resolve-Path $filePath).Path

Write-Host ""
Write-Host "File:"
Write-Host $resolvedPath
Write-Host ""

# -------------------------------------------------------
# Select hashing algorithm
# -------------------------------------------------------

Write-Host "Available hashing algorithms:"
Write-Host ""
Write-Host "1. SHA256"
Write-Host "2. SHA384"
Write-Host "3. SHA512"
Write-Host "4. SHA1"
Write-Host "5. MD5"
Write-Host ""

$algorithmChoice = Read-Host "Choose an algorithm"

# -------------------------------------------------------
# Convert selection into an algorithm name
# -------------------------------------------------------

switch ($algorithmChoice) {

    "1" {
        $algorithm = "SHA256"
    }

    "2" {
        $algorithm = "SHA384"
    }

    "3" {
        $algorithm = "SHA512"
    }

    "4" {
        $algorithm = "SHA1"
    }

    "5" {
        $algorithm = "MD5"
    }

    default {

        Write-Host ""
        Write-Host "Invalid selection."
        exit
    }
}

# -------------------------------------------------------
# Calculate the hash
# -------------------------------------------------------

try {

    # Get-FileHash reads the file and calculates the
    # selected cryptographic hash.
    $hashResult = Get-FileHash `
        -Path $resolvedPath `
        -Algorithm $algorithm `
        -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "Unable to calculate the file hash."
    Write-Host $_.Exception.Message
    exit
}

# -------------------------------------------------------
# Display the result
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Hash Result"
Write-Host "==========================================="
Write-Host ""

Write-Host "File:"
Write-Host $hashResult.Path

Write-Host ""
Write-Host "Algorithm:"
Write-Host $hashResult.Algorithm

Write-Host ""
Write-Host "Hash:"
Write-Host $hashResult.Hash

Write-Host ""
