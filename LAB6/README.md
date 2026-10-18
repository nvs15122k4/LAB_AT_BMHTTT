# LAB6 – Xác thực Active Directory và chính sách truy cập trên pfSense

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 6 – Xác thực Active Directory và chính sách truy cập trên pfSense |
| **Ngày thực hành** | 18/10/2026 |
| **Báo cáo** | [`11DH_THMT-Lab6_1150080072-NguyenVanSang.docx`](11DH_THMT-Lab6_1150080072-NguyenVanSang.docx) |
| **Video** | _(không có)_ |
| **Mức độ hoàn thành** | Mục A, B.1 → B.4 và 12 câu hỏi; B.5 → H, K **chưa thực hiện** |

## Phiên bản môi trường

| Thành phần | Phiên bản |
|---|---|
| Máy thật (host) | Ubuntu 26.04.1 LTS (kernel 7.0.0-38-generic) (thay cho Windows) |
| Ảo hóa | Oracle VirtualBox 7.2.18 r175117, Host-Only `vboxnet0` 192.168.56.1/24 |
| pfSense-LAB6 | pfSense CE 2.7.2-RELEASE (amd64), 2 GB RAM, 2 vCPU — WAN DHCP `192.168.250.3`, MGMT `192.168.56.254`, LAN `10.6.0.1`, DMZ `172.16.6.1` |
| LAB6-DC01 | Windows Server 2025 Standard Evaluation, 4 GB RAM — `10.6.0.10`, domain `lab6.test` |
| Client-A / Client-B | _chưa tạo_ |
| LAB6-DMZ-WEB | _chưa tạo_ |

## Cách dựng môi trường

1. Mạng: `VBoxManage natnetwork add --netname LAB6-WAN --network 192.168.250.0/24 --enable --dhcp on`; `vboxnet0` 192.168.56.1/24 tắt DHCP; Internal `lab6-lan`, `lab6-dmz`.
2. pfSense-LAB6: 4 card Intel PRO/1000 (LAB6-WAN, vboxnet0, lab6-lan, lab6-dmz), cài ZFS; console option `1` gán em0/em2/em1/em3, option `2` đặt IP; `pfctl -d` tạm để tạo rule MGMT (HTTPS + ICMP từ 192.168.56.1), chạy Setup Wizard, đổi tên MGMT/DMZ, tắt DHCP; snapshot `pfSense-base`.
3. DC01: `VBoxManage unattended install` Windows Server 2025; `dc01-1-ip-promote.ps1` (IP tĩnh, AD DS + DNS, forest `lab6.test`), `dc01-2-users.ps1` (forwarder 10.6.0.1, OU LAB6-Users, sv_a, sv_b, svc_pfsense_ldap).

Chi tiết từng bước, ảnh và phân tích: xem báo cáo Word (trình bày theo bố cục `LAB6_pfSense_AD_Access_Policies_2026.pdf`).

## Các phần đã thực hiện và kết quả

| Phần | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| A. Tổng quan, topology | **PASS** | Topology riêng LAB6: WAN/MGMT/LAN/DMZ | Hình A.1 |
| B.1 Tạo mạng ảo | **PASS** | LAB6-WAN 192.168.250.0/24 DHCP Yes; vboxnet0 192.168.56.1/24 DHCP tắt. Chưa có ảnh Network Manager (ẢNH 01) | Output VBoxManage |
| B.2 4 card mạng pfSense | **PASS** | 4 adapter đúng mạng; MAC khớp em0–em3 trên Status → Interfaces. Chưa có ảnh Details VirtualBox (ẢNH 02) | Bảng MAC, Anh05 |
| B.3 IP interface pfSense | **PASS** | WAN DHCP 192.168.250.3, MGMT .56.254, LAN 10.6.0.1, DMZ 172.16.6.1; DHCP tắt; rule MGMT; wizard; giờ +07 | Anh03, 03a–03c, 04, 04a–04g, 05, 05b |
| B.4 Domain Controller | **PASS** | DC01 10.6.0.10, lab6.test, OU LAB6-Users (sv_a, sv_b), svc_pfsense_ldap chỉ Domain Users, forwarder 10.6.0.1. Chưa có ảnh ADUC/DNS Manager (07, 07b, 08) | Anh06 |
| B.5 Client-A / Client-B | **CHƯA THỰC HIỆN** | Chưa clone 2 client | — |
| B.6 DMZ-WEB | **CHƯA THỰC HIỆN** | Chưa cài Ubuntu Server + Nginx | — |
| C. LDAP LAB6-AD + kiểm tra sv_a/sv_b | **CHƯA THỰC HIỆN** | Chưa tạo Authentication Server | — |
| D. Captive Portal LAB6_USERS | **CHƯA THỰC HIỆN** |  | — |
| E. Alias | **CHƯA THỰC HIỆN** |  | — |
| F. Schedule | **CHƯA THỰC HIỆN** |  | — |
| G. Kịch bản 1 → 7 | **CHƯA THỰC HIỆN** |  | — |
| H. Chính sách tổng hợp + kiểm thử bắt buộc | **CHƯA THỰC HIỆN** |  | — |
| J. 12 câu hỏi phân tích | **PASS** | Trả lời đủ 12 câu (phần lý thuyết) | Báo cáo mục J |
| K. config.xml | **CHƯA THỰC HIỆN** | Chưa xuất bản cấu hình cuối (chưa có policy) | — |

### Số liệu chính
- MAC: em0 `08:00:27:62:bb:e5` = Adapter 1 (LAB6-WAN) · em1 `08:00:27:56:13:ff` = Adapter 2 (vboxnet0) · em2 `08:00:27:7f:2e:e3` = Adapter 3 (lab6-lan) · em3 `08:00:27:e3:c3:07` = Adapter 4 (lab6-dmz).
- pfSense ping 8.8.8.8: 3/3, 0.0% loss; Dashboard giờ `+07`.
- DC01: `lab6.test` / `LAB6` / Windows2025Domain; `svc_pfsense_ldap` chỉ thuộc *Domain Users*; `Resolve example.com → 104.20.23.154` qua forwarder pfSense.

## Lỗi gặp phải và cách khắc phục

| # | Lỗi | Nguyên nhân | Khắc phục |
|---|---|---|---|
| 1 | Console pfSense: option `7` ping `8.8.8.8` → *ping: sendto: No route to host* (Anh03b0) | Lúc đó WAN `em0` chưa nhận IP (dòng WAN trên menu trống), pfSense chưa có default gateway | Gán lại interface bằng option `1` (WAN = em0) để WAN nhận DHCP 192.168.250.3/24 từ LAB6-WAN; ping lại: 3 packets transmitted, 3 received, 0.0% packet loss (Anh03b) |
| 2 | Sau khi cài, pfSense chỉ có `WAN → em0` và `LAN → em1` | Mặc định pfSense chỉ tạo 2 interface; `em1` là card Host-Only (MGMT), không phải LAN | Assign Interfaces (option `1`): WAN em0, LAN em2, OPT1 em1, OPT2 em3, đối chiếu MAC với VirtualBox (Anh03a) |
| 3 | MGMT (OPT1) chưa có rule nên WebGUI `https://192.168.56.254` bị chặn | Interface OPT1 mới tạo mặc định block mọi lưu lượng vào | Tạm `pfctl -d` ở console, vào WebGUI tạo 2 rule OPT1: `MGMT - admin WebGUI` (TCP 443) và `MGMT - ping` (ICMP), nguồn 192.168.56.1 → This Firewall, Apply để pf bật lại (Anh03c) |

## Cấu trúc thư mục

```
LAB6/
├── README.md
├── 11DH_THMT-Lab6_1150080072-NguyenVanSang.docx
├── evidence_sha256.csv          # SHA-256 mọi tệp trong LAB6/ (trừ chính nó)
└── evidence/
    └── screenshots/             # ảnh chụp VM / cắt từ video quay màn hình buổi thực hành
```

Ảnh chụp:
- `evidence/screenshots/Anh03_pfSense_Console.png`
- `evidence/screenshots/Anh03a_pfSense_AssignIF.png`
- `evidence/screenshots/Anh03b0_Ping_NoRoute.png`
- `evidence/screenshots/Anh03b_pfSense_Ping.png`
- `evidence/screenshots/Anh03c_MGMT_Rules_OPT1.png`
- `evidence/screenshots/Anh04_pfSense_Login.png`
- `evidence/screenshots/Anh04a_Wizard_General.png`
- `evidence/screenshots/Anh04b_Wizard_WAN.png`
- `evidence/screenshots/Anh04c_Wizard_Completed.png`
- `evidence/screenshots/Anh04d_Interface_MGMT.png`
- `evidence/screenshots/Anh04e_Interface_DMZ.png`
- `evidence/screenshots/Anh04f_DHCP_LAN_Off.png`
- `evidence/screenshots/Anh04g_Dashboard_GMT7.png`
- `evidence/screenshots/Anh05_pfSense_Interfaces.png`
- `evidence/screenshots/Anh05b_pfSense_Interfaces_DMZ.png`
- `evidence/screenshots/Anh06_DC01_KetQua.png`

## An toàn & làm sạch dữ liệu
- Toàn bộ lab chạy trong mạng ảo cô lập (Internal Network, Host-Only); chỉ pfSense WAN ra Internet qua NAT Network.
- Mật khẩu xuất hiện trong script là mật khẩu lab dùng một lần, không phải mật khẩu thật.
- Không có installer, ISO, token hay dữ liệu cá nhân.
- Kiểm tra toàn vẹn: `sha256sum` từng tệp và so với `evidence_sha256.csv`.
