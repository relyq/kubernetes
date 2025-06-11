# kubernetes

homelab k3s cluster

- using SOPS + age
- i'm using a [custom longhorn storage class](https://github.com/relyq/kubernetes/tree/master/infrastructure/storage/longhorn/storageclass.yaml) with number of replicas set to one (single node k3s)
- i think i should split things into more kustomizations
- there's some dependency issues with kustomizations at the moment - infrastructure resources need secrets, but secrets need namespaces created in infrastructure kustomizations
- see [secrets](https://github.com/relyq/kubernetes/tree/master/secrets/production). fix copied over secrets

## order of resource creation

- keycloak only after postgres & keycloak migration
- clusterissuers after cert-manager