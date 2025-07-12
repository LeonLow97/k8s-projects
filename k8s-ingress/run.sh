#!/bin/bash

echo "***** Push Users Microservice image to local Docker Registry *****"
docker run -d -p 5000:5000 --name registry registry:3
cd users-service
docker build -t users-service .
docker tag users-service localhost:5000/users-service:latest
docker push localhost:5000/users-service:latest
cd ..

echo "***** Push Products Microservice image to local Docker Registry *****"
docker run -d -p 5000:5000 --name registry registry:3
cd products-service
docker build -t products-service .
docker tag products-service localhost:5000/products-service:latest
docker push localhost:5000/products-service:latest
cd ..

curl -X GET http://localhost:5000/v2/_catalog

echo "***** Setting up NGINX Ingress Controller *****"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo "***** Creating k8s-ingress project namespace *****"
kubectl create namespace k8s-ingress

echo "***** Set current context to k8s-ingress project namespace *****"
kubectl config set-context --current --namespace=k8s-ingress

echo "***** Applying Kubernetes Manifests - Ingress, Service, Deployment *****"
kubectl apply -f k8s
