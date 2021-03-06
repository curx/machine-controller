#!/usr/bin/env bash

set -euo pipefail
set -x

cd $(dirname $0)

export ADDR=$(terraform output -json|jq '.ip.value' -r)


ssh_exec() { ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ADDR $@; }


cat <<EOEXEC |ssh_exec
set -ex
kubectl annotate --all=true --overwrite node kubermatic.io/skip-eviction=true
kubectl delete machinedeployment -n kube-system --all
kubectl delete machineset -n kube-system --all
kubectl delete machine -n kube-system --all
for try in {1..30}; do
  if kubectl get machine -n kube-system 2>&1|grep -q  'No resources found.'; then exit 0; fi
  sleep 10s
done

echo "Error: couldn't delete all machines!"
exit 1
EOEXEC
