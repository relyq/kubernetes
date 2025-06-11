# kubernetes

homelab k3s cluster

- using SOPS + age
- i'm using a [custom longhorn storage class](https://github.com/relyq/kubernetes/blob/master/infrastructure/storage/longhorn/storageclass.yaml) with number of replicas set to one (single node k3s)
- see [keycloak](https://github.com/relyq/kubernetes/blob/master/infrastructure/auth/keycloak). fix copied over secrets
- i think i should split things into more kustomizations