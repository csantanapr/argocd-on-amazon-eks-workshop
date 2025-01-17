#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(cd ${SCRIPTDIR}/../..; pwd )"
[[ -n "${DEBUG:-}" ]] && set -x


pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

pushd ${SCRIPTDIR}

if [[ $# -eq 0 ]] ; then
    echo "No arguments supplied"
    echo "Usage: destroy.sh <environment>"
    echo "Example: destroy.sh dev"
    exit 1
fi
env=$1
echo "Destroying $env ..."

set -x

terraform workspace select $env
# Delete the Ingress/SVC before removing the addons
TMPFILE=$(mktemp)
terraform output -raw configure_kubectl > "$TMPFILE"
source "$TMPFILE"
kubectl delete svc --all -n ui

terraform destroy -target="module.gitops_bridge_bootstrap" -auto-approve -var-file="workspaces/${env}.tfvars"
terraform destroy -target="module.eks_blueprints_addons" -auto-approve -var-file="workspaces/${env}.tfvars"
terraform destroy -target="module.eks" -auto-approve -var-file="workspaces/${env}.tfvars"
terraform destroy -target="module.vpc" -auto-approve -var-file="workspaces/${env}.tfvars"
terraform destroy -auto-approve -var-file="workspaces/${env}.tfvars"

popd