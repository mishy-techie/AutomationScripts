# ============================================
# Project 6 - Ping Test Tool
# ============================================

Clear-Host

Write-Host "==========================================="
Write-Host "             PING TEST TOOL"
Write-Host "==========================================="
Write-Host ""

$Target = Read-Host "Enter hostname or IP address"

try {

    $Result = Test-Connection `
        -TargetName $Target `
        -Count 4 `
        -ErrorAction Stop

    $Average = ($Result | Measure-Object ResponseTime -Average).Average

    Write-Host ""
    Write-Host "Target        : $Target"
    Write-Host "Status        : SUCCESS ✅"
    Write-Host "Packets Sent  : $($Result.Count)"
    Write-Host "Average Time  : $([math]::Round($Average,2)) ms"

}
catch {

    Write-Host ""
    Write-Host "Target        : $Target"
    Write-Host "Status        : FAILED ❌"
    Write-Host "Reason        : Host unreachable"

}

Write-Host ""
Write-Host "Date          : $(Get-Date -Format 'dd MMM yyyy')"
Write-Host "Time          : $(Get-Date -Format 'HH:mm:ss')"

Write-Host ""
Write-Host "==========================================="