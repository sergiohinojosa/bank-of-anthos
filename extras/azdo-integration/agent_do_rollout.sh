#!/bin/bash

setDefaultValues() {
    # RELEASE_RELEASENAME is an Azdo Pipeline variable
    if [ -z "$RELEASE_RELEASENAME" ]; then
        echo "\$RELEASE_RELEASENAME is empty"
        RELEASE_RELEASENAME="Release-000"

        RELEASE_RELEASEID="001"
    fi
    # Default Variabes
    REPOSITORY="gcr.io/sales-engineering-emea/bank-of-anthos"
    VERSION="latest"
    JVM_OPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+ExitOnOutOfMemoryError -Xms256m -Xmx512m"
    LOG_LEVEL="info"
    imagePullPolicy="Always"
    APPLICATION="banking"
    ENVIRONMENT="development"
    NAMESPACE=${ENVIRONMENT}-${APPLICATION}
    YAMLFILE=$(date '+%Y-%m-%d_%H_%M_%S').yaml
    RESET_DB=false
    EXTRA_LATENCY_MILLIS=0

    # Release Info from AzDo
    DT_RELEASE_VERSION=${RELEASE_RELEASENAME##*-}
    DT_RELEASE_BUILD_VERSION=$RELEASE_RELEASENAME.$VERSION

    # RELEASE ID FROM AZDO
    #RELEASE_RELEASEID=387
    #RELEASE_RELEASENAME=Release-386
}

exportVariables() {
    # Export variables so they are available in the command 'envsubst'
    export REPOSITORY=$REPOSITORY
    export VERSION=$VERSION
    export JVM_OPTS=$JVM_OPTS
    export LOG_LEVEL=$LOG_LEVEL
    export imagePullPolicy=$imagePullPolicy
    export APPLICATION=$APPLICATION
    export ENVIRONMENT=$ENVIRONMENT
    export NAMESPACE=${ENVIRONMENT}-${APPLICATION}
    export RELEASE_RELEASEID=${RELEASE_RELEASENAME##*-}
    export DT_RELEASE_VERSION=${RELEASE_RELEASENAME##*-}
    export DT_RELEASE_BUILD_VERSION=$RELEASE_RELEASENAME.$VERSION
    # Envs with problems
    export EXTRA_LATENCY_MILLIS=$EXTRA_LATENCY_MILLIS

    

}

printOutput() {
    echo ""
    echo -e "\tApplying  Deployment configuration with the following variables:"
    echo ""
    echo -e "\tREPOSITORY\t\t\t$REPOSITORY"
    echo -e "\tVERSION\t\t\t\t$VERSION"
    echo -e "\tJVM_OPTS\t\t\t$JVM_OPTS"
    echo -e "\tLOG_LEVEL\t\t\t$LOG_LEVEL"
    echo -e "\tRESET_DB\t\t\t$RESET_DB"
    echo -e "\timagePullPolicy\t\t\t$imagePullPolicy"
    echo -e "\tAPPLICATION\t\t\t$APPLICATION"
    echo -e "\tENVIRONMENT\t\t\t$ENVIRONMENT"
    echo -e "\tDT_RELEASE_VERSION\t\t$DT_RELEASE_VERSION"
    echo -e "\tDT_RELEASE_BUILD_VERSION\t$DT_RELEASE_BUILD_VERSION"
    echo -e "\tYAMLFILE\t\t\t$YAMLFILE can be found under 'gen' folder"

}

calculateVersion() {
    #Date in 12 Hour format (01-12)
    # Problems in PODs
    # BalanceReader 1.0.1  - CPU Issue
    # LedgeWriter 1.0.2  - MemoryLeak
    # TransactionHistory 1.03 - Synch Issue (synchronized + sleep)
    # ENV Variable EXTRA_LATENCY_MILLIS for Production 
    h=$(date +"%I")
    case $h in
    "12" | "04" | "08" )
        VERSION="1.0.0"
        PROBLEM="none"
        ;;
    "01" | "05" | "09")
        VERSION="1.0.1"
        PROBLEM="cpu"
        ;;
    "02" | "06" | "10")
        VERSION="1.0.2"
        PROBLEM="memory"
        ;;
    "03" | "07"| "11")
        VERSION="1.0.3"
        PROBLEM="n+1"
        ;;
    esac
    echo "The hour is $h and the Version selected is $VERSION with the problem $PROBLEM"
}

printDeployments() {
    echo "The new deployments now look like:"
    kubectl get deployments -n $NAMESPACE -o wide || true
}

rolloutDeployments() {
    # This function deprecated. It gets all deployments and iterates over each and changes the image name and its version.
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
    
    kubectl wait --for=condition=Ready --timeout=300s --all pods --namespace $NAMESPACE -l='app.kubernetes.io/version=$VERSION'
}

resetDatabase() {
    if $RESET_DB; then
        echo "Resetting database, stateful pods will be recycled"
        kubectl delete pod -n $NAMESPACE accounts-db-0 ledger-db-0
    else
        echo "No database will be resetted"
    fi
}

createApp(){

    exportVariables

    # If we are in AZDO then
    if [ -z "$AGENT_RELEASEDIRECTORY" ]; then
        echo "Running locally"
    else
        echo "Running in AzDo Agent machine"
        cd $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/extras/azdo-integration
    fi

    envsubst < banking.yaml > gen/banking-$YAMLFILE

    kubectl apply -f gen/banking-$YAMLFILE -n $NAMESPACE

}

applyDeploymentChange() {
    printOutput

    resetDatabase

    #envsubst <cluster/deploy.yaml | deployment-dev.yaml
    # Put in a generated file for logging.

    # If we are in AZDO then
    if [ -z "$AGENT_RELEASEDIRECTORY" ]; then
        echo "Running locally"
    else
        echo "Running in AzDo Agent machine"
        cd $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/extras/azdo-integration
    fi
    
    envsubst < deployments.yaml > gen/deploy-$YAMLFILE

    kubectl apply -f gen/deploy-$YAMLFILE
    # If we want to do an inliner
    # kubectl apply -f <( envsubst < deployment.yaml )
    echo "Waiting for all pods of all deployments to be ready and running..."
    
    # TODO Fix this and add label to pods, swap for sleep
    #kubectl wait --for=condition=Ready --timeout=300s --all pods --namespace $NAMESPACE || true
    sleep 150 || true
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
    echo "Usage: bash rollout.sh [-e environment (development/staging     "
    echo " production)] [-v version]                                      "
    echo "                                                                "
    echo "     -e      Environment. Default '$ENVIRONMENT'                "
    echo "             Namespace=Environment-Application                  "
    echo "     -v      Version. Calculated '$VERSION'                     "
    echo "     -d      Delete Database - Any argument e.g (yes)           "
    echo "     -c      Create Structure (svc, sa, secrets, config)        "
    echo "================================================================"
}

setDefaultValues
calculateVersion

# Read Flags
while getopts e:v:d:h:c: flag; do
    case "${flag}" in
    # we do another case for the stages
    e)
        case "${OPTARG}" in
        development)
            ENVIRONMENT="development"
            ;;
        staging)
            ENVIRONMENT="staging"
            ;;
        production)
            ENVIRONMENT="production"
            ;;
        *)
            echo "not a valid environment"
            exit 1
            ;;
        esac
        ;;
    v) # overwrite version from pipeline
        VERSION=${OPTARG}
        PROBLEM="manual_overwrite"
        ;;
    d) # we delete/init the statefulset database
        RESET_DB=true
        ;;
    h)
        usage
        exit 0
        ;;
    c) # create all
        createApp
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done


setOutputVariables() 
{
echo "##vso[task.setvariable variable=DT_RELEASE_VERSION]$DT_RELEASE_VERSION"
echo "##vso[task.setvariable variable=DT_RELEASE_BUILD_VERSION]$DT_RELEASE_BUILD_VERSION"
echo "##vso[task.setvariable variable=REPOSITORY]$REPOSITORY"
echo "##vso[task.setvariable variable=APPLICATION]$APPLICATION"
echo "##vso[task.setvariable variable=ENVIRONMENT]$ENVIRONMENT"
echo "##vso[task.setvariable variable=NAMESPACE]$NAMESPACE"
echo "##vso[task.setvariable variable=PROBLEM]$PROBLEM"
}


exportVariables

applyDeploymentChange

printDeployments

setOutputVariables
