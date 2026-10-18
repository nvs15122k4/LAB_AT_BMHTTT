# LAB6 – Xác thực Active Directory và chính sách truy cập trên pfSense

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 6 – Xác thực Active Directory và chính sách truy cập trên pfSense |
| **Ngày thực hành** | 18/10/2026 |
| **Báo cáo** | [`11DH_THMT-Lab6_1150080072-NguyenVanSang.docx`](11DH_THMT-Lab6_1150080072-NguyenVanSang.docx) |
| **Cấu hình pfSense** | [`config-pfSense-LAB6.home.arpa-20261018184656.xml`](config-pfSense-LAB6.home.arpa-20261018184656.xml) |
| **Video** | _(không có)_ |

## Phiên bản môi trường

| Thành phần | Phiên bản |
|---|---|
| Máy thật (host) | Ubuntu 26.04.1 LTS (kernel 7.0.0-38-generic) (thay cho Windows) |
| Ảo hóa | Oracle VirtualBox 7.2.18 r175117, Host-Only `vboxnet0` 192.168.56.1/24 |
| pfSense-LAB6 | pfSense CE 2.7.2-RELEASE — WAN DHCP `192.168.250.3`, MGMT `192.168.56.254`, LAN `10.6.0.1`, DMZ `172.16.6.1` |
| LAB6-DC01 | Windows Server 2025 Standard Evaluation — `10.6.0.10`, domain `lab6.test` |
| LAB6-Client-A / B | Windows 11 (linked clone LAB3-Win11) — `10.6.0.21` / `10.6.0.22` |
| LAB6-DMZ-WEB | Ubuntu Server 26.04.1 + Nginx 1.28.3 — `172.16.6.10/.20/.30/.40` |

## Cách dựng môi trường

1. Mạng: NAT Network `LAB6-WAN` 192.168.250.0/24 (DHCP), `vboxnet0` 192.168.56.1/24 tắt DHCP, Internal `lab6-lan`, `lab6-dmz`.
2. pfSense-LAB6: 4 card (LAB6-WAN, vboxnet0, lab6-lan, lab6-dmz); gán em0/em2/em1/em3; rule MGMT; Setup Wizard; tắt DHCP.
3. DC01: `dc01-1-ip-promote.ps1`, `dc01-2-users.ps1`; tắt `LDAPServerEnforceIntegrity` (chỉ trong lab) để pfSense bind LDAP TCP/389.
4. Client-A/B: linked clone LAB3-Win11, `client-setup.ps1 -Role A|B`. DMZ-WEB: `dmz-setup.sh phase1`, tự gõ lệnh Hình 4, `phase2`, `check`.
5. pfSense: LDAP `LAB6-AD` → Captive Portal `LAB6_USERS` → 8 Alias → 3 Schedule → Kịch bản 1–7 → ruleset P1–P7 → Backup config.

Chi tiết từng bước, ảnh và phân tích: xem báo cáo Word (trình bày theo bố cục `LAB6_pfSense_AD_Access_Policies_2026.pdf`).

## Các phần đã thực hiện và kết quả

| Phần | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| A. Tổng quan, topology | **PASS** | Topology riêng LAB6: WAN/MGMT/LAN/DMZ, 5 VM | Hình A.1, Anh14 |
| B.1 Tạo mạng ảo | **PASS** | LAB6-WAN 192.168.250.0/24 DHCP; vboxnet0 192.168.56.1/24 tắt DHCP; lab6-lan, lab6-dmz | Output VBoxManage |
| B.2 4 card mạng pfSense | **PASS** | 4 adapter đúng mạng, MAC khớp em0–em3 | Anh02, Anh05 |
| B.3 IP interface pfSense | **PASS** | WAN DHCP 192.168.250.3, MGMT .56.254, LAN 10.6.0.1, DMZ 172.16.6.1; DHCP tắt; rule MGMT | Anh03 → Anh05b |
| B.4 Domain Controller | **PASS** | lab6.test, OU LAB6-Users (sv_a, sv_b), svc_pfsense_ldap chỉ Domain Users, forwarder 10.6.0.1 | Anh06, 07, 07b, 08 |
| B.5 Client-A / Client-B | **PASS** | CLIENT-A 10.6.0.21, CLIENT-B 10.6.0.22, DNS 10.6.0.10, không join domain | Anh09, Anh10 |
| B.6 DMZ-WEB | **PASS** | Nginx 1.28.3, IP .10/.20/.30/.40, GW 172.16.6.1; baseline mọi đích ALLOW | Anh11, 11b, 12, 13 |
| C. LDAP LAB6-AD | **PASS** | sv_a, sv_b authenticated successfully (sau khi xử lý LDAP signing của Server 2025) | Anh15 → Anh18 |
| D. Captive Portal LAB6_USERS | **PASS** | Portal trên LAN, backend LAB6-AD; 2 session sv_a/sv_b | Anh19 → Anh23 |
| E. Alias | **PASS** | 8 alias; POLICY_CLIENTS nạp 2 IP | Anh24, 25, 26 |
| F. Schedule | **PASS** | LUNCH_WINDOW, WORK_HOURS, TEST_NOW | Anh27 |
| G.1 Kịch bản 1 | **PASS** | A: .10 ALLOW, .20 BLOCK; log 10.6.0.21 → 172.16.6.20:80 | Anh28, 29, 30 |
| G.2 Kịch bản 2 | **PASS** | A và B: .40 BLOCK, .10 ALLOW | Anh31, 32, 33 |
| G.3 Kịch bản 3 | **PASS** | B: .30 ALLOW trong TEST_NOW, BLOCK ngoài giờ (lần đầu sai do thứ tự rule) | Anh34, 35, 36, I3 |
| G.4 Kịch bản 4 | **PASS** | Trong giờ HTTPS ALLOW, ping BLOCK; ngoài giờ HTTPS BLOCK, .10 vẫn ALLOW | Anh37, 38, 39 |
| G.5 Kịch bản 5 | **PASS** | LAN→DMZ .10 ALLOW; DMZ→LAN 389/53/ICMP BLOCK, log interface DMZ | Anh40 → Anh43 |
| G.6 Kịch bản 6 | **PASS** | Block 21,10 s (curl 28); Reject 2,09 s (curl 7) | Anh44, Anh45 |
| G.7 Kịch bản 7 | **PASS** | Log KB1 đúng 10.6.0.21 → .20:80; state chỉ có tới .10 | Anh46, 46b, 47 |
| H. Chính sách tổng hợp + H.1 | **PASS** | Ruleset P1–P7; 6/6 dòng kiểm thử khớp dự đoán | Anh48 → Anh53 |
| J. Bảng kết quả + 12 câu hỏi | **PASS** | Điền đủ bảng, trả lời 12 câu | Báo cáo mục J |
| K. config.xml | **PASS** | Đã xuất cấu hình cuối cùng | Anh54, `config-pfSense-LAB6.home.arpa-20261018184656.xml` |

### Số liệu chính
- LDAP: `sv_a`, `sv_b` *authenticated successfully*; Captive Portal: 2 session `sv_a` 10.6.0.21, `sv_b` 10.6.0.22.
- Kiểm thử bắt buộc H.1: 6/6 dòng khớp dự đoán (A: .10 ALLOW, .20/.40 BLOCK; B: .30 ALLOW trong giờ nghỉ / BLOCK ngoài giờ, .40 BLOCK; DMZ → DC01 BLOCK).
- Block và Reject: **21,10 s** (curl 28) so với **2,09 s** (curl 7).
- First-match: log chặn `.20` luôn ghi rule P1/KB1, không phải P7.

## Lỗi gặp phải và cách khắc phục

| # | Lỗi | Nguyên nhân | Khắc phục |
|---|---|---|---|
| 1 | Console pfSense: ping `8.8.8.8` → *ping: sendto: No route to host* (Hình I.1) | WAN `em0` chưa nhận IP (dòng WAN trên menu trống), pfSense chưa có default gateway | Gán lại interface (option `1`, WAN = em0) để WAN nhận DHCP 192.168.250.3/24; ping lại 3/3, 0.0% loss (Anh03b) |
| 2 | Sau khi cài, pfSense chỉ có `WAN → em0` và `LAN → em1` | Mặc định pfSense chỉ tạo 2 interface; `em1` là card Host-Only (MGMT) | Assign Interfaces: WAN em0, LAN em2, OPT1 em1, OPT2 em3, đối chiếu MAC với VirtualBox (Anh03a, Anh02) |
| 3 | MGMT (OPT1) chưa có rule nên WebGUI `https://192.168.56.254` bị chặn | Interface OPT1 mới tạo mặc định chặn mọi lưu lượng vào | Tạm `pfctl -d`, tạo 2 rule OPT1 `MGMT - admin WebGUI` (TCP 443) và `MGMT - ping` nguồn 192.168.56.1, Apply (Anh03c) |
| 4 | Diagnostics → Authentication: sv_a, sv_b *Authentication failed*; log *Could not bind to LDAP server LAB6-AD* (Hình I.2) | Mật khẩu bind đúng (bind Negotiate thành công) nhưng simple bind TCP/389 bị DC trả *Strong authentication is required*: Windows Server 2025 mặc định bắt buộc LDAP signing trên DC mới | Trong lab cô lập (đề cho phép TCP/389): đặt `LDAPServerEnforceIntegrity = 0` tại `HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters` trên DC01 → simple bind OK → sv_a/sv_b thành công. Triển khai thật phải dùng LDAPS/STARTTLS với CA của AD |
| 5 | Kịch bản 3 lần đầu: Client-B trong TEST_NOW vẫn **BLOCK** SOCIAL_SITE (Hình I.3) | Thứ tự rule sai: `KB3 - Block B -> SOCIAL` nằm **trên** `KB3 - Pass … TEST_NOW` nên gói khớp Block trước (first-match) | Kéo-thả lại thứ tự (Pass có schedule ngay trên Block) → Save → Apply → Reset States → SOCIAL_SITE ALLOW (Anh34) |
| 6 | DMZ-WEB không tải được script qua NAT: `wget http://10.0.3.2:8000` → *Network is unreachable* | VirtualBox 7 mặc định không cho máy ảo NAT truy cập `localhost` của host | Chạy HTTP server tạm trên IP vboxnet0 `192.168.56.1` để tải script, tải xong tắt ngay |
| 7 | pfSense sau khi khởi động lại hiển thị giờ lệch 7 tiếng (log `Oct 18 23:58` khi thực tế ~17:00) | VirtualBox cấp RTC theo giờ địa phương, FreeBSD hiểu RTC là UTC | NTP của pfSense tự đồng bộ lại sau vài phút; kiểm tra Dashboard (+07) trước khi làm Schedule |

## Cấu trúc thư mục

```
LAB6/
├── README.md
├── 11DH_THMT-Lab6_1150080072-NguyenVanSang.docx
├── config-pfSense-LAB6.home.arpa-20261018184656.xml
├── evidence_sha256.csv          # SHA-256 mọi tệp trong LAB6/ (trừ chính nó)
└── evidence/
    └── screenshots/             # ảnh chụp VM, WebGUI, VirtualBox Manager và cắt từ video buổi thực hành
```

Ảnh chụp:
- `evidence/screenshots/Anh02_pfSense_4Adapter.png`
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
- `evidence/screenshots/Anh07_ADUC_Users.png`
- `evidence/screenshots/Anh07b_ADUC_svc.png`
- `evidence/screenshots/Anh08_DNS_Forwarder.png`
- `evidence/screenshots/Anh09_ClientA_IP.png`
- `evidence/screenshots/Anh10_ClientB_IP.png`
- `evidence/screenshots/Anh11_DMZ_Nginx_IP.png`
- `evidence/screenshots/Anh11b_DMZ_apt_nginx.png`
- `evidence/screenshots/Anh12_DMZ_Check.png`
- `evidence/screenshots/Anh13_Test_Baseline_A.png`
- `evidence/screenshots/Anh14_VBox_AllVMs.png`
- `evidence/screenshots/Anh15_LDAP_Server_1.png`
- `evidence/screenshots/Anh16_LDAP_Server_2.png`
- `evidence/screenshots/Anh17_LDAP_Test_sv_a.png`
- `evidence/screenshots/Anh18_LDAP_Test_sv_b.png`
- `evidence/screenshots/Anh19_CP_Zone.png`
- `evidence/screenshots/Anh19b_CP_Zone_Auth.png`
- `evidence/screenshots/Anh20_CP_AllowedIP.png`
- `evidence/screenshots/Anh21_CP_LoginPage_A.png`
- `evidence/screenshots/Anh21b_CP_LoginOK_A.png`
- `evidence/screenshots/Anh22_CP_LoginOK_B.png`
- `evidence/screenshots/Anh22a_CP_LoginPage_B.png`
- `evidence/screenshots/Anh23_CP_Status.png`
- `evidence/screenshots/Anh24_Alias_IP.png`
- `evidence/screenshots/Anh25_Alias_Ports.png`
- `evidence/screenshots/Anh26_Diag_Tables.png`
- `evidence/screenshots/Anh27_Schedules.png`
- `evidence/screenshots/Anh28_KB1_Rule.png`
- `evidence/screenshots/Anh29_KB1_Test.png`
- `evidence/screenshots/Anh30_KB1_Log.png`
- `evidence/screenshots/Anh31_KB2_Rule.png`
- `evidence/screenshots/Anh32_KB2_Test_A.png`
- `evidence/screenshots/Anh33_KB2_Test_B.png`
- `evidence/screenshots/Anh34_KB3_TestIn.png`
- `evidence/screenshots/Anh35_KB3_TestOut.png`
- `evidence/screenshots/Anh35b_KB3_Schedule_Out.png`
- `evidence/screenshots/Anh36_KB3_Rule.png`
- `evidence/screenshots/Anh37_KB4_TestIn.png`
- `evidence/screenshots/Anh38_KB4_TestOut.png`
- `evidence/screenshots/Anh39_KB4_Rule.png`
- `evidence/screenshots/Anh40_KB5_Rule_DMZ.png`
- `evidence/screenshots/Anh41_KB5_LAN_to_DMZ.png`
- `evidence/screenshots/Anh42_KB5_DMZ_to_LAN.png`
- `evidence/screenshots/Anh43_KB5_Log.png`
- `evidence/screenshots/Anh44_KB6_Block.png`
- `evidence/screenshots/Anh45_KB6_Reject.png`
- `evidence/screenshots/Anh46_KB7_FirewallLog.png`
- `evidence/screenshots/Anh46b_KB7_Client.png`
- `evidence/screenshots/Anh47_KB7_States.png`
- `evidence/screenshots/Anh48_Ruleset_LAN.png`
- `evidence/screenshots/Anh49_Ruleset_DMZ.png`
- `evidence/screenshots/Anh50_H1_ClientA.png`
- `evidence/screenshots/Anh51_H1_ClientB_In.png`
- `evidence/screenshots/Anh52_H1_ClientB_Out.png`
- `evidence/screenshots/Anh53_H1_DMZ.png`
- `evidence/screenshots/Anh54_Backup.png`
- `evidence/screenshots/I2_LDAP_Bind_Error.png`
- `evidence/screenshots/I3_KB3_SaiThuTu_Rule.png`
- `evidence/screenshots/I3_KB3_SaiThuTu_Test.png`

## An toàn & làm sạch dữ liệu
- Toàn bộ lab chạy trong mạng ảo cô lập (Internal Network, Host-Only); chỉ pfSense WAN ra Internet qua NAT Network.
- `config.xml` chứa mật khẩu bind LDAP của lab (pfSense lưu dạng rõ) và hash mật khẩu admin. Đây là mật khẩu dùng riêng cho lab, không dùng ở nơi khác.
- Không có installer, ISO, token hay dữ liệu cá nhân.
- Kiểm tra toàn vẹn: `sha256sum` từng tệp và so với `evidence_sha256.csv`.
