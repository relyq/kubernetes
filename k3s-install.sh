#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "please run as root"
  exit 1
fi

if ! command -v flux &> /dev/null; then
  echo "flux not installed, exiting"
  exit 1
fi

cd "$(dirname "$0")"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
mkdir -p /home/relyq/.kube /root/.kube
cp -f /etc/rancher/k3s/k3s.yaml /home/relyq/.kube/config
cp -f /etc/rancher/k3s/k3s.yaml /root/.kube/config
chown relyq:relyq /etc/rancher/k3s/k3s.yaml
systemctl disable k3s

flux install

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

kubectl apply -k ./clusters/stateless-rebuild/flux-system

sleep 2 # wait for kustomizations to be created

# Wait until all flux kustomizations are ready
printf "Waiting for Kustomizations to become ready"
FAILED_KUSTOMIZATION=""
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

sleep 5 # wait for system stability

BACKUP_SEARCH_PATTERN="velero-weekly-backup-[0-9]+"

# Find latest velero backup
BACKUP_NAME=$(velero backup get -o json | jq -r '
  .items? // [.]
  | [.[] | select(.metadata.name | test("'"$BACKUP_SEARCH_PATTERN"'"))]
  | sort_by(.metadata.completionTimestamp)
  | last
  | .metadata.name')

if [ -z "$BACKUP_NAME" ] || [ "$BACKUP_NAME" = "null" ]; then
  echo "No matching velero backup found"
  exit 1
fi

echo "restoring $BACKUP_NAME"

RESTORE_NAME="auto-restore"

velero restore create "$RESTORE_NAME" --from-backup "$BACKUP_NAME" --wait --include-resources pv,pvc,volumesnapshots

# already waits

kubectl apply -k ./clusters/production/flux-system

#flux get kustomizations -A

# Wait until all flux kustomizations are ready
printf "Waiting for Kustomizations to become ready"
FAILED_KUSTOMIZATION=""
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