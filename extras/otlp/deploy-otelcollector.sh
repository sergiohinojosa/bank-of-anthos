#!/bin/bash

kubectl create ns opentelemetry

# Add your variables
export DT_ENDPOINT="https://tenantID.live.dynatrace.com/api/v2/otlp"
export DT_API_TOKEN="dt0c01.XXXX"

# Readfile, replace env variables execute kubectl and read from pipe
envsubst <  otel-collector-config.yaml | kubectl -n opentelemetry apply -f -