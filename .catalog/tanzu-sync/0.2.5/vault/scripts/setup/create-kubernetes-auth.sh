#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: create Vault Kubernetes Auth engine

Required Environment Variables:
- VAULT_ADDR -- Vault server which is hosting the secrets
- CLUSTER_NAME -- cluster on which TAP is being installed

Optional Environment Variables:
- VAULT_TOKEN -- Vault token authorized to add/update authentication engine instances in vault
EOF
}

error_msg="Expected env var to be set, but was not."
: "${VAULT_ADDR?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

k8s_api_server="$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")"
k8s_cacert="$(kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 --decode)"

vault auth enable -path=$CLUSTER_NAME kubernetes

vault write auth/$CLUSTER_NAME/config \
  kubernetes_host="${k8s_api_server}" \
  kubernetes_ca_cert="${k8s_cacert}" \
  ttl=1h