# LAB5 - DC01: dat IP tinh, cai AD DS + DNS, tao forest vietnam.local (tu khoi dong lai)
$ErrorActionPreference = 'Stop'
Set-TimeZone -Id 'SE Asia Standard Time'
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
Rename-NetAdapter -Name $nic.Name -NewName 'LAN' -ErrorAction SilentlyContinue
Disable-NetAdapterBinding -Name 'LAN' -ComponentID ms_tcpip6
Get-NetIPAddress -InterfaceAlias 'LAN' -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false
Remove-NetRoute -InterfaceAlias 'LAN' -DestinationPrefix 0.0.0.0/0 -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias 'LAN' -IPAddress 10.0.0.2 -PrefixLength 8 -DefaultGateway 10.0.0.1 | Out-Null
Set-DnsClientServerAddress -InterfaceAlias 'LAN' -ServerAddresses 10.0.0.2
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools | Out-Null
Import-Module ADDSDeployment
Install-ADDSForest -DomainName 'vietnam.local' -DomainNetbiosName 'VIETNAM' `
  -SafeModeAdministratorPassword (ConvertTo-SecureString 'Lab5@Dsrm2026' -AsPlainText -Force) `
  -InstallDns -Force -NoRebootOnCompletion:$false
