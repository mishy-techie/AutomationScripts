# ============================================
# Public IP Checker (PowerShell)
# ============================================
# This script sends an HTTP request to a public
# IP service and displays your current public IP.
#
# Skills practiced:
# - Web requests
# - Variables
# - Functions
# - Error handling
# ============================================

# Function to retrieve the public IP
function Get-PublicIP {

    try {
        # Send a GET request to the API.
        # The response is plain text containing your IP address.
        $ip = Invoke-RestMethod -Uri "https://api.ipify.org"

        return $ip
    }
    catch {
        Write-Host "Unable to retrieve your public IP."
        Write-Host $_.Exception.Message
        return $null
    }
}

# Main Program

Write-Host "Checking your public IP..."
Write-Host ""

$publicIP = Get-PublicIP

if ($publicIP) {
    Write-Host "Your Public IP Address:"
    Write-Host $publicIP
}