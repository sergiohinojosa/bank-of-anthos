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

calculateVersion() {
    #Date in 12 Hour format (01-12)
    h=$(date +"%I")
    echo "The hour is $h"
    case $h in
    "12" | "06")
        VERSION="1.0.0"
        ;;
    "01" | "07")
        VERSION="1.0.1"
        ;;
    "02" | "08")
        VERSION="1.0.2"
        ;;
    "03" | "09")
        VERSION="1.0.0"
        ;;
    "04" | "10")
        VERSION="1.0.1"
        ;;
    "05" | "11")
        VERSION="1.0.2"
        ;;
    esac
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
    echo "Waiting for all pods of all deployments to be ready and running..."
    kubectl wait --for=condition=Ready --timeout=300s --all pods --namespace $NAMESPACE || true
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
    echo "     -v      Version. Calculated '$VERSION'                     "
    echo "================================================================"
}

calculateVersion
# Read Flags
while getopts n:v:h: flag; do
    case "${flag}" in
    n) NAMESPACE=${OPTARG} ;;
    v)  # overwrite version from pipeline
        VERSION=${OPTARG}
        ;;
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
