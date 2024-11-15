#!/bin/bash

# Deploys the Kubernetes dashboard when enabled in settings.yaml

set -euxo pipefail

config_path="./configs"

DASHBOARD_VERSION=$(grep -E '^\s*dashboard:' settings.yaml | sed -E -e 's/[^:]+: *//' -e 's/\r$//')
if [ -n "${DASHBOARD_VERSION}" ]; then
  while kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'Waiting for metrics server to be ready...'
    sleep 5
  done
  echo 'Metrics server is ready. Installing dashboard...'

  kubectl create namespace kubernetes-dashboard

  echo "Creating the dashboard user..."

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
EOF

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  echo "Deploying the dashboard..."
  kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v${DASHBOARD_VERSION}/aio/deploy/recommended.yaml"

  kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}" > "${config_path}/token"
  echo "The following token was also saved to: ${config_path}/token"
  cat "${config_path}/token"
  echo "
Use it to log in at:
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard
"
fi
