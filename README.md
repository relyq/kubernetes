# kubernetes

homelab k3s cluster

- using SOPS + age
- i'm using a [custom longhorn storage class](https://github.com/relyq/kubernetes/tree/master/infrastructure/storage/longhorn/storageclass.yaml) with number of replicas set to one (single node k3s)
- see [secrets](https://github.com/relyq/kubernetes/tree/master/secrets/production). fix copied over secrets
- i might move the [structure readme](https://github.com/relyq/kubernetes/tree/master/clusters/production) to the root dir
- i have to demote traefik to platform - see [structure notes]((https://github.com/relyq/kubernetes/tree/master/clusters/production))

- not sure how i'll manage separated envs. what if i want -dev subdomains for dev env? currently my gateway api with the domain is in "infrastructure", with no overlay

## naming conventions

- deployments & services - if there's only one they take the service name
- supporting resources are named by purpose