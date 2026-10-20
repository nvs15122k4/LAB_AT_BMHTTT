#!/usr/bin/env bash
# LAB7 - kiem thu policy qua E2Guardian 10.6.0.30:8080 (chay tren WEB-PROXY)
P=http://10.6.0.30:8080
echo "=== LAB7 proxy test - $(date '+%F %T') - $(hostname) $(hostname -I) ==="
printf '%-26s %-5s %s\n' SITE HTTP KET_QUA
for h in normal china mideast jobs weapons politics religion education streaming blockedgame entertainment games; do
  T=$(curl -s -x $P http://$h.lab7.test/ | grep -oE '<title>[^<]*|Lý do:</b>[^<]*|GBYPASS' | sed 's/<title>//; s/Lý do:<\/b> //' | paste -sd'|' | sed 's/|GBYPASS/ [co link bypass 5 phut]/')
  printf '%-26s %-5s %s\n' "$h.lab7.test" "$(curl -s -o /dev/null -w '%{http_code}' -x $P http://$h.lab7.test/)" "$T"
done
echo "--- Download (AV + size) ---"
for f in eicar.com.txt 10MB.bin 100MB.bin 110MB.bin; do
  printf '%-26s %s\n' "$f" "$(curl -s -o /tmp/t.bin -w 'HTTP %{http_code}  %{size_download} byte' -x $P http://download.lab7.test/files/$f) $(grep -aoE 'Virus[^<]*|Eicar[^<]*' /tmp/t.bin | head -1)"
done
echo "--- Bypass weapons (warning) vs china (hard block) ---"
L=$(curl -s -x $P http://weapons.lab7.test/ | grep -oE 'http://[^"]*GBYPASS=[^"]*')
echo "weapons: bam link bypass -> $(curl -s -L -c /tmp/cj -b /tmp/cj -x $P "$L" | grep -oE '<title>[^<]*' | sed 's/<title>//')"
echo "china  : link bypass = [$(curl -s -x $P http://china.lab7.test/ | grep -oE 'GBYPASS=[^"]*' | head -1)] (rong = khong cho bypass)"
echo "--- Squid chi nghe localhost ---"; ss -lnt | grep -E ':3128|:8080'
