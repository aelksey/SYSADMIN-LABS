# Part I.

$computerName = (Get-WmiObject -Query "SELECT Name FROM Win32_ComputerSystem").Name
$users = Get-WmiObject -Query "SELECT Name FROM Win32_UserAccount"
$networkAdapters = Get-WmiObject -Query "SELECT Name, MACAddress FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL"

Write-Host "Computer name:"
Write-Host $computerName
Write-Host ""

Write-Host "List of users:"
$users | ForEach-Object {
    Write-Host $_.Name
}
Write-Host ""

Write-Host "Network cards and MAC addresses:"
$networkAdapters | ForEach-Object {
    Write-Host "$($_.Name) - $($_.MACAddress)"
}

# Part II.

$startupPrograms = Get-WmiObject -Query "SELECT Name, Command, Location FROM Win32_StartupCommand"

# Part III.

$reportDir = "C:\SysAdmLab2"
$reportFile = Join-Path $reportDir "$computerName.rep"
$fileContent = @(
    "[users]"
    ($users | ForEach-Object { $_.Name })
    ""
    "[network]"
    ($networkAdapters | ForEach-Object { "$($_.Name), $($_.MACAddress)" })
    ""
    "[startup]"
    ($startupPrograms | ForEach-Object { "Name: $($_.Name), Command: $($_.Command), Location: $($_.Location)" })
)

$fileContent | Out-File -FilePath $reportFile -Encoding utf8

Write-Host ""
Write-Host "Data saved to file:"
Write-Host $reportFile