#!/bin/bash
set -e
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/90-dnslab-victim.yaml /etc/netplan/90-dnslab.yaml
echo 'Lab8Pass123!' | sudo -S chmod 600 /etc/netplan/90-dnslab.yaml
echo 'Lab8Pass123!' | sudo -S netplan apply
sleep 2
echo "=== ip ==="
ip -br addr
echo "=== resolv ==="
resolvectl status enp0s8 2>&1 | head -10 || cat /etc/resolv.conf
echo "=== ping dns-server ==="
ping -c2 -W2 10.9.0.10
echo "SETUP_VICTIM_DONE"
