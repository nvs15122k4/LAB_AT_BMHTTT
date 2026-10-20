#!/usr/bin/env bash
# LAB7 - DMZ-WEB: IP tinh 172.16.6.10/24 (GW 172.16.6.1) + chay setup_lab7_dmz_web.sh cua de
# Chay: sudo bash ~/lab7/dmz-setup.sh
set -euo pipefail
echo "== 1. Netplan: enp0s3 (lab6-dmz) = 172.16.6.10/24, GW 172.16.6.1 =="
cat > /etc/netplan/99-lab7.yaml <<'NP'
network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [172.16.6.10/24]
      routes: [{to: default, via: 172.16.6.1, metric: 50}]
      nameservers: {addresses: [172.16.6.1]}
    enp0s8:
      dhcp4: true
      dhcp4-overrides: {route-metric: 200}
      optional: true
NP
chmod 600 /etc/netplan/99-lab7.yaml
rm -f /etc/netplan/50-cloud-init.yaml
netplan apply; sleep 3
ip -br a
timedatectl set-timezone Asia/Ho_Chi_Minh
echo "== 2. Chay setup_lab7_dmz_web.sh (nginx + 13 vhost + file test) =="
sudo -u student bash /home/student/lab7/setup_lab7_dmz_web.sh
echo "== 3. Kiem tra =="
for h in normal china download; do printf '%-22s ' "$h.lab7.test"; curl -s -o /dev/null -w '%{http_code}\n' -H "Host: $h.lab7.test" http://127.0.0.1/; done
ls -lh /var/www/lab7/download/files/
