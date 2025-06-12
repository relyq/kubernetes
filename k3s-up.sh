#!/bin/bash
docker compose -f /home/relyq/compose/main-compose/compose.yaml down traefik

# restore old iptables state saved by k3s-down.sh
if [ -f ./.k3s-iptables-backup ]; then
    echo "restoring iptables rules for k3s"
    iptables-restore < ./.k3s-iptables-backup
fi

systemctl start k3s

echo "k3s up"
