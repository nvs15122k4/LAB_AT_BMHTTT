#!/usr/bin/env bash
# LAB7 - WEB-PROXY: cau hinh Squid (127.0.0.1:3128) + E2Guardian (10.6.0.30:8080) + ClamAV
# Chay: sudo bash ~/lab7/proxy-config.sh
set -euo pipefail
L=/home/student/lab7
E=/etc/e2guardian
echo "== 1. Squid: chi nghe localhost:3128, chan file > 100 MB =="
[ -f /etc/squid/squid.conf.orig ] || cp /etc/squid/squid.conf /etc/squid/squid.conf.orig
cat > /etc/squid/squid.conf <<'SQ'
# LAB7 Squid - upstream cho E2Guardian (chi localhost)
http_port 127.0.0.1:3128
acl localhost src 127.0.0.1/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80 443
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost
http_access deny all
# LAB7 strict size: tu choi response lon hon 100 MB (104857600 byte)
reply_body_max_size 104857600 bytes
access_log daemon:/var/log/squid/access.log squid
coredump_dir /var/spool/squid
visible_hostname web-proxy.lab6.test
refresh_pattern . 0 20% 4320
SQ
squid -k parse 2>&1 | grep -iE "error|warn" || true

echo "== 2. e2guardian.conf =="
[ -f $E/e2guardian.conf.orig ] || cp $E/e2guardian.conf $E/e2guardian.conf.orig
sed -i -E "s|^filterip =.*|filterip = 10.6.0.30|; s|^filterports = .*|filterports = 8080|; \
 s|^#?proxyip = .*|proxyip = 127.0.0.1|; s|^#?proxyport = .*|proxyport = 3128|; \
 s|^loglevel = .*|loglevel = 2|; s|^#?loglocation = .*|loglocation = '/var/log/e2guardian/access.log'|; \
 s|^#contentscanner = '/etc/e2guardian/contentscanners/clamdscan.conf'|contentscanner = '/etc/e2guardian/contentscanners/clamdscan.conf'|; \
 s|^enablessl = .*|enablessl = off|" $E/e2guardian.conf
grep -nE "^(filterip|filterports|proxyip|proxyport|loglevel|loglocation|contentscanner|enablessl|maxcontentfilecachescansize) " $E/e2guardian.conf

echo "== 3. e2guardianf1.conf: reportinglevel 3, bypass 300, template LAB7 =="
[ -f $E/e2guardianf1.conf.orig ] || cp $E/e2guardianf1.conf $E/e2guardianf1.conf.orig
sed -i -E "s|^reportinglevel = .*|reportinglevel = 3|; s|^bypass = .*|bypass = 300|; \
 s|^contentscanexceptions = .*|contentscanexceptions = on|; s|^#?htmltemplate = .*|htmltemplate = 'lab7_block.html'|; \
 s|^groupname = .*|groupname = 'LAB7_STUDENTS'|" $E/e2guardianf1.conf
grep -nE "^(groupname|reportinglevel|bypass|contentscanexceptions|htmltemplate|sslmitm) " $E/e2guardianf1.conf
cp $L/lab7_block.html /usr/share/e2guardian/languages/ukenglish/lab7_block.html

echo "== 4. Danh sach policy =="
for f in bannedsitelist domainsnobypass exceptionsitelist; do [ -f $E/lists/$f.orig ] || cp $E/lists/$f $E/lists/$f.orig; done
{ cat $E/lists/bannedsitelist.orig; echo "#LAB7 hard block"; cat $L/lists/hard_block_sites.txt; echo; echo "#LAB7 warning (co bypass 5 phut)"; cat $L/lists/warning_sites.txt; echo; } > $E/lists/bannedsitelist
{ cat $E/lists/domainsnobypass.orig; echo "#LAB7 hard block - khong cho bypass"; cat $L/lists/hard_block_sites.txt; echo; } > $E/lists/domainsnobypass
{ cat $E/lists/exceptionsitelist.orig; echo "#LAB7 allow"; cat $L/lists/allow_sites.txt; echo; } > $E/lists/exceptionsitelist
sed -i 's/\r$//' $E/lists/bannedsitelist $E/lists/domainsnobypass $E/lists/exceptionsitelist
for f in bannedsitelist domainsnobypass exceptionsitelist; do echo "-- $f:"; grep -A20 "#LAB7" $E/lists/$f | grep -v '^$'; done

echo "== 4b. site.story: bat kiem tra domainsnobypass (mac dinh ham rong -> hard block van bypass duoc) =="
[ -f $E/site.story.orig ] || cp $E/site.story $E/site.story.orig
awk '{print} /^function\(checknobypasslists\)/{print "if(urlin,bannedbypass) return unsetbypassallow"}' $E/site.story.orig > $E/site.story
grep -A1 "checknobypasslists" $E/site.story

echo "== 5. ClamAV: cap nhat signature + cho clamd doc file tam cua e2guardian =="
usermod -aG e2guardian clamav || true
systemctl stop clamav-freshclam || true
freshclam --quiet || freshclam || true
systemctl start clamav-freshclam || true
systemctl restart clamav-daemon
for i in $(seq 1 60); do [ -S /run/clamav/clamd.ctl ] && break; sleep 2; done
ls -l /run/clamav/clamd.ctl

echo "== 6. Khoi dong lai dich vu =="
systemctl restart squid
systemctl restart e2guardian
sleep 3
systemctl is-active squid e2guardian clamav-daemon
ss -lntp | grep -E ':8080|:3128'
