#!/bin/bash
set -e
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/90-dnslab.yaml /etc/netplan/90-dnslab.yaml
echo 'Lab8Pass123!' | sudo -S chmod 600 /etc/netplan/90-dnslab.yaml
echo 'Lab8Pass123!' | sudo -S netplan apply
echo 'Lab8Pass123!' | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -y
echo 'Lab8Pass123!' | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/bind-config/named.conf.options /etc/bind/named.conf.options
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/bind-config/named.conf.local /etc/bind/named.conf.local
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/bind-config/db.lab9.test /etc/bind/db.lab9.test
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/bind-config/db.10.9.0 /etc/bind/db.10.9.0
echo 'Lab8Pass123!' | sudo -S named-checkconf
echo 'Lab8Pass123!' | sudo -S named-checkzone lab9.test /etc/bind/db.lab9.test
echo 'Lab8Pass123!' | sudo -S named-checkzone 9.10.in-addr.arpa /etc/bind/db.10.9.0
echo 'Lab8Pass123!' | sudo -S systemctl restart bind9
echo 'Lab8Pass123!' | sudo -S systemctl enable bind9
sleep 2
echo "=== netplan/IP ==="
ip -br addr
echo "=== bind9 status ==="
systemctl is-active bind9
echo "=== self test ==="
dig @10.9.0.10 ns.lab9.test +short
echo "SETUP_DNS_DONE"
