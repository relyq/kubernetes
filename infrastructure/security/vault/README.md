# vault

- raft/consul? + backup storage backend
- multi-node requires HA mode with special configuration
- i should enable audit logs
- vault is stateful
  - don’t delete pods blindly, and always back up before doing upgrades or major config changes
- least privilege always