# LAB7 - DC01: IP tinh 10.6.0.10, cai AD DS + DNS, tao forest lab6.test
# Chay: PowerShell (Run as Administrator). May TU KHOI DONG LAI khi tao forest xong.
$ErrorActionPreference = 'Stop'

Write-Host '== 1. IP tinh 10.6.0.10/24, GW 10.6.0.1, DNS 127.0.0.1 ==' -ForegroundColor Cyan
$N = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
Get-NetIPAddress -InterfaceAlias $N -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $N -DestinationPrefix '0.0.0.0/0' -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias $N -IPAddress 10.6.0.10 -PrefixLength 24 -DefaultGateway 10.6.0.1 | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $N -ServerAddresses 127.0.0.1

Write-Host '== 2. Cho phep ping DC01 ==' -ForegroundColor Cyan
Get-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In*' | Enable-NetFirewallRule
ipconfig | Select-String 'IPv4|Subnet|Gateway'
Test-Connection 10.6.0.1 -Count 2 | Format-Table -AutoSize

Write-Host '== 3. Cai AD DS + DNS ==' -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools | Format-Table -AutoSize

Write-Host '== 4. Tao forest lab6.test (may se tu khoi dong lai) ==' -ForegroundColor Cyan
Install-ADDSForest -DomainName 'lab6.test' -DomainNetbiosName 'LAB6' -InstallDns `
  -SafeModeAdministratorPassword (ConvertTo-SecureString 'Lab7@Dsrm2026' -AsPlainText -Force) -Force
