LAB 9 - LOCAL DNS ATTACK - STUDENT RESOURCES

Pham vi: chi su dung mang ao DNS-LAB 10.9.0.0/24 va cac may ao cua chinh sinh vien.
Khong su dung script tren mang that, Wi-Fi truong, Internet hay he thong cua nguoi khac.

LAB 9 ke thua pfSense WAN/DMZ/MGMT tu LAB 8 va chi bo sung OPT2 = DNSLAB 10.9.0.1/24.
LAN-DOMAIN 10.6.0.0/24 khong tham gia bai tan cong.

Thanh phan:
- DNS-SERVER Ubuntu Server 24.04: 10.9.0.10
- VICTIM Ubuntu 24.04: 10.9.0.100
- ATTACKER Kali: 10.9.0.200
- APP-TEST/AUTH-DNS ke thua LAB 8: 172.16.6.20
- DMZ-WEB ke thua LAB 7/8: 172.16.6.10

Script dns_spoof_lab9.py bi hard-code vao IP/domain cua LAB 9 de tranh su dung ngoai pham vi.
