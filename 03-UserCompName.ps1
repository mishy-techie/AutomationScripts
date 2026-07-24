# Display the computer name and the currently logged-in user

$ComputerName = [System.Environment]::MachineName
$CurrentUser = [System.Environment]::UserName

Write-Host "Computer Name: $ComputerName"
Write-Host "Logged-in User: $CurrentUser"