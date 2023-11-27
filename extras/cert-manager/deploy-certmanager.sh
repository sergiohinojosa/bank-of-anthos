#!/bin/bash

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.11.0/cert-manager.yaml


# Export the Email for the issuer
cat clusterissuer.yaml | sed 's~email.placeholder~'"$EMAIL"'~' > ./gen/clusterissuer.yaml

# create cluster issuer
kubectl apply -f gen/clusterissuer.yaml
