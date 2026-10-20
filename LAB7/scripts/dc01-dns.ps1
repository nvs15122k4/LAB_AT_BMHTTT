# LAB7 - DC01: tao zone lab7.test (script de bai) + forwarder ve pfSense 10.6.0.1
Write-Host '== 1. Forwarder DNS -> pfSense 10.6.0.1 ==' -ForegroundColor Cyan
Set-DnsServerForwarder -IPAddress 10.6.0.1 -UseRootHint $false
Get-DnsServerForwarder | Format-Table IPAddress,UseRootHint -AutoSize
Write-Host '== 2. Add-LAB7-DNS.ps1 (13 ban ghi A -> 172.16.6.10) ==' -ForegroundColor Cyan
& C:\LAB7\Add-LAB7-DNS.ps1 | Format-Table HostName,RecordType,@{n='IP';e={$_.RecordData.IPv4Address}} -AutoSize
Write-Host '== 3. Kiem tra ==' -ForegroundColor Cyan
Resolve-DnsName normal.lab7.test -Server 10.6.0.10 | Format-Table Name,Type,IPAddress -AutoSize
Resolve-DnsName ubuntu.com -Server 10.6.0.10 -Type A | Select-Object -First 1 | Format-Table Name,IPAddress -AutoSize
