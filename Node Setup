#!/bin/bash
#
# Setup for Node servers

set -euxo pipefail

config_path="/etc/kubernetes"

/bin/bash $config_path/join.sh -v

NODENAME=$(hostname -s)
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
