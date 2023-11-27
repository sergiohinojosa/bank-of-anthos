#!/bin/bash

setupMagicDomainPublicIp() {
  echo "Setting up the Domain"
  if [ -n "${DOMAIN}" ]; then
    echo "The following domain is defined: $DOMAIN"
    export DOMAIN
  else
    echo "No DOMAIN is defined, converting the public IP in a magic sslip.io domain"
    # https://unix.stackexchange.com/a/81699/37512
    PUBLIC_IP_AS_DOM=$(dig @resolver4.opendns.com myip.opendns.com +short -4 | sed 's~\.~-~g')
    export DOMAIN="${PUBLIC_IP_AS_DOM}.sslip.io"
    echo "Magic Domain: $DOMAIN"
  fi
  # Now we save the DOMAIN in a ConfigMap
  kubectl create configmap -n default domain --from-literal=domain=${DOMAIN}
}

readDomain(){
    DOMAIN=$(kubectl get configmap domain -n default -ojsonpath={.data.domain})
    # -n verify if the variable is non-zero
    if [ -n "${DOMAIN}" ]; then
      echo "The following domain is defined in the configmap: $DOMAIN"
      echo "kubectl get cm -n default domain -o=jsonpath='{.data.domain}'"
      export DOMAIN
    else
      echo "The Domain is not defined."
      echo "Setting it up from public ip"
      setupMagicDomainPublicIp
    fi
}
readDomain