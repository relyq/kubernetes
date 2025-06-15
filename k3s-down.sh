#!/bin/bash
cd "$(dirname "$0")"

systemctl stop k3s

# save current iptables rules before flushing
echo "saving k3s iptables rules"
iptables-save > ./.k3s-iptables-backup

# flush nat rules that k3s set up
echo "flushing k3s-related iptables nat rules"
iptables -t nat -F KUBE-SERVICES
iptables -t nat -F KUBE-POSTROUTING
iptables -t nat -F KUBE-NODEPORTS
iptables -t nat -F KUBE-MARK-MASQ
iptables -t nat -F

docker compose -f /home/relyq/compose/main-compose/compose.yaml up -d traefik

echo "k3s down"
