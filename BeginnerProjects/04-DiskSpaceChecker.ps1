# =====================================
# Project 4 - Disk Space Checker
# =====================================

Clear-Host

Write-Host "======================================="
Write-Host "         DISK SPACE CHECKER"
Write-Host "======================================="
Write-Host ""

$drive = Get-PSDrive -PSProvider FileSystem | Select-Object -First 1

$total = $drive.Used + $drive.Free
$used = $drive.Used
$free = $drive.Free

$totalGB = [math]::Round($total / 1GB, 2)
$usedGB = [math]::Round($used / 1GB, 2)
$freeGB = [math]::Round($free / 1GB, 2)

$usedPercent = [math]::Round(($used / $total) * 100, 2)
$freePercent = [math]::Round(($free / $total) * 100, 2)

if ($freePercent -lt 10) {
    $status = "CRITICAL"
}
elseif ($freePercent -lt 20) {
    $status = "WARNING"
}
else {
    $status = "HEALTHY"
}

Write-Host "Drive          : $($drive.Name)"
Write-Host "Total Space    : $totalGB GB"
Write-Host "Used Space     : $usedGB GB"
Write-Host "Free Space     : $freeGB GB"
Write-Host "Used           : $usedPercent%"
Write-Host "Free           : $freePercent%"
Write-Host "Status         : $status"

Write-Host ""
Write-Host "======================================="

# A Disk Space Checker is something technicians use frequently to identify low-storage issues on user computers and servers.