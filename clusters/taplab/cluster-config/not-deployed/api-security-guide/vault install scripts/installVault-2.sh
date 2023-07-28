kubectl -n vault exec -it vault-0 -- /bin/sh -c "vault operator init" > vault.out
cat vault.out
