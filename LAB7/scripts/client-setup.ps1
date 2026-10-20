# LAB7 - Client-A/B: IP tinh, GW pfSense LAN, DNS DC01
# Chay: PowerShell (Run as Administrator):  client-setup.ps1 -Ip 10.6.0.21
param([Parameter(Mandatory)][string]$Ip)
$ErrorActionPreference = 'Stop'
Write-Host "== 1. IP $Ip/24, GW 10.6.0.1, DNS 10.6.0.10 ==" -ForegroundColor Cyan
$N = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
Set-NetConnectionProfile -InterfaceAlias $N -NetworkCategory Private -ErrorAction SilentlyContinue
Get-NetIPAddress -InterfaceAlias $N -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $N -DestinationPrefix '0.0.0.0/0' -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias $N -IPAddress $Ip -PrefixLength 24 -DefaultGateway 10.6.0.1 | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $N -ServerAddresses 10.6.0.10
Write-Host '== 2. Cho phep ping ==' -ForegroundColor Cyan
Get-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In*' | Enable-NetFirewallRule
Write-Host '== 3. Bat tai khoan Administrator (quan tri tu xa qua Guest Additions) ==' -ForegroundColor Cyan
net user Administrator 'Lab7@2026' /active:yes
reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v FilterAdministratorToken /t REG_DWORD /d 0 /f | Out-Null
Start-Sleep 3
ipconfig /all | Select-String 'Host Name|IPv4|Subnet|Gateway|DNS Servers'
Test-Connection 10.6.0.1 -Count 2 | Format-Table -AutoSize
