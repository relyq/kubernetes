# pi-hole

- should enable doh via cloudflared (available in helm chart) and [unbound](https://docs.pi-hole.net/guides/dns/unbound/) for recursive dns
- [blocklists](https://github.com/hagezi/dns-blocklists)
- should serve cluster.local cert so external-dns doesn't have to skip tls verification. [not trivial](https://discourse.pi-hole.net/t/enabling-https-for-your-pi-hole-web-interface/5771)