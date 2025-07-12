#!/bin/bash

# Delete k8s objects
kubectl delete svc users-service products-service -n k8s-ingress
kubectl delete deploy users-deployment products-deployment -n k8s-ingress
kubectl delete ingress app-ingress-resource -n k8s-ingress

kubectl config set-context --current --namespace=default
