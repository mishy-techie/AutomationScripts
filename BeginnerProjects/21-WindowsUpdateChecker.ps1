<#
    Windows Update Checker
    ----------------------
    This script checks Windows Update for available updates.

    Main concept:
    - Windows Update APIs

    Features:
    - Detects the operating system
    - Connects to the Windows Update API
    - Searches for available updates
    - Displays update titles
    - Displays a summary

    Requires:
    - PowerShell 7+
    - Windows
#>

# -------------------------------------------------------
# Check the operating system
# -------------------------------------------------------

# Windows Update APIs are only available on Windows.
if (-not $IsWindows) {

    Write-Host ""
    Write-Host "==========================================="
    Write-Host " Windows Update Checker"
    Write-Host "==========================================="
    Write-Host ""

    Write-Host "This script requires Windows."
    Write-Host "Windows Update APIs are not available on"
    Write-Host "Linux or macOS."

    Write-Host ""
    exit
}

# -------------------------------------------------------
# Display the program title
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Windows Update Checker"
Write-Host "==========================================="
Write-Host ""

Write-Host "Connecting to Windows Update..."
Write-Host ""

# -------------------------------------------------------
# Create the Windows Update API objects
# -------------------------------------------------------

try {

    # Create a Windows Update session.
    #
    # Microsoft provides this COM API for applications
    # that need to communicate with Windows Update.
    $updateSession = New-Object -ComObject Microsoft.Update.Session

    # Create an update searcher.
    $updateSearcher = $updateSession.CreateUpdateSearcher()

}
catch {

    Write-Host "Unable to connect to Windows Update."
    Write-Host $_.Exception.Message

    exit
}

# -------------------------------------------------------
# Search for available updates
# -------------------------------------------------------

try {

    Write-Host "Searching for available updates..."
    Write-Host ""

    # Search for updates that:
    #
    # - Are not installed
    # - Are not hidden
    #
    $searchResult = $updateSearcher.Search(
        "IsInstalled=0 AND IsHidden=0"
    )

}
catch {

    Write-Host "Windows Update search failed."
    Write-Host $_.Exception.Message

    exit
}

# -------------------------------------------------------
# Display the results
# -------------------------------------------------------

$updateCount = $searchResult.Updates.Count

if ($updateCount -eq 0) {

    Write-Host "Your computer is up to date."

}
else {

    Write-Host "Available Updates: $updateCount"
    Write-Host ""

    # ---------------------------------------------------
    # Display each available update
    # ---------------------------------------------------

    foreach ($update in $searchResult.Updates) {

        Write-Host "-------------------------------------------"

        Write-Host "Title:"
        Write-Host $update.Title

        # Some updates have a KB article number.
        # Display it when available.
        if ($update.KBArticleIDs.Count -gt 0) {

            Write-Host ""
            Write-Host "KB Article(s):"

            foreach ($kb in $update.KBArticleIDs) {

                Write-Host "KB$kb"

            }
        }

        Write-Host ""

    }
}

# -------------------------------------------------------
# Display summary
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Summary"
Write-Host "==========================================="
Write-Host "Updates Available: $updateCount"
Write-Host ""
