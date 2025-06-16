# kustomizations

the purpose of this is to outline a clear hierarchy of services

lower tier resources are core services with higher impact on the critical path. if a provider has many downstream services depend on it, it will have a lower tier

## infrastructure

i could rename 00- to static or configs

- core
- platform
- high impact
- upstream
- providers
- critical path

- higher tier services go into the platform kustomization
- lower tier services have their own kustomization

### platform

internal services to manage operations

- postgres, keycloak, grafana etc

### core

foundational services that are critical for platform stability

- longhorn, cert-manager etc

currently traefik is core because i need it to expose my platform dashboards - once i set up a dns server for internal access i'll demote it to platform

### todo - dependency graph

- cert-manager depends on cluster-issuers
- postgres depends on longhorn
- keycloak depends on postgres & its keycloak migration

## apps

- top-level
- low impact
- loosely coupled
- downstream
- depend on core - platform infra