#!/usr/bin/env bash
# LAB7 - WEB-PROXY: IP tinh 10.6.0.30/24, GW 10.6.0.1, DNS 10.6.0.10 (lab6-lan)
set -euo pipefail
cat > /etc/netplan/99-lab7.yaml <<'NP'
network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [10.6.0.30/24]
      routes: [{to: default, via: 10.6.0.1}]
      nameservers: {addresses: [10.6.0.10], search: [lab6.test]}
NP
chmod 600 /etc/netplan/99-lab7.yaml; rm -f /etc/netplan/50-cloud-init.yaml
netplan apply; sleep 3
timedatectl set-timezone Asia/Ho_Chi_Minh
ip -br a; ip route; resolvectl dns enp0s3
ping -c2 10.6.0.1; ping -c2 10.6.0.10
getent hosts normal.lab7.test archive.ubuntu.com
