#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "--- please run as root"
  exit 1
fi

if ! command -v flux &> /dev/null; then
  echo "--- flux not installed, exiting"
  exit 1
fi

cd "$(dirname "$0")"

# install k3s if not already installed
if ! command -v k3s &> /dev/null; then
  echo "--- installing k3s"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
fi

# setup kubeconfigs
mkdir -p /home/relyq/.kube /root/.kube
cp -f /etc/rancher/k3s/k3s.yaml /home/relyq/.kube/config
cp -f /etc/rancher/k3s/k3s.yaml /root/.kube/config
chown relyq:relyq /etc/rancher/k3s/k3s.yaml

# disable auto-start on boot, if not already
systemctl is-enabled k3s &> /dev/null && systemctl disable k3s

# install flux if not installed
if ! kubectl get ns flux-system &>/dev/null; then
  echo "--- installing flux"
  flux check --pre
  flux install
fi

# create secrets if they don't exist
if ! kubectl get secret sops-age -n flux-system &> /dev/null; then
  kubectl create secret generic sops-age \
    --namespace=flux-system \
    --from-file=age.agekey=./age.key
fi

if ! kubectl get secret flux-system -n flux-system &> /dev/null; then
  kubectl create secret generic flux-system \
    --namespace=flux-system \
    --from-file=identity=/home/relyq/.ssh/id_ed25519 \
    --from-file=identity.pub=/home/relyq/.ssh/id_ed25519.pub \
    --from-literal=known_hosts="$(ssh-keyscan github.com)"
fi

echo "--- bringing up velero"
if ! kubectl get namespace velero >/dev/null 2>&1; then
  kubectl apply -k ./clusters/stateless-rebuild/flux-system 2> >(grep -v "missing the kubectl.kubernetes.io/last-applied-configuration annotation" >&2)
  sleep 2
fi

wait_for_flux_ready() {
  printf "Waiting for Kustomizations to become ready"
  while true; do
    NOT_READY=$(kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A -o json \
      | jq '[.items[] | select(.status.conditions[] | select(.type == "Ready" and .status != "True"))] | length')

    FAILED_KUSTOMIZATION=$(kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A -o json \
      | jq -r '[.items[] | select(.status.conditions[] | select(.type == "Ready" and .status == "False" and .reason == "ReconciliationFailed")) | .metadata.name] | first')

    if [[ -n "$FAILED_KUSTOMIZATION" && "$FAILED_KUSTOMIZATION" != "null" ]]; then
      echo -e "\nKustomization '$FAILED_KUSTOMIZATION' failed permanently. Exiting."
      exit 1
    fi

    if [[ "$NOT_READY" -eq 0 ]]; then
      echo -e "\nAll Kustomizations are ready."
      break
    fi

    printf "."
    sleep 5
  done
}

wait_for_flux_ready

sleep 5 # wait for system stability

echo "--- restoring persistence"

# --- velero restore ---
BACKUP_SEARCH_PATTERN="velero-weekly-backup-[0-9]+"
RESTORE_NAME="velero-cluster-rebuild"

# don't re-restore if already exists
if ! velero restore get "$RESTORE_NAME" &> /dev/null; then
  BACKUP_NAME=$(velero backup get -o json | jq -r '
    .items? // []
    | [.[] | select(.metadata.name | test("'"$BACKUP_SEARCH_PATTERN"'"))]
    | sort_by(.metadata.completionTimestamp)
    | last
    | .metadata.name')

  if [ -z "$BACKUP_NAME" ] || [ "$BACKUP_NAME" = "null" ]; then
    echo "No matching velero backup found. Proceed manually"
    exit 1
  fi

  echo "--- restoring $BACKUP_NAME"
  velero restore create "$RESTORE_NAME" --from-backup "$BACKUP_NAME" --wait --include-resources pv,pvc,volumesnapshots
else
  echo "Restore $RESTORE_NAME already exists, skipping"
fi

echo "--- syncing prod"

kubectl apply -k ./clusters/production/flux-system 2> >(grep -v "missing the kubectl.kubernetes.io/last-applied-configuration annotation" >&2)
wait_for_flux_ready