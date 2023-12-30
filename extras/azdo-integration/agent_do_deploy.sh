#!/bin/bash

calculateDeployment() {
    #Date in 12 Hour format (01-12)
    h=$(date +"%I")
    echo "H is $h"
    case $h in
    "12" | "06")
        Deployment_memory_problem
        ;;
    "01" | "07")
        Deployment_latest
        ;;
    "02" | "08")
        Deployment_memory_problem
        ;;
    "03" | "09")
        Deployment_latest
        ;;
    "04" | "10")
        Deployment_memory_problem
        ;;
    "05" | "11")
        Deployment_latest
        ;;
    esac
}

Deployment_latest() {
cd $(System.ArtifactsDirectory)/$(Release.PrimaryArtifactSourceAlias)
kubectl set image -n $(staging_namespace) deployment/transactionhistory transactionhistory=gcr.io/sales-engineering-emea/bank-of-anthos/transactionhistory:latest
kubectl rollout restart deployment/transactionhistory -n $(staging_namespace)
kubectl wait --for=condition=available --timeout=300s --all deployments --namespace $(staging_namespace)  || true
#kubectl delete deployment loadgenerator -n $(staging_namespace) || true
}

Deployment_memory_problem() {
kubectl set image -n $(staging_namespace) deployment/transactionhistory transactionhistory=gcr.io/sales-engineering-emea/bank-of-anthos/transactionhistory:memory-dtsaas
kubectl rollout restart deployment/transactionhistory -n $(staging_namespace)
kubectl wait --for=condition=available --timeout=300s --all deployments --namespace $(staging_namespace)  || true
#kubectl delete deployment loadgenerator -n $(staging_namespace) || true
}

#Deployment_latest
#Deployment_memory_problem
calculateDeployment