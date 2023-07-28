#!/bin/bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm upgrade --install vault hashicorp/vault --atomic --namespace vault --create-namespace --wait
sleep 5
helm repo update
sleep 5
helm upgrade --install vault hashicorp/vault --atomic --namespace vault --create-namespace --set "injector.agentDefaults.templateConfig.staticSecretRenderInterval=16s" --wait

