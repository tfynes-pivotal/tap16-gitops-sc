#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: create Vault Roles governing access to Tanzu Sync and TAP Install secrets

Required:
- VAULT_ADDR -- Vault server which is hosting the secrets
- CLUSTER_NAME -- cluster on which TAP is being installed

Optional:
- VAULT_TOKEN -- Vault token authorized to create policies
- VAULT_POLICY_NAME_FOR_TANZU_SYNC -- name of existing Vault Policy granting (at least) read access to secrets needed for Tanzu Sync
- VAULT_POLICY_NAME_FOR_TAP -- name of existing Vault Policy granting (at least) read access to secrets needed for TAP install
- VAULT_SECRET_PATH_FOR_TANZU_SYNC -- path in Vault for secret(s) needed for Tanzu Sync (may contain wildcards)
- VAULT_SECRET_PATH_FOR_TAP -- path in Vault for secret(s) needed for TAP install (may contain wildcards)

EOF
}
error_msg="Expected env var to be set, but was not."
: "${VAULT_ADDR?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

VAULT_POLICY_NAME_FOR_TANZU_SYNC=${VAULT_POLICY_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--read-tanzu-sync-secrets}
VAULT_POLICY_NAME_FOR_TAP=${VAULT_POLICY_NAME_FOR_TAP:-${CLUSTER_NAME}--read-tap-secrets}
VAULT_ROLE_NAME_FOR_TANZU_SYNC=${VAULT_ROLE_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--tanzu-sync-secrets}
VAULT_ROLE_NAME_FOR_TAP=${VAULT_ROLE_NAME_FOR_TAP:-${CLUSTER_NAME}--tap-install-secrets}

vault write auth/$CLUSTER_NAME/role/$VAULT_ROLE_NAME_FOR_TANZU_SYNC \
  bound_service_account_names="tanzu-sync-vault-sa" \
  bound_service_account_namespaces="tanzu-sync" \
  policies="$VAULT_POLICY_NAME_FOR_TANZU_SYNC" \
  ttl=1h

vault write auth/$CLUSTER_NAME/role/$VAULT_ROLE_NAME_FOR_TAP \
  bound_service_account_names="tap-install-vault-sa" \
  bound_service_account_namespaces="tap-install" \
  policies="$VAULT_POLICY_NAME_FOR_TAP" \
  ttl=1h