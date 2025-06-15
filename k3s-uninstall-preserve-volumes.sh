#!/bin/bash
cd "$(dirname "$0")"

set -euo pipefail

LONGHORN_DISK_PATH="/var/lib/longhorn"  # change this if your disk path is different

echo "[1/5] Scaling down workloads using PVCs..."
kubectl -n longhorn-system scale deployment --all --replicas=0 || true

echo "[2/5] Waiting for volumes to detach..."
while kubectl get volumes -n longhorn-system -o jsonpath='{.items[*].status.state}' | grep -qv "detached"; do
  echo "Waiting for all volumes to become detached..."
  sleep 5
done

echo "[3/5] Stopping k3s..."
sudo systemctl stop k3s || true

echo "[4/5] Verifying longhorn data exists..."
if [ -d "$LONGHORN_DISK_PATH" ]; then
  echo "Longhorn disk directory exists: $LONGHORN_DISK_PATH"
  echo "   Contents:"
  ls -l "$LONGHORN_DISK_PATH"
else
  echo "Longhorn disk path not found: $LONGHORN_DISK_PATH"
  exit 1
fi

echo "[5/5] Running k3s uninstall..."
sudo /usr/local/bin/k3s-uninstall.sh

echo "k3s removed. Longhorn volume data preserved at $LONGHORN_DISK_PATH"