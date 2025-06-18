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
mkdir /home/relyq/.kube
mkdir /root/.kube
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

kubectl apply -k ./clusters/production/flux-system