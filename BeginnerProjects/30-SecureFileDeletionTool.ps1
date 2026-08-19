<#
    Secure File Deletion Tool
    --------------------------
    Demonstrates secure-deletion concepts by overwriting a file
    with cryptographically secure random data before deleting it.

    Main concept:
    - Secure deletion methods

    Cross-platform:
    - Windows
    - Linux
    - macOS

    IMPORTANT:
    Overwriting a file does NOT guarantee physical data destruction
    on SSDs, flash storage, copy-on-write filesystems, snapshots,
    backups, or cloud-synchronized storage.

    This project is intended for learning and basic file sanitization,
    not as a guarantee of forensic-grade data destruction.

    Requires:
    - PowerShell 7+
#>

# -------------------------------------------------------
# Display title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Secure File Deletion Tool"
Write-Host "==========================================="
Write-Host ""

Write-Host "WARNING:"
Write-Host "This tool permanently deletes files."
Write-Host ""
Write-Host "Overwriting does not guarantee physical destruction"
Write-Host "of data on SSDs, flash storage, snapshots, backups,"
Write-Host "or copy-on-write filesystems."
Write-Host ""

# -------------------------------------------------------
# Ask for the file path
# -------------------------------------------------------

$filePath = Read-Host "Enter the path of the file to delete"

# Check whether input was provided.
if ([string]::IsNullOrWhiteSpace($filePath)) {

    Write-Host ""
    Write-Host "No file path was provided."
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

# Get the full path.
$resolvedPath = (Resolve-Path $filePath).Path

# -------------------------------------------------------
# Get file information
# -------------------------------------------------------

try {

    $fileInfo = Get-Item -Path $resolvedPath -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "Unable to access the file."
    Write-Host $_.Exception.Message
    exit
}

# -------------------------------------------------------
# Display file information
# -------------------------------------------------------

Write-Host ""
Write-Host "-------------------------------------------"
Write-Host "File Information"
Write-Host "-------------------------------------------"
Write-Host "Path : $resolvedPath"
Write-Host "Size : $($fileInfo.Length) bytes"
Write-Host ""

# -------------------------------------------------------
# Require explicit confirmation
# -------------------------------------------------------

Write-Host "This operation cannot be easily undone."
Write-Host ""

$confirmation = Read-Host "Type DELETE to permanently delete this file"

if ($confirmation -cne "DELETE") {

    Write-Host ""
    Write-Host "Confirmation failed."
    Write-Host "File was NOT deleted."
    exit
}

# -------------------------------------------------------
# Handle empty files
# -------------------------------------------------------

if ($fileInfo.Length -eq 0) {

    Write-Host ""
    Write-Host "The file is empty."
    Write-Host "There is no file content to overwrite."

    try {

        Remove-Item `
            -LiteralPath $resolvedPath `
            -Force `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "File deleted successfully."

    }
    catch {

        Write-Host ""
        Write-Host "Unable to delete the file."
        Write-Host $_.Exception.Message
    }

    exit
}

# -------------------------------------------------------
# Overwrite the file
# -------------------------------------------------------

try {

    Write-Host ""
    Write-Host "Overwriting file contents..."
    Write-Host ""

    # Use the original file size so that we overwrite
    # the existing contents rather than changing the
    # file's intended size.
    $fileSize = $fileInfo.Length

    # Open the file for writing.
    $stream = [System.IO.File]::Open(
        $resolvedPath,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )

    try {

        # Process the file in chunks instead of loading
        # the entire file into memory.
        $bufferSize = 1MB

        # Create a reusable byte buffer.
        $buffer = New-Object byte[] $bufferSize

        # Create a cryptographically secure random
        # number generator.
        $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()

        try {

            $remaining = $fileSize

            while ($remaining -gt 0) {

                # Determine how many bytes to write during
                # this iteration.
                $bytesToWrite = [Math]::Min(
                    $bufferSize,
                    $remaining
                )

                # Fill the buffer with cryptographically
                # secure random bytes.
                $random.GetBytes(
                    $buffer,
                    0,
                    $bytesToWrite
                )

                # Write the random data to the file.
                $stream.Write(
                    $buffer,
                    0,
                    $bytesToWrite
                )

                $remaining -= $bytesToWrite
            }

            # Flush buffered data to the underlying stream.
            $stream.Flush()

        }
        finally {

            $random.Dispose()
        }

    }
    finally {

        $stream.Dispose()
    }

    Write-Host "Overwrite completed."

}
catch {

    Write-Host ""
    Write-Host "Unable to overwrite the file."
    Write-Host $_.Exception.Message

    Write-Host ""
    Write-Host "The file was NOT intentionally deleted."
    exit
}

# -------------------------------------------------------
# Delete the overwritten file
# -------------------------------------------------------

try {

    Remove-Item `
        -LiteralPath $resolvedPath `
        -Force `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "File deleted successfully."

}
catch {

    Write-Host ""
    Write-Host "The file was overwritten but could not be deleted."
    Write-Host $_.Exception.Message

    exit
}

# -------------------------------------------------------
# Verify deletion
# -------------------------------------------------------

if (-not (Test-Path -LiteralPath $resolvedPath)) {

    Write-Host ""
    Write-Host "Deletion verified."
    Write-Host ""

}
else {

    Write-Host ""
    Write-Host "Warning: The file still appears to exist."
    Write-Host ""
}
