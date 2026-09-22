# LAB3 – Nhận diện và ứng phó các mối đe dọa đến an toàn thông tin

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 3 – Identifying and Responding to Information Security Threats |
| **Báo cáo** | [`11DH_THMT-LAB3_1150080072-NguyenVanSang.docx`](11DH_THMT-LAB3_1150080072-NguyenVanSang.docx) |
| **Video** | _(không yêu cầu)_ |

## Phiên bản môi trường

| Thành phần | Phiên bản |
|---|---|
| Ảo hóa | Oracle VirtualBox (VM LAB3-Win11, Adapter 1 = Host-only Adapter vboxnet0) |
| Máy ảo | Windows 11 Home 25H2 x64 (OS Build 26200.8037), hostname LAB3-WIN11 |
| Endpoint protection | Microsoft Defender Antivirus 4.18.25080.5 (engine 1.1.26090.7, signature 1.459.335.0), Real-time + Tamper Protection bật |
| Shell | Windows PowerShell 5.1 (Run as administrator) |
| Sysmon | 15.22 (schema 4.90, `sysmon-lab.xml`) |
| Autoruns | 14.3 |
| Process Explorer | 17.14 |
| Wireshark | 4.6.8 + Npcap |
| Python | 3.14.7 |

## Cách dựng môi trường

1. Tạo VM Windows 11 25H2 x64 trên Oracle VirtualBox (2 vCPU, 6 GB RAM, 64 GB đĩa), **Network → Adapter 1 → Host-only Adapter**, cài Guest Additions để chép `lab3_assets` qua Shared Folder, tạo snapshot sạch `LAB3_CLEAN_<ngày>`.
2. PowerShell (Admin): tạo `C:\LAB3\{Evidence,Tools,Downloads,Assets}`, ghi `start_time.txt`.
3. Chép/giải nén `lab3_assets` vào `C:\LAB3\lab3_assets`, kiểm tra hash.
4. `winget install` Python 3.14.7 và Wireshark 4.6.8 (kèm Npcap).
5. Tải Sysmon, Autoruns, Process Explorer **chỉ** từ `https://download.sysinternals.com/files/…`, giải nén vào `C:\LAB3\Tools`, kiểm tra version.
6. Chạy baseline, rồi lần lượt TH1 → TH7, cleanup, `Get-FileHash` toàn bộ Evidence.

Chi tiết lệnh: xem báo cáo Word và `HUONG_DAN_LAB3.md` gốc của bài.

## Các tình huống đã thực hiện và kết quả

| Tình huống | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| Baseline | **PASS** | AntivirusEnabled, RealTimeProtectionEnabled, IsTamperProtected = True (H3) | H3 |
| TH1 – Risk register & phân loại nguồn đe dọa | **PASS** | Risk register 7 dòng + phân loại 5 tình huống | Báo cáo mục B.1 |
| TH2 – Malware: EICAR + Defender | **PASS** | Đã chạy khối lệnh EICAR + Get-MpThreatDetection; Defender vẫn bật, không Allow, không exclusion (H4) | H4 |
| TH3 – Brute force / dictionary / keylogger, Event 4624/4625/4648 | **PASS** | Audit Logon bật; lab3user đăng nhập bằng runas sinh cặp 4648 + 4624 lúc 8:56:46, 8:58:04, 9:00:47 (H5) | H5 |
| TH4 – Backdoor: Run key, Scheduled Task, listener 127.0.0.1:8080 | **PASS** | Sysmon Event 1 (H6); Autoruns thấy LAB3_Persistence_Demo (H7); python.exe PID 4300 bind 127.0.0.1:8080 (H8) | H6, H7, H8 |
| TH5 – Sniffing / MITM / Spoofing: HTTP vs HTTPS | **FAIL (lần 1)** | Capture loopback chạy, nhưng lúc curl thì HTTP server đã dừng → chỉ có SYN/RST, chưa thấy GET TRAINING_ONLY (H9). Phần HTTPS chưa làm | H9 |
| TH6 – DoS / DDoS / Mail bombing | **CHƯA THỰC HIỆN** | Chưa làm tới phần này; câu hỏi liên quan đã trả lời trong mục C | evidence/offline_analysis/ (phân tích dataset) |
| TH7 – Social Engineering / Phishing | **CHƯA THỰC HIỆN** | Chưa làm tới phần này; câu hỏi liên quan đã trả lời trong mục C | Báo cáo câu 16–17 |
| Cleanup – Recover – Verify | **CHƯA THỰC HIỆN** | Chưa làm tới phần này; câu hỏi liên quan đã trả lời trong mục C | — |

### Số liệu chính
- **DDoS dataset:** 120 bản ghi / 14.9 s, 20 SourceIP (TEST-NET), nguồn lớn nhất chỉ 8.3% → chặn 1 IP không đủ.
- **Mail bombing:** `bulk-sender@example.invalid` gửi 60/80 thư trong 118 s (~31 thư/phút), chiếm 92.1% dung lượng.
- **TH4:** python.exe PID 4300 lắng nghe 127.0.0.1:8080; `LAB3_Persistence_Demo` → `cmd.exe /c echo LAB3_TASK_OK>>C:\LAB3\Evidence\task_ran.txt`.

## Lỗi gặp phải và cách khắc phục

| # | Lỗi | Nguyên nhân | Khắc phục |
|---|---|---|---|
| 1 | curl.exe báo “Failed to connect to 127.0.0.1 port 8080 … Could not connect to server”; Wireshark chỉ có SYN → RST,ACK (H9 lần 1) | Cửa sổ `python -m http.server 8080 --bind 127.0.0.1` đã bị đóng/ dừng trước khi gửi request | Mở lại PowerShell riêng chạy HTTP server, kiểm tra `Get-NetTCPConnection -LocalPort 8080 -State Listen`, rồi mới chạy curl và capture lại |
| 2 | `winget install --id Insecure.Npcap` → “No package found matching input criteria” | Npcap không có trên kho winget | Cài Npcap từ trình cài Wireshark 4.6.8 (tick Install Npcap) hoặc npcap.com, chọn “Support loopback traffic” |
| 3 | Lệnh copy từ PDF bị ngắt dòng, PowerShell hiện dấu nhắc `>>` chờ nhập tiếp | PDF xuống dòng giữa tham số (vd. `-OutFile`, `Select`) | Nối lại thành 1 dòng hoặc dùng dấu backtick ` ở cuối dòng; nhấn Enter trống để thoát `>>` |
| 4 | Get-FileHash của LAB3_Threats_Assets.zip không khớp manifest 96236f95…5439 | File zip trong máy là bản đóng gói lại (có thêm PDF và file khóa ~$…docx), không phải gói gốc | Không dùng hash zip để kết luận; đối chiếu nội dung lab3_assets với README.txt và băm từng tệp; báo giảng viên |
| 5 | VM là Windows 11 Home build 26200.8037, không phải Pro/Enterprise 26200.9445 | ISO có sẵn là bản Home, chưa cài KB5124008 | Ghi rõ phiên bản thực tế; các lệnh dùng trong lab (auditpol, Get-WinEvent, Sysmon) vẫn chạy được trên Home |
| 6 | Dùng VirtualBox thay VMware Workstation 26H1 | Máy host chạy Linux, đã có VirtualBox | Cấu hình Host-only Adapter (vboxnet0), Guest Additions cho clipboard/shared folder để chép lab3_assets |

## Cấu trúc thư mục

```
LAB3/
├── README.md
├── 11DH_THMT-LAB3_1150080072-NguyenVanSang.docx
├── evidence_sha256.csv          # SHA-256 mọi tệp trong LAB3/ (trừ chính nó)
└── evidence/
    ├── screenshots/             # ảnh chụp trực tiếp từ VM
    └── offline_analysis/        # thống kê ddos_sample.csv / mailbomb_sample.csv
```

Ảnh chụp:
- `evidence/screenshots/H1_VM_VirtualBox_HostOnly.png`
- `evidence/screenshots/H1_VM_WindowsVersion.png`
- `evidence/screenshots/H2_ToolVersions.png`
- `evidence/screenshots/H3_Baseline_Defender_Firewall.png`
- `evidence/screenshots/H4_ProtectionHistory_EICAR.png`
- `evidence/screenshots/H5_Event4625.png`
- `evidence/screenshots/H6_Sysmon_Event1.png`
- `evidence/screenshots/H7_Autoruns_LAB3_Run_Demo.png`
- `evidence/screenshots/H8_ProcessExplorer_Python.png`
- `evidence/screenshots/H9_HTTP_Plaintext.png`

## An toàn & làm sạch dữ liệu
- Không có installer, executable Sysinternals/Wireshark/Python, tệp EICAR hoặc tệp bị quarantine.
- Không có mật khẩu (lab3user tạo bằng `Read-Host -AsSecureString`), token, cookie, email thật. SID, ComputerID, địa chỉ MAC trong log đã được thay bằng `<REDACTED>`.
- `local_load_test.py` giữ nguyên target `127.0.0.1:8080`; không tạo mail bomb, DDoS, spoofing hay MITM ngoài VM.
- Kiểm tra toàn vẹn: tính lại `Get-FileHash -Algorithm SHA256` (hoặc `sha256sum`) và so với `evidence_sha256.csv`.
