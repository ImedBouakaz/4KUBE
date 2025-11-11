#!/bin/bash

# Namespaces
kubectl apply -f /vagrant/api-deployment/api-namespace.yaml
kubectl apply -f /vagrant/position-simulator/position-sim-namespace.yaml
kubectl apply -f /vagrant/webapp/webapp-namespace.yaml
kubectl apply -f /vagrant/mongodb/namespace.yaml
kubectl apply -f /vagrant/truck-queue/namespace-trucks-queue.yaml
kubectl apply -f /vagrant/position-tracker/position-tracker-namespace.yaml

# PV MongoDB
kubectl apply -f /vagrant/mongodb/pv-mongo.yaml

# Deployments
kubectl apply -f /vagrant/mongodb/statefulset-mongo.yaml
kubectl apply -f /vagrant/truck-queue/deployment-trucks-queue.yaml
kubectl apply -f /vagrant/api-deployment/api-deploy.yaml
kubectl apply -f /vagrant/position-simulator/position-sim-deploy.yaml
kubectl apply -f /vagrant/position-tracker/position-tracker-deploy.yaml
kubectl apply -f /vagrant/webapp/webapp-deploy.yaml

# Services

kubectl apply -f /vagrant/mongodb/svc-clusterip.yaml
kubectl apply -f /vagrant/truck-queue/service-trucks-queue.yaml
kubectl apply -f /vagrant/api-deployment/api-service.yaml
kubectl apply -f /vagrant/position-simulator/position-sim-service.yaml
kubectl apply -f /vagrant/position-tracker/position-tracker-service.yaml
kubectl apply -f /vagrant/webapp/webapp-service.yaml

# Port-Forward
kubectl port-forward --namespace webapp svc/webapp-service-cluster 30080:80