#!/bin/bash
set -e

k3d registry create local-registry --port 5000
k3d cluster create tekton-poc-cluster -p "8888:80@loadbalancer" -p "9001:9001@loadbalancer" -p "9000:9000@loadbalancer" -p "9080:9080@loadbalancer" --registry-config "./conf/k3d/tekton-registry.yaml" -v /etc/machine-id:/etc/machine-id:ro -v /var/log/journal:/var/log/journal:ro -v /var/run/docker.sock:/var/run/docker.sock --k3s-arg '--disable=traefik@server:0' --agents 0
