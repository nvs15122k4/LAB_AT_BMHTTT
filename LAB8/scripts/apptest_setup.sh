#!/bin/bash
set -e
echo 'Lab8Pass123!' | sudo -S cp /home/lab8/90-dmzsim.yaml /etc/netplan/90-dmzsim.yaml
echo 'Lab8Pass123!' | sudo -S chmod 600 /etc/netplan/90-dmzsim.yaml
echo 'Lab8Pass123!' | sudo -S netplan apply
sleep 2
echo 'Lab8Pass123!' | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -y
echo 'Lab8Pass123!' | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
echo "<html><body><h1>LAB9 DMZ-WEB</h1><p>172.16.6.10 legitimate site</p></body></html>" | sudo tee /var/www/html/index.html > /dev/null
echo 'Lab8Pass123!' | sudo -S systemctl restart nginx
echo 'Lab8Pass123!' | sudo -S systemctl enable nginx 2>&1 || true
echo "=== ip ==="
ip -br addr
echo "=== nginx ==="
systemctl is-active nginx
curl -s http://172.16.6.10/ | head -3
echo "SETUP_APPTEST_DONE"
