# LAB7 – Web Protection trên mô hình pfSense + Web Proxy

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 7 – Xây dựng chính sách Web Protection trên mô hình pfSense + Web Proxy |
| **Ngày thực hành** | 20/10/2026 |
| **Báo cáo** | [`11DH_THMT-Lab7_1150080072-NguyenVanSang.docx`](11DH_THMT-Lab7_1150080072-NguyenVanSang.docx) |
| **Video** | https://youtu.be/bh3cppNg4aU |

## Mục tiêu

Bài gốc tập trung vào Web Protection: xây dựng chính sách truy cập website, phân loại/chặn/cảnh báo theo nhóm nội dung, giới hạn truy cập, quét virus khi tải file, giới hạn kích thước download, mở khóa tạm thời và xử lý HTTPS inspection.

- không cài Squid trực tiếp trên pfSense

Luồng web: Client → E2Guardian `10.6.0.30:8080` → Squid `127.0.0.1:3128` → pfSense → đích.

## Phiên bản môi trường

| Thành phần | Phiên bản |
|---|---|
| Máy thật (host) | Ubuntu 26.04.1 LTS (kernel 7.0.0-38-generic) |
| Ảo hóa | Oracle VirtualBox 7.2.18 r175117, NAT Network `LAB7-WAN` 192.168.250.0/24, Host-Only `vboxnet0` 192.168.56.1/24 |
| LAB7-pfSense | pfSense CE 2.7.2-RELEASE — WAN DHCP `192.168.250.3`, MGMT `192.168.56.254`, LAN `10.6.0.1`, DMZ `172.16.6.1` |
| LAB7-DC01 | Windows Server 2025 Standard Evaluation — `10.6.0.10`, AD/DNS `lab6.test`, zone `lab7.test` |
| LAB7-Client-A / B | Windows 11 Pro — `10.6.0.21` / `10.6.0.22` |
| LAB7-DMZ-WEB | Ubuntu Server 24.04.5 + Nginx 1.24 — `172.16.6.10`, 13 vhost `*.lab7.test` |
| LAB7-WEB-PROXY | Ubuntu Server 24.04.5 — Squid 6.14, E2Guardian 5.3.5, ClamAV 1.5.4 — `10.6.0.30` |

## Scripts

| File | Chạy trên | Nội dung |
|---|---|---|
| `scripts/dc01-setup.ps1` | DC01 | IP tĩnh, AD DS + DNS, forest lab6.test |
| `scripts/dc01-dns.ps1` | DC01 | Forwarder 10.6.0.1 + Add-LAB7-DNS.ps1 (13 bản ghi A) |
| `scripts/client-setup.ps1` | Client-A/B | IP tĩnh, DNS DC01 |
| `scripts/dmz-setup.sh` | DMZ-WEB | IP 172.16.6.10 + setup_lab7_dmz_web.sh của đề |
| `scripts/proxy-net.sh` | WEB-PROXY | IP 10.6.0.30, GW 10.6.0.1, DNS 10.6.0.10 |
| `scripts/proxy-config.sh` | WEB-PROXY | Squid localhost:3128 + size 100 MB, E2Guardian :8080, ClamAV, bypass 300, list policy, trang block |
| `scripts/lab7_block.html` | WEB-PROXY | Trang block/warning tùy biến LAB 7 |
| `scripts/proxy-test.sh` | WEB-PROXY | Kiểm thử 10 kịch bản qua proxy |

## Các phần đã thực hiện và kết quả

| Phần | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| B. Topology, IP | **PASS** | 6 VM, IP đúng đề | Anh02, Anh03, Anh05 |
| C.1–C.2 WEB-PROXY | **PASS** | E2Guardian 10.6.0.30:8080 → Squid 127.0.0.1:3128, ClamAV active | Anh07, Anh08 |
| C.3 DMZ-WEB | **PASS** | 13 vhost trả 200, file 10/100/110MB, EICAR | Anh04, Anh04b |
| C.4 DNS lab7.test | **PASS** | 13 bản ghi A → 172.16.6.10 | Anh06 |
| C.5 Proxy trên trình duyệt Client | **CHƯA LÀM** | Kiểm thử bằng curl trên WEB-PROXY | – |
| D. Alias + ruleset LAN, chống bypass | **CHƯA LÀM** | Mới có rule MGMT, LAN đang default allow | Anh12–Anh14 |
| E.1 Hard block | **PASS** | china/mideast/jobs/blockedgame bị chặn, không có bypass (domainsnobypass + sửa site.story) | Anh09, Anh10 |
| E.2 Warning / temporary bypass | **PASS** | weapons/politics/religion/streaming có link bypass 5 phút, bấm vào truy cập được | Anh09 |
| E.3 Exception | **PASS** | normal/education/download được phép | Anh09, Anh10 |
| E.4 Schedule 60 phút | **CHƯA LÀM** | entertainment/games đang truy cập được mọi lúc | – |
| E.5 ClamAV | **PASS** | eicar.com.txt bị chặn: Eicar-Signature (contentscanexceptions = on) | Anh09, Anh10 |
| E.6 Giới hạn > 100 MB | **PASS** | 100MB.bin 200, 110MB.bin 403 (Squid reply_body_max_size) | Anh09, Anh11 |
| E.7 Trang block tùy biến | **PASS** | lab7_block.html (reportinglevel 3) | Anh09 |
| G. HTTPS inspection (mở rộng) | **CHƯA LÀM** | – | – |
| I.2 Câu hỏi phân tích | **PASS** | Trả lời đủ 10 câu | Báo cáo mục 5 |

Chi tiết từng bước, ảnh và phân tích: xem báo cáo Word.
