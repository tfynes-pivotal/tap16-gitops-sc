#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: delete Vault Roles governing access to Tanzu Sync and TAP Install secrets

Required:
- VAULT_ADDR -- Vault server which is hosting the secrets
- CLUSTER_NAME -- cluster on which TAP is being installed

Optional:
- VAULT_TOKEN -- Vault token authorized to delete policies

EOF
}
error_msg="Expected env var to be set, but was not."
: "${VAULT_ADDR?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

VAULT_ROLE_NAME_FOR_TANZU_SYNC=${VAULT_ROLE_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--tanzu-sync-secrets}
VAULT_ROLE_NAME_FOR_TAP=${VAULT_ROLE_NAME_FOR_TAP:-${CLUSTER_NAME}--tap-install-secrets}

vault delete auth/$CLUSTER_NAME/role/$VAULT_ROLE_NAME_FOR_TANZU_SYNC
vault delete auth/$CLUSTER_NAME/role/$VAULT_ROLE_NAME_FOR_TAP
