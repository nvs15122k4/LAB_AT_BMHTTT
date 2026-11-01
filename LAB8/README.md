# LAB8 – Local DNS Attack trên pfSense (DNS Spoofing & Cache Poisoning)

| | |
|---|---|
| **Họ và tên** | Nguyễn Văn Sang |
| **MSSV** | 1150080072 |
| **Mã lớp** | 11ĐH_THMT |
| **Tên lab** | Lab 8 – Local DNS Attack: DNS Spoofing và Cache Poisoning trong mạng ảo cô lập (kế thừa pfSense Lab8, dựa trên SEED Labs) |
| **Ngày thực hành** | 01/11/2026 |
| **Báo cáo** | [`11DH_THMT-Lab8_1150080072-NguyenVanSang.docx`](11DH_THMT-Lab8_1150080072-NguyenVanSang.docx) |
| **Đề bài gốc** | [`LAB8_Local_DNS_Attack_pfSense_2026.docx`](LAB8_Local_DNS_Attack_pfSense_2026.docx) |

## Mục tiêu

Dựng mạng DNS-LAB cô lập sau pfSense (kế thừa Lab8), cấu hình DNS-SERVER (BIND9) đệ quy/cache, quan sát và thực hiện 3 kỹ thuật tấn công DNS trong tài liệu gốc SEED Labs: HOSTS-file redirection, Direct DNS Spoofing (nhắm Victim), DNS Cache Poisoning (nhắm Resolver), sau đó khôi phục và phân tích biện pháp phòng thủ.

Vì hạ tầng LAN-DOMAIN/DMZ cũ của Lab6-7 không còn tồn tại trên máy thực hành, Lab8 được dựng **gọn, tự chứa (self-contained)**: chỉ dựng mới pfSense + mạng DNSLAB/DMZSIM cần thiết, không dựng lại AD/Web-Proxy của các lab trước.

## Mô hình mạng đã dựng (VirtualBox, toàn bộ qua `VBoxManage`)

| VM | Vai trò | Network / IP |
|---|---|---|
| `LAB8-pfSense` | Firewall, kế thừa Lab8 | WAN=NAT(10.0.2.15), MGMT=hostonly vboxnet0 (`192.168.56.254/24`), DNSLAB=intnet "dns-lab" (`10.9.0.1/24`), DMZSIM=intnet "dmz-sim" (`172.16.6.1/24`) |
| `LAB8-DNS-SERVER` | BIND9 recursive/cache cho DNS-LAB | `10.9.0.10/24` trên "dns-lab" |
| `LAB8-VICTIM` | Máy nạn nhân | `10.9.0.100/24` trên "dns-lab", DNS=10.9.0.10 |
| `LAB8-ATTACKER-Kali` | Kali, Scapy/raw-socket + Wireshark/tcpdump | `10.9.0.200/24` trên "dns-lab", Promiscuous Mode = **Allow VMs** |
| `LAB8-APPTEST-DMZ` | AUTH-DNS mô phỏng (delay 1.5s) + DMZ-WEB (nginx) | `172.16.6.20` (AUTH-DNS) + `172.16.6.10` (DMZ-WEB) trên "dmz-sim" |

pfSense cài qua console installer (UFS, 1 đĩa), gán `le0..le3` = WAN/MGMT/DNSLAB/DMZSIM. 5 firewall rule cô lập DNSLAB theo đúng bảng trong đề (`scripts/pfsense_config.xml`): cho phép DNS-SERVER→AUTH-DNS:53, Victim→DMZ-WEB:80, chặn+log mọi hướng còn lại (kể cả MGMT và LAN-DOMAIN cũ).

## Scripts & tài nguyên

| File | Chạy trên | Nội dung |
|---|---|---|
| `scripts/pfsense_config.xml` | pfSense (SFTP) | Toàn bộ config.xml: 4 interface + 5 firewall rule DNSLAB |
| `scripts/dns_setup.sh` | DNS-SERVER | Cài BIND9, nạp 4 file cấu hình, named-checkzone, start service |
| `scripts/90-dnslab.yaml` / `90-dnslab-victim.yaml` / `90-dmzsim.yaml` | DNS-SERVER / VICTIM / APPTEST-DMZ | Netplan IP tĩnh + route chéo sang mạng DMZSIM |
| `scripts/victim_setup.sh` | VICTIM | Áp netplan, kiểm tra ping/resolv |
| `scripts/apptest_setup.sh` | APPTEST-DMZ | Netplan 2 IP, cài nginx, trang DMZ-WEB |
| `resources/` | — | Trọn bộ tài nguyên gốc của đề (01_DNS_SERVER…07_REPORT, SHA256SUMS) |
| `resources/03_ATTACKER/dns_spoof_lab9.py` | Kali | Script spoof gốc (scapy) — **không ổn định** trong môi trường ảo hoá lồng nhau này (xem mục Sự cố) |

## Sự cố kỹ thuật đáng chú ý khi thực hành

1. **Zone forward bị "nuốt" bởi zone master cha**: khai báo `zone "external.lab9.test" { type forward; ... }` lồng dưới `zone "lab9.test" { type master; }` bị BIND9 trả lời NXDOMAIN tức thời thay vì forward, do zone master cha mặc định nhận quyền uỷ quyền (authority) cho mọi subdomain khi không có bản ghi NS zone-cut. **Khắc phục**: thêm bản ghi `external IN NS ns.lab9.test.` vào `db.lab9.test` để tạo zone cut, buộc BIND chuyển quyền xử lý `external.lab9.test` sang zone forward.
2. **Script `dns_spoof_lab9.py` (scapy) không capture được gói tin của VM khác**: `scapy.sniff(..., promisc=True)` không thực sự bật promiscuous mode ở cấp kernel Linux trên Kali (khác với `tcpdump` tự động bật). Gói tin của Victim/DNS-SERVER gửi cho nhau bị kernel lọc bỏ trước khi tới userspace dù VirtualBox đã bật "Promiscuous Mode = Allow VMs". **Khắc phục**: chạy `sudo ip link set eth0 promisc on` thủ công trước khi sniff, và viết lại attacker bằng `AF_PACKET` raw socket thuần (`scripts/dns_spoof_raw.py` nội bộ, không kèm trong `resources/` vì không thuộc gói đề) để chủ động kiểm soát toàn bộ frame Ethernet.
3. **Độ trễ ngẫu nhiên của mạng ảo lồng nhau** khiến vài lần thử đầu bị `SERVFAIL`/timeout dù cấu hình đúng — phải thử lại (`rndc flush` trước mỗi lần đo) để có kết quả ổn định.

## Các phần đã thực hiện và kết quả

| Phần | Kết quả | Ghi chú | Bằng chứng |
|---|---|---|---|
| B. Dựng DNSLAB trên pfSense + ruleset cô lập | **PASS** | 4 interface, 5 rule đúng bảng đề | `scripts/pfsense_config.xml` |
| C/D. DNS-SERVER BIND9 | **PASS** | zone lab9.test, reverse, forward external.lab9.test | — |
| E. VICTIM/ATTACKER/Fake web | **PASS** | IP tĩnh, Kali promiscuous, fake web python http.server | — |
| F. Baseline | **PASS** | `www.external.lab9.test` → `172.16.6.10`, curl trang hợp lệ | `Hinh11_baseline_victim.png` |
| G. Task 1 – HOSTS redirection | **PASS** | curl → 10.9.0.200 (trang giả Kali); `dig` trực tiếp vẫn → 172.16.6.10; đã khôi phục `/etc/hosts` | `Hinh12_task1_hosts_edit.png`, `Hinh12b_task1_result.png`, `Hinh13_task1_restore.png` |
| H. Task 2 – Direct DNS Spoofing | **PASS** | Forged response thắng cuộc đua (1 ms so với >1500 ms của phản hồi hợp lệ); Victim nhận A=10.9.0.200, curl ra đúng trang giả | `Hinh14_task2_clear_cache.png`, `Hinh16_task2_forged_response.png`, `Hinh16b_task2_curl_fake.png` |
| I. Task 3 – DNS Cache Poisoning | **CHUẨN BỊ XONG, CHƯA GHI NHẬN KẾT QUẢ** | Đã xoá cache sạch (xác nhận 0 bản ghi `external` trong `named_dump.db`) và khởi chạy `dns_spoof_raw.py --mode resolver`; dừng lại theo yêu cầu trước khi ghi nhận ảnh cache bị đầu độc | `Hinh17_task3_clean_cache.png` |
| J. Khôi phục | **PASS** | Dừng tiến trình tấn công trên Kali, `rndc flush` trên DNS-SERVER, `/etc/hosts` khôi phục | — |
| K/L. Câu hỏi phân tích, Wireshark GUI đầy đủ | **CHƯA LÀM** | Mới dùng tcpdump/log script làm bằng chứng gói tin; chưa chụp Wireshark GUI; 10 câu hỏi phân tích chưa trả lời trong báo cáo | — |

Chi tiết từng bước, lệnh và phân tích: xem báo cáo Word.
