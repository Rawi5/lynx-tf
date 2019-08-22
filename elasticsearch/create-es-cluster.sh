#!/bin/bash

NAMESPACE=${1:-es-farm}

kubectl create ns $NAMESPACE

kubectl apply -f es-discovery-svc.yaml -n $NAMESPACE
kubectl apply -f es-svc.yaml -n $NAMESPACE

kubectl apply -f es-master-svc.yaml  -n $NAMESPACE
kubectl apply -f es-master-stateful.yaml -n $NAMESPACE
kubectl rollout status -f es-master-stateful.yaml -n $NAMESPACE

kubectl apply -f es-ingest-svc.yaml -n $NAMESPACE
kubectl apply -f es-ingest.yaml -n $NAMESPACE
kubectl rollout status -f es-ingest.yaml -n $NAMESPACE

kubectl apply -f es-data-svc.yaml -n $NAMESPACE
kubectl apply -f es-data-stateful.yaml -n $NAMESPACE
kubectl rollout status -f es-data-stateful.yaml -n $NAMESPACE

kubectl apply -f kibana-cm.yaml -n $NAMESPACE
kubectl apply -f kibana-svc.yaml -n $NAMESPACE
kubectl apply -f kibana.yaml -n $NAMESPACE

kubectl apply -f es-curator-config.yaml -n $NAMESPACE
kubectl apply -f es-curator.yaml -n $NAMESPACE
