# longhorn

containerd doesn't resolve symlinks inside pods, so a bind mount must be added to the fstab

https://longhorn.io/docs/1.9.0/nodes-and-volumes/nodes/multidisk/#use-an-alternative-path-for-a-disk-on-the-node