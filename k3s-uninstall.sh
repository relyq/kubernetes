#!/bin/bash
cd "$(dirname "$0")"

/usr/local/bin/k3s-killall.sh
/usr/local/bin/k3s-uninstall.sh
