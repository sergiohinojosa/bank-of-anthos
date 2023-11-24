#!/bin/bash


# Deploy the NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml

# Instrument NGINX for adding RUM to all ingresses (we use Classic Deployment)
# https://docs.dynatrace.com/docs/setup-and-configuration/setup-on-k8s/guides/instrument-ingress-nginx
kubectl apply -f ingress-cm-load-oneagent.yaml

# Read the domain from CM or variable DOMAIN (use export DOMAIN) like
#  export DOMAIN=2-2-2-2-sslip.io
# source ../util/loaddomain.sh

#kubectl create configmap -n default domain --from-literal=domain=${DOMAIN}
sed 's~domain.placeholder~'"$DOMAIN"'~' ingress.template > gen/ingress.yaml 

kubectl apply -f gen/ingress.yaml

