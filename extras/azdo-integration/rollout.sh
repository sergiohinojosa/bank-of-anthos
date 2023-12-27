#!/bin/bash
# Default Variabes
REPOSITORY="gcr.io/sales-engineering-emea/bank-of-anthos"
VERSION="latest"
NAMESPACE="staging-banking"

# This might not be needed
setDefaultValues() {
    #TODO Set NS and Version from Arguments
    if [ -z ${NAMESPACE+x} ]; then

        export NAMESPACE="staging-banking"
        echo "NAMESPACE is unset setting to '$NAMESPACE'"
    else
        echo "NAMESPACE is set to '$NAMESPACE'"
    fi
}

printDeployments() {
    kubectl get deployments -n $NAMESPACE -o wide
}

rolloutDeployments() {
    echo "Setting all deployment images to Version:'$VERSION' of the namespace '$NAMESPACE'"
    for deployment in $(kubectl get deploy -n $NAMESPACE -o=jsonpath='{.items..metadata.name}'); do
        echo "Rolling up deployment for ${deployment}"
        # main container images == deployment
        container=$deployment
        # TODO Rename front image to frontend
        if [ "$deployment" = "frontend" ]; then
            container="front"
        fi
        # Bumping up deployment
        kubectl -n $NAMESPACE set image deployment/$deployment $container=$REPOSITORY/$deployment:$VERSION
    done
    echo "waiting for all deployments to be ready"
    kubectl wait --for=condition=available --timeout=300s --all deployments --namespace $(staging_namespace)  || true
}

getNodes() {
    for node in $(kubectl get nodes -o name); do
        echo "     Node Name: ${node##*/}"
        echo "Type/Node Name: ${node}"
        echo
    done
}

usage() {
    echo "================================================================"
    echo "Rollout helper to Rollout images for all deployments            "
    echo "in a given namespace                                            "
    echo "                                                                "
    echo "================================================================"
    echo "Usage: bash rollout.sh [-n namespace] [-v version]              "
    echo "                                                                "
    echo "     -n      Namespace. Default '$NAMESPACE'                    "
    echo "     -v      Version. Default '$VERSION'                        "
    echo "================================================================"
}


# Read Flags
while getopts n:v:h: flag; do
    case "${flag}" in
    n) NAMESPACE=${OPTARG} ;;
    v) VERSION=${OPTARG} ;;
    h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

# call functions after variables set
rolloutDeployments
