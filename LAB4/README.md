# LAB4 – Khảo sát và đánh giá bề mặt mạng bằng Nmap

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 4 – Khảo sát và đánh giá bề mặt mạng bằng Nmap |
| **Ngày thực hành** | 29/09/2026 |
| **Báo cáo** | [`11DH_THMT-LAB4_1150080072-NguyenVanSang.docx`](11DH_THMT-LAB4_1150080072-NguyenVanSang.docx) |
| **Video** | _(không có)_ |

## Phiên bản môi trường

| Thành phần | Phiên bản |
|---|---|
| Máy thật (host) | Ubuntu 26.04.1 LTS (kernel 7.0.0-34-generic) (thay cho Windows 10/11) |
| Ảo hóa | Oracle VirtualBox 7.2.18 r175117, Host-Only `vboxnet0` 192.168.56.1/24 |
| Kali Linux VM | LAB4-Kali (kali-linux-2026.2-virtualbox-amd64), 4 GB RAM, 2 vCPU — `192.168.56.10` |
| Nmap (Kali) | 7.99 (gói `7.99+dfsg-1kali1`), libpcap 1.10.6, openssl 3.6.2 |
| Metasploitable 2 VM | LAB4-Metasploitable2 (metasploitable-linux-2.0.0), 2 GB RAM, chỉ Host-Only — `192.168.56.101` |
| Windows VM | LAB4-Win11, Windows 11 64-bit, 6 GB RAM — `192.168.56.20` |
| Nmap (Windows) | 7.99 + Npcap 1.89 + Zenmap GUI |

## Cách dựng môi trường

1. Host Ubuntu: `VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0`.
2. Giải nén `kali-linux-2026.2-virtualbox-amd64.7z`, `VBoxManage registervm`, đổi tên `LAB4-Kali`, Adapter 1 = Host-Only `vboxnet0`, Adapter 2 = NAT (tạm để `apt`). Trong Kali: `nmcli` đặt `eth0` tĩnh `192.168.56.10/24`.
3. Metasploitable 2: tạo VM `LAB4-Metasploitable2` từ `Metasploitable.vmdk`, **chỉ** Adapter 1 = Host-Only (không NAT, không Bridge); DHCP của vboxnet0 cấp cố định `192.168.56.101`.
4. Windows 11 VM `LAB4-Win11`: Adapter 1 = Host-Only (`192.168.56.20/24`), Adapter 2 = NAT tạm để tải Nmap từ nmap.org; cài Nmap + Npcap + Zenmap bằng Run as administrator.
5. Kali: `sudo apt update && sudo apt install nmap`, tạo `~/LAB4/Evidence`, chạy lần lượt các lệnh ở mục 5 → 10 của đề, lưu log bằng `-oN`.

Chi tiết từng lệnh, ảnh và phân tích: xem báo cáo Word (trình bày theo đúng bố cục `LAB4_Nmap_HuongDan_2026.pdf`).

## Các phần đã thực hiện và kết quả

| Phần | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| 2. Cài Nmap trên Windows (trong VM Windows 11) | **PASS** | Nmap 7.99 + Npcap 1.89, Zenmap GUI; ipconfig 192.168.56.20 | Hình 2.1, 2.2 |
| 3. Cài Nmap trên Kali | **PASS** | nmap 7.99+dfsg-1kali1 (already the newest version) | Hình 3.1–3.3 |
| 4. Host-Only, IP, ping | **PASS** | Kali .10, MSF2 .101, Win11 .20; ping 0% loss. Lưu ý: NAT chưa ngắt, chưa snapshot | Ảnh 1, Ảnh 2, Hình 4.4 |
| 5. Host discovery -sn | **PASS** | 5 hosts up / 256 IP trong 11.01 s | Ảnh 3 |
| 6.1–6.2 -sT / -sS | **PASS** | -sT: 23 open, 977 closed, 0 filtered (2.63 s) | Ảnh 4 (Anh4b_sT) |
| 6.3 FIN / Xmas / NULL | **PASS** | MSF2: 23 open|filtered, 977 closed; Win11: 1000 open|filtered (no-response) | Hình 6.3–6.5, 6.3b |
| 6.4 ACK scan | **PASS** | 1000 unfiltered (reset) → không có firewall lọc | Hình 6.6 |
| 7. UDP top 20 | **PASS** | 2 open, 6 open|filtered, 12 closed (9.93 s) | Hình 7.1 |
| 8. -sV / -O / -A | **PASS** | 23 dịch vụ có version; Linux 2.6.9 – 2.6.33; -A 23.91 s | Ảnh 5, Ảnh 6, Ảnh 6b |
| 9. NSE SMB | **PASS** | Samba 3.0.20-Debian; MS17-010 không xác định | Ảnh 7, Ảnh 7b |
| 10. Xuất kết quả | **PASS** | ket_qua.txt, ket_qua.xml, smb.txt + grep 445/open. Chưa có ảnh bao_cao.html (10.4) | Ảnh 8 |
| 11. Before/After hardening | **CHƯA THỰC HIỆN** | Chưa chạy 2 lần quét trước/sau | — |
| 12.2 + 14.3 Câu hỏi phân tích | **PASS** | Trả lời đủ 14 câu | Báo cáo mục 12.2, 14.3 |
| 14.1–14.2 Bài tập bổ sung | **MỘT PHẦN** | Làm câu 1, 3, 4 (phần MSF2) và bản đồ dịch vụ từ dữ liệu đã quét | Báo cáo mục 14 |

### Số liệu chính (Metasploitable 2 – 192.168.56.101)
- Host discovery: **5 hosts up** — .1 (host Ubuntu), .10 (Kali), .20 (Win11), .100 (DHCP VirtualBox), .101 (MSF2).
- TCP 1000 cổng: **23 open / 977 closed / 0 filtered**; ACK scan: 1000 unfiltered → không có firewall.
- UDP top 20: 2 open (53, 137), 6 open|filtered, 12 closed — 9.93 s.
- OS: Linux 2.6.9 – 2.6.33; SMB: Samba 3.0.20-Debian; MS17-010: không xác định.
- Dịch vụ rủi ro nhất: 1524 bindshell (root shell), 21 vsftpd 2.3.4 (CVE-2011-2523), 139/445 Samba 3.0.20 (CVE-2007-2447).

## Lỗi gặp phải và cách khắc phục

| # | Lỗi | Nguyên nhân | Khắc phục |
|---|---|---|---|
| 1 | `sudo nmap -sn 192.168.56.0/24 - oN sn.txt` → *Failed to resolve "-". Bare '-': did you put a space between '--'? Failed to resolve "oN"… "sn.txt"* (Ảnh 3) | Gõ thừa khoảng trắng giữa `-` và `oN`; Nmap hiểu `-`, `oN`, `sn.txt` là 3 mục tiêu | Kết quả quét vẫn đúng nhưng không lưu `sn.txt`. Gõ liền `-oN sn.txt` rồi chạy lại khi cần tệp log |
| 2 | Metasploitable 2: `ip -br addr` → *Option "-br" is unknown* (Ảnh 2) | iproute2 trên Ubuntu 8.04 của Metasploitable 2 quá cũ, không có tùy chọn `-br` | Dùng `ifconfig` đúng như Hình 4.3 của đề |
| 3 | Kali còn `eth1 UP 10.0.3.15/24` (Ảnh 1) và `ping -c 2 -W 2 8.8.8.8` thành công 0% loss (Hình 4.4) | Chưa ngắt Adapter 2 (NAT) sau khi cài gói như bước 16; Windows VM cũng còn *Ethernet 2* NAT 10.0.3.15 | Mọi lệnh quét chỉ nhắm 192.168.56.0/24 nên không có gói quét nào ra ngoài. Lần sau tắt VM và chạy `VBoxManage modifyvm LAB4-Kali --nic2 none` (tương tự LAB4-Win11) trước khi quét |
| 4 | Host discovery thấy 5 host thay vì 4, có thêm 192.168.56.100 | DHCP server của vboxnet0 vẫn bật (`VBoxManage list dhcpservers`: Dhcpd IP 192.168.56.100, cấp cố định 192.168.56.101 cho MAC 08:00:27:b1:66:1c) | Xác định đó là dịch vụ DHCP của VirtualBox (bước 26 của đề), không phải máy lạ; không quét tiếp |
| 5 | Không có ảnh riêng cho `sudo nmap -sS` (ảnh đặt tên Anh4_SYN_Connect thực chất là `-sT`) | Chụp nhầm lệnh | Số liệu SYN lấy từ phần quét cổng của `sudo nmap -O`/`-sV` (Nmap chạy root mặc định dùng -sS). Có thể chụp bổ sung `Anh4_SYN_Connect.png` vào `screenshots/` rồi build lại |
| 6 | `smb-vuln-ms17-010` không in dòng kết quả nào (Ảnh 7b) | Script không nhận được phản hồi đủ để kết luận; máy đích là Samba 3.0.20 trên Linux, không phải Windows SMBv1 | Ghi "không xác định", **không** suy diễn là đã vá (theo hướng dẫn mục 9.2) |
| 7 | Chưa có snapshot `Before-LAB4` (`VBoxManage snapshot … list`: *does not have any snapshots*) | Bỏ sót bước 22 | Tạo trước khi làm mục 11: `VBoxManage snapshot LAB4-Win11 take Before-LAB4` (tương tự cho 2 VM còn lại) |
| 8 | Gõ nhầm: `^M: command not found`, tên tệp UDP lưu thành `upd.txt` | Lỗi gõ phím khi tự gõ lệnh | Không ảnh hưởng kết quả; giữ nguyên trong ảnh theo quy tắc "tự gõ lệnh" |
| 9 | Đề viết cho máy thật Windows 10/11 | Máy thật của em chạy Ubuntu, không có Windows | Cài Nmap + Npcap + Zenmap trong VM Windows 11 (LAB4-Win11); IP Host-Only của host lấy bằng VBoxManage/`ip addr` |

## Cấu trúc thư mục

```
LAB4/
├── README.md
├── 11DH_THMT-LAB4_1150080072-NguyenVanSang.docx
├── evidence_sha256.csv          # SHA-256 mọi tệp trong LAB4/ (trừ chính nó)
└── evidence/
    └── screenshots/             # ảnh chụp trực tiếp từ các VM (VirtualBox)
```

Ảnh chụp:
- `evidence/screenshots/Anh1_Kali_IP.png`
- `evidence/screenshots/Anh2_MSF2_IP.png`
- `evidence/screenshots/Anh3_HostDiscovery.png`
- `evidence/screenshots/Anh4b_sT.png`
- `evidence/screenshots/Anh5_Version.png`
- `evidence/screenshots/Anh6_OS_Aggressive.png`
- `evidence/screenshots/Anh6b_A.png`
- `evidence/screenshots/Anh7_NSE.png`
- `evidence/screenshots/Anh7b_MS17.png`
- `evidence/screenshots/Anh8_Output_Files.png`
- `evidence/screenshots/Hinh2_1_Win_nmap_version.png`
- `evidence/screenshots/Hinh2_2_Win_ipconfig.png`
- `evidence/screenshots/Hinh3_1_Kali_apt_update.png`
- `evidence/screenshots/Hinh3_2_Kali_install_nmap.png`
- `evidence/screenshots/Hinh3_3_Kali_nmap_version.png`
- `evidence/screenshots/Hinh4_4_Ping.png`
- `evidence/screenshots/Hinh6_3_FIN.png`
- `evidence/screenshots/Hinh6_3b_FIN_Win.png`
- `evidence/screenshots/Hinh6_4_Xmas.png`
- `evidence/screenshots/Hinh6_5_NULL.png`
- `evidence/screenshots/Hinh6_6_ACK.png`
- `evidence/screenshots/Hinh7_1_UDP.png`

## An toàn & làm sạch dữ liệu
- Chỉ quét máy ảo của chính em trong mạng Host-Only 192.168.56.0/24; không quét IP/tên miền bên ngoài.
- Không khai thác lỗ hổng: NSE chỉ dùng `smb-os-discovery` và `smb-vuln-ms17-010` để nhận diện.
- Không có installer, mật khẩu thật, token hay dữ liệu cá nhân (tài khoản `msfadmin` là mặc định công khai của Metasploitable 2).
- Kiểm tra toàn vẹn: `sha256sum` từng tệp và so với `evidence_sha256.csv`.
