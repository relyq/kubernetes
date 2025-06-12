#!/bin/bash

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
mkdir /home/relyq/.kube
mkdir /root/.kube
cp -f /etc/rancher/k3s/k3s.yaml /home/relyq/.kube/config
cp -f /etc/rancher/k3s/k3s.yaml /root/.kube/config
chown relyq:relyq /etc/rancher/k3s/k3s.yaml
systemctl disable k3s

flux install

#kubectl create ns flux-system

kubectl create secret generic sops-age \
	--namespace=flux-system \
	--from-file=age.agekey=/home/relyq/age.key

TOKEN_FILE="./k3s-flux-gh-token"
export GITHUB_TOKEN=$(cat "$TOKEN_FILE")

flux bootstrap github \
	--owner=relyq \
	--repository=kubernetes \
	--branch=master \
	--path=clusters/production \
	--personal
