# ============================================
# Project 5 - RAM & CPU Usage Monitor
# ============================================

Clear-Host

Write-Host "==========================================="
Write-Host "         RAM & CPU USAGE MONITOR"
Write-Host "==========================================="
Write-Host ""

# Computer Name
$ComputerName = [System.Environment]::MachineName

# ---------- RAM ----------
$memInfo = Get-Content "/proc/meminfo"

$totalMemKB = (($memInfo | Select-String "^MemTotal").ToString() -split "\s+")[1]
$freeMemKB = (($memInfo | Select-String "^MemAvailable").ToString() -split "\s+")[1]

$totalGB = [math]::Round($totalMemKB / 1MB,2)
$freeGB = [math]::Round($freeMemKB / 1MB,2)
$usedGB = [math]::Round($totalGB - $freeGB,2)

$usedPercent = [math]::Round(($usedGB / $totalGB) * 100,2)

# ---------- CPU ----------
$load = (Get-Content "/proc/loadavg").Split(" ")[0]

# ---------- Health ----------
if($usedPercent -ge 90){
    $status = "CRITICAL"
}
elseif($usedPercent -ge 75){
    $status = "WARNING"
}
else{
    $status = "HEALTHY"
}

Write-Host "Computer Name : $ComputerName"
Write-Host ""
Write-Host "CPU Load      : $load"
Write-Host ""
Write-Host "Total RAM     : $totalGB GB"
Write-Host "Used RAM      : $usedGB GB"
Write-Host "Free RAM      : $freeGB GB"
Write-Host "RAM Usage     : $usedPercent%"
Write-Host ""
Write-Host "Status        : $status"

Write-Host ""
Write-Host "==========================================="