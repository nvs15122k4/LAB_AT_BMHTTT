# LAB5 – pfSense Firewall Configuration

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 5 – pfSense Firewall Configuration (WAN / LAN / DMZ, NAT, firewall rule) |
| **Ngày thực hành** | 06/10/2026 |
| **Báo cáo** | [`11DH_THMT-Lab5_1150080072-NguyenVanSang.docx`](11DH_THMT-Lab5_1150080072-NguyenVanSang.docx) |
| **Cấu hình pfSense** | [`config-pfSense-LAB5.lab5.local-20261018220723.xml`](config-pfSense-LAB5.lab5.local-20261018220723.xml) |
| **Video** | _(không có)_ |

## Phiên bản môi trường

| Thành phần | Phiên bản |
|---|---|
| Máy thật (host) | Ubuntu 26.04.1 LTS (kernel 7.0.0-38-generic) (thay cho Windows) |
| Ảo hóa | Oracle VirtualBox 7.2.18 r175117, Host-Only `vboxnet1` 10.0.0.100/8 (DHCP tắt, không GW/DNS) |
| LAB5-pfSense | pfSense CE 2.7.2-RELEASE: WAN em0 Bridged DHCP `192.168.1.145`, LAN em1 `10.0.0.1/8`, DMZ em2 `172.16.0.1/16` |
| LAB5-DC (DC01) | Windows Server 2025 Standard Evaluation: `10.0.0.2/8`, domain `vietnam.local`, forwarder 8.8.8.8 |
| LAB5-DMZ-Web | Ubuntu Server 26.04.1 + nginx 1.28.3 (thay IIS): `172.16.0.2/16` |
| LAB5-LAN-Test | Ubuntu Server 26.04.1: `10.0.0.3/8` |

## Cách dựng môi trường

1. Kiểm tra chồng lấn: Wi-Fi 192.168.1.0/24 không trùng 10.0.0.0/8 / 172.16.0.0/16. Tạo `/etc/vbox/networks.conf` để cho phép Host-Only 10.0.0.0/8, `vboxnet1` = 10.0.0.100/8.
2. Tải `.iso.gz` từ mirror Netgate, `sha256sum -c SHA256SUMS.txt` → OK, giải nén, gắn ISO. Cài pfSense (ZFS), tháo ISO.
3. Console: gán WAN em0 / LAN em1 / OPT1 em2, LAN 10.0.0.1/8 không DHCP. WebGUI `https://10.0.0.1` → Setup Wizard.
4. DC01: `VBoxManage unattended install` Windows Server 2025, script `dc-1-ip-promote.ps1` (IP, AD DS, forest vietnam.local), forwarder 8.8.8.8.
5. pfSense: OPT1 = DMZ 172.16.0.1/16 → Outbound NAT Hybrid → disable Default allow LAN, Reset States, rule nền tảng → Tình huống 1–5 → Backup config.

Chi tiết từng bước, ảnh và phân tích: xem báo cáo Word (trình bày theo bố cục tài liệu pfSense Firewall Configuration v6 của giảng viên).

## Các phần đã thực hiện và kết quả

| Phần | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| A.2 Kiểm tra chồng lấn địa chỉ | **PASS** | Wi-Fi 192.168.1.0/24, docker0 172.17.0.0/16: không trùng 10.0.0.0/8, 172.16.0.0/16 | Hình 13 |
| B.1 VM pfSense 3 card mạng | **PASS** | Bridged / Host-Only vboxnet1 / Internal dmz-net, Intel PRO/1000 → em0/em1/em2 | Hình 5 |
| B.2 SHA-256 + cài pfSense 2.7.2 | **PASS** | .iso.gz khớp 883fb7bc…; ISO giải nén trùng hash ISO đã cài; ZFS stripe | Hình 6, 7 |
| B.3 LAN 10.0.0.1/8 trên console | **PASS** | Không bật DHCP, giữ HTTPS | Hình 8, 9 |
| B.4 Domain Controller | **PASS** | Windows Server 2025, 10.0.0.2/8, GW 10.0.0.1, DNS 10.0.0.2, forest vietnam.local, forwarder 8.8.8.8 | Hình 10, 11 |
| B.5 WebGUI + Setup Wizard | **PASS** | Host-only 10.0.0.100/8 không GW/DNS, ping 10.0.0.1 0% loss; đổi mật khẩu admin | Hình 13 → 16 |
| B.6 DMZ + DMZ-Web | **PASS** | OPT1 em2 = DMZ 172.16.0.1/16; DMZ-Web 172.16.0.2 nginx, curl localhost OK | Hình 17, 18, DMZ01–03 |
| B.7 Outbound NAT | **PASS** | Hybrid; Automatic Rules có 10.0.0.0/8 và 172.16.0.0/16 | Hình 19 |
| B.8 Chuẩn hóa ruleset LAN | **PASS** | Disable 2 Default allow, giữ Anti-Lockout, Reset States, tạo LAN net → Any | Hình 21, 22 |
| B.9 Kiểm thử rule nền tảng | **PASS** | Bật: ping/DNS/HTTPS OK; Tắt + Reset States: cả 3 thất bại | Hình 23, 24 |
| C.1 Chặn ICMP, cho Web/DNS | **PASS** | ping 8.8.8.8 100% loss; DNS @8.8.8.8 OK; HTTPS 200 | TH1 |
| C.2 Chỉ một host ra Internet | **PASS** | DC 10.0.0.2 ping 0% loss; LAN-Test 10.0.0.3 100% loss | TH2 |
| C.3 Cô lập DMZ khỏi LAN | **PASS** | Baseline DMZ → DC 0% loss; sau Block 100% loss; DMZ vẫn ra Internet | TH3 |
| C.4 Port Forward WAN → DMZ | **PASS** | http://192.168.1.145:8080 → nginx DMZ-Web (HTTP 200) | TH4 |
| C.5 Logging + Firewall Log | **PASS** | Log đúng rule TH1/TH2/TH3; State table của Port Forward | TH5 |
| D. 6 câu hỏi | **PASS** | Trả lời đủ, dẫn chứng bằng kết quả thật | Mục D |

### Số liệu chính
- Rule nền tảng: Enabled → ping 8.8.8.8 0% loss, DNS OK, HTTPS 200; Disabled + Reset States → 100% loss, DNS timeout, HTTPS 000.
- TH1: ping 100% loss; `Resolve-DnsName example.com -Server 8.8.8.8` OK; HTTPS 200.
- TH2: DC01 10.0.0.2 0% loss; LAN-Test 10.0.0.3 100% loss.
- TH3: DMZ-Web → DC01 trước Block 0% loss, sau Block 100% loss; DMZ → 8.8.8.8 vẫn 0% loss.
- TH4: `http://192.168.1.145:8080` → `HTTP/1.1 200 OK`, `Server: nginx/1.28.3` (DMZ-Web 172.16.0.2:80).

## Lỗi gặp phải và cách khắc phục

| # | Lỗi | Nguyên nhân | Khắc phục |
|---|---|---|---|
| 1 | VirtualBox không cho đặt Host-Only `10.0.0.100/8` | VirtualBox 7 trên Linux chỉ cho Host-Only trong `192.168.56.0/21` nếu không có `/etc/vbox/networks.conf` | Tạo `/etc/vbox/networks.conf` với `* 10.0.0.0/8 192.168.0.0/16` (sudo), rồi `VBoxManage hostonlyif ipconfig vboxnet1 --ip 10.0.0.100 --netmask 255.0.0.0` |
| 2 | Trên WebGUI chỉ có WAN/LAN, `em2` vẫn nằm ở *Available network ports* dù đã gán OPT1 trên console (Hình I.1). Mở `interfaces.php?if=opt1` khi OPT1 chưa tồn tại thì pfSense trả về trang WAN, nên lần cấu hình đầu ghi nhầm IP DMZ `172.16.0.1/16` lên WAN | Gán OPT1 trên console không được giữ lại sau Setup Wizard; trang chỉnh interface không báo lỗi khi tên interface không tồn tại | Trả WAN về DHCP (nhận lại 192.168.1.145), Interfaces → Assignments → **Add** `em2` thành OPT1, rồi mới cấu hình DMZ. Kiểm tra lại Status → Interfaces đủ 3 card đúng MAC (Hình 18b) |
| 3 | Dashboard hiển thị *Name: .* (hostname rỗng) | Bước General Information của Setup Wizard không lưu hostname/domain | System → General Setup: Hostname `pfSense-LAB5`, Domain `lab5.local` → Save (Hình 8c, 16) |
| 4 | Sau khi promote, DNS trên card LAN của DC01 tự đổi thành `127.0.0.1` | Install-ADDSForest đặt DNS loopback cho DC | Đặt lại Preferred DNS = `10.0.0.2` đúng yêu cầu đề (Hình 10) |
| 5 | Lần test đầu khi rule nền tảng đã tắt: ping/HTTPS bị chặn nhưng `Resolve-DnsName` vẫn ra IP | DNS Server trên DC01 còn **cache** kết quả từ lần test trước, không cần ra Internet | Thêm `Clear-DnsServerCache -Force; Clear-DnsClientCache` trước mỗi lần test; DNS cũng thất bại (Hình 23b) |
| 6 | Firewall Log ghi gói ICMP bị chặn nhưng cột Rule hiện `TH1 - Pass DNS TCP/UDP 53` (Hình I.2) | Rule Block ICMP và Pass DNS tạo trong cùng 1 giây nên **trùng tracker ID** `1792335070` (pfSense đặt tracker theo timestamp); log tra mô tả theo tracker nên hiện sai tên rule | Xóa và tạo lại rule Pass DNS (tracker mới `1792335263`), đặt lại đúng vị trí dưới Block ICMP; log hiện đúng `TH1 - Block ICMP` (TH5a). Khi tạo nhiều rule liên tiếp phải chờ ≥ 1 giây giữa các lần Save |
| 7 | Reset States làm WebGUI mất kết nối vài giây | Xóa state table xóa luôn kết nối HTTPS của trình duyệt quản trị (đề đã cảnh báo) | Chờ ~6 giây rồi tải lại trang, WebGUI tự kết nối lại |
| 8 | Cột thời gian Firewall Log hiển thị giờ UTC (vd. `14:55` khi DC01 là `21:55`) | syslogd khởi động trước khi đổi timezone sang Asia/Ho_Chi_Minh trong Wizard | Đối chiếu log bằng +7 giờ; Dashboard và các máy khác đều đúng +07. Khởi động lại pfSense sẽ làm log theo giờ địa phương |

## Cấu trúc thư mục

```
LAB5/
├── README.md
├── 11DH_THMT-Lab5_1150080072-NguyenVanSang.docx
├── config-pfSense-LAB5.lab5.local-20261018220723.xml
├── scripts/                     # script đã dùng (VBoxManage/PowerShell/Playwright)
├── evidence_sha256.csv          # SHA-256 mọi tệp trong LAB5/ (trừ chính nó)
└── evidence/
    └── screenshots/             # ảnh màn hình VM, WebGUI pfSense, terminal máy thật
```

Ảnh chụp:
- `evidence/screenshots/Final_Backup.png`
- `evidence/screenshots/Final_DMZ_Rules.png`
- `evidence/screenshots/Final_LAN_Rules.png`
- `evidence/screenshots/Final_Outbound_NAT.png`
- `evidence/screenshots/Hinh05_VBox_VMs_NICs.png`
- `evidence/screenshots/Hinh06a_SHA256_Verify.png`
- `evidence/screenshots/Hinh07_pfSense_Installer.png`
- `evidence/screenshots/Hinh07b_pfSense_Install_Complete.png`
- `evidence/screenshots/Hinh08a_Console_Menu_Default.png`
- `evidence/screenshots/Hinh08b_Console_Assign_Interfaces.png`
- `evidence/screenshots/Hinh08c_Console_Menu_Final.png`
- `evidence/screenshots/Hinh08c_Console_Menu_LAN_10.0.0.1.png`
- `evidence/screenshots/Hinh09a_Console_LAN_10.0.0.1.png`
- `evidence/screenshots/Hinh09b_Console_LAN_Saved.png`
- `evidence/screenshots/Hinh10_DC_IPv4_Config.png`
- `evidence/screenshots/Hinh11_ServerManager_ADDS_DNS.png`
- `evidence/screenshots/Hinh13_Host_Ping_pfSense.png`
- `evidence/screenshots/Hinh14_pfSense_Login.png`
- `evidence/screenshots/Hinh15_Wizard_01.png`
- `evidence/screenshots/Hinh15_Wizard_02.png`
- `evidence/screenshots/Hinh15_Wizard_03.png`
- `evidence/screenshots/Hinh15_Wizard_04.png`
- `evidence/screenshots/Hinh15_Wizard_05.png`
- `evidence/screenshots/Hinh15_Wizard_06.png`
- `evidence/screenshots/Hinh15_Wizard_07.png`
- `evidence/screenshots/Hinh15_Wizard_08.png`
- `evidence/screenshots/Hinh15_Wizard_09_Completed.png`
- `evidence/screenshots/Hinh16_Dashboard.png`
- `evidence/screenshots/Hinh17_Interfaces_Assignments_OPT1.png`
- `evidence/screenshots/Hinh17a_Interfaces_Assignments_Before.png`
- `evidence/screenshots/Hinh17b_Interfaces_Assignments_DMZ.png`
- `evidence/screenshots/Hinh18_Interface_DMZ_Saved.png`
- `evidence/screenshots/Hinh18a_Interface_DMZ_Form.png`
- `evidence/screenshots/Hinh18b_Status_Interfaces.png`
- `evidence/screenshots/Hinh19_OutboundNAT_Hybrid_AutoRules.png`
- `evidence/screenshots/Hinh21_LAN_Rules_NenTang.png`
- `evidence/screenshots/Hinh21a_LAN_Rules_Default.png`
- `evidence/screenshots/Hinh21b_LAN_Default_Disabled.png`
- `evidence/screenshots/Hinh21c_Reset_States.png`
- `evidence/screenshots/Hinh21d_Reset_States_Done.png`
- `evidence/screenshots/Hinh21e_Rule_LANnet_Any_Form.png`
- `evidence/screenshots/Hinh22_pfSense_Diag_Ping.png`
- `evidence/screenshots/Hinh23a_DC_Test_RuleNenTang_Enabled.png`
- `evidence/screenshots/Hinh23b_DC_Test_RuleNenTang_Disabled.png`
- `evidence/screenshots/Hinh24a_LAN_RuleNenTang_Disabled.png`
- `evidence/screenshots/Hinh24b_Reset_States.png`
- `evidence/screenshots/Hinh24c_LAN_RuleNenTang_Enabled_Again.png`
- `evidence/screenshots/Hinh_DMZ01_apt_install_nginx.png`
- `evidence/screenshots/Hinh_DMZ02_IP_nginx_localhost.png`
- `evidence/screenshots/Hinh_DMZ03_DNS_8888.png`
- `evidence/screenshots/I2_Log_Tracker_Trung.png`
- `evidence/screenshots/TH1a_Alias_WEB_PORTS.png`
- `evidence/screenshots/TH1b_Rule_Block_ICMP_Form.png`
- `evidence/screenshots/TH1c_LAN_Rules.png`
- `evidence/screenshots/TH1d_DC_Test.png`
- `evidence/screenshots/TH2a_Rule_Pass_DC_Form.png`
- `evidence/screenshots/TH2b_LAN_Rules.png`
- `evidence/screenshots/TH2c_DC_Test_Pass.png`
- `evidence/screenshots/TH2d_LANTest_Test_Block.png`
- `evidence/screenshots/TH3a_LAN_Rules_Truoc_TH3.png`
- `evidence/screenshots/TH3b_DMZ_Rules_Empty.png`
- `evidence/screenshots/TH3c_Rule_Pass_DMZ_Form.png`
- `evidence/screenshots/TH3d_DMZ_Rules_Baseline.png`
- `evidence/screenshots/TH3e_DC_netsh_ICMP.png`
- `evidence/screenshots/TH3f_DMZ_Ping_DC_Baseline.png`
- `evidence/screenshots/TH3g_Rule_Block_DMZ_LAN_Form.png`
- `evidence/screenshots/TH3h_DMZ_Rules_Block_Tren_Pass.png`
- `evidence/screenshots/TH3i_DMZ_Test_Sau_Block.png`
- `evidence/screenshots/TH3j_DC_netsh_Delete_ICMP.png`
- `evidence/screenshots/TH4a_TestPort_172.16.0.2_80.png`
- `evidence/screenshots/TH4b_WAN_Bo_Block_Private_Bogon.png`
- `evidence/screenshots/TH4c_PortForward_Form.png`
- `evidence/screenshots/TH4d_PortForward_List.png`
- `evidence/screenshots/TH4e_WAN_Rule_Associated.png`
- `evidence/screenshots/TH4f_Host_curl_WAN_8080.png`
- `evidence/screenshots/TH4g_Browser_WAN_8080.png`
- `evidence/screenshots/TH4h_DMZ_nginx_access_log.png`
- `evidence/screenshots/TH5a_FirewallLog_Block_ICMP.png`
- `evidence/screenshots/TH5b_FirewallLog_Block_LANTest.png`
- `evidence/screenshots/TH5c_FirewallLog_Block_DMZ_LAN.png`
- `evidence/screenshots/TH5d_States_PortForward.png`

## An toàn & làm sạch dữ liệu
- pfSense CE 2.7.2 là bản cũ, chỉ dùng trong lab cô lập. Block private/bogon trên WAN chỉ tắt để thử Port Forward trong mạng Wi-Fi nhà.
- `config.xml` chứa hash mật khẩu admin của lab (mật khẩu dùng riêng cho lab).
- Không có installer, ISO, token hay dữ liệu cá nhân.
- Kiểm tra toàn vẹn: `sha256sum` từng tệp và so với `evidence_sha256.csv`.
