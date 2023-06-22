#!/bin/bash
set -e

clear
echo "------------------------------------------------------------------------------------------"
echo ""
echo "  _____    _    _                    ___           _                         ____ ____    "
echo " |_   _|__| | _| |_ ___  _ __       ( _ )         / \   _ __ __ _  ___      / ___|  _ \   "
echo "   | |/ _ \ |/ / __/ _ \| '_ \      / _ \/\      / _ \ | '__/ _  |/ _ \    | |   | | | |  "
echo "   | |  __/   <| || (_) | | | |    | (_>  <     / ___ \| | | (_| | (_) |   | |___| |_| |  "
echo "   |_|\___|_|\_\\__\___/|_| |_|     \___/\/    /_/   \_\_|  \__, |\___/     \____|____/   "
echo "                                                            |___/ "
echo ""
echo "------------------------------------------------------------------------------------------"

initK8SResources() {
  kubectl create namespace cicd | true
  kubectl create namespace argocd | true
  kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
  kubectl apply -f conf/k8s -n cicd
  kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/previous/v0.36.1/release.yaml
  cd argo-bootstrap/ 
  ./apply.sh
  cd -
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --set controller.publishService.enabled=true

  echo '-------------------------------------------------'
  echo 'Be patient while the pods are ready for you  '
  echo '-------------------------------------------------'

  while [[ $(kubectl get pods -l 'app in (tekton-pipelines-controller)' --all-namespaces -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pods ready..." && sleep 10; done
  while [[ $(kubectl get pods -l 'app in (tekton-dashboard)' --all-namespaces -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pods ready..." && sleep 10; done
}

installPoCResources() {
  echo ""
  echo "Deploying configmaps, tasks, pipelines and ArgoCD application"
  kubectl apply -f conf/argocd
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-clone/0.2/git-clone.yaml -n cicd
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/buildah/0.2/buildah.yaml -n cicd
  kubectl apply -f conf/tekton/git-access -n cicd
  kubectl apply -f conf/tekton/tasks -n cicd
  kubectl apply -f conf/tekton/pipelines -n cicd
  echo "Create ingress for argo & tekton"
  kubectl apply -f ingress-argo.yaml -n argocd
  kubectl apply -f ingress-tekton.yaml -n tekton-pipelines
  kubectl apply -f ingress-products.yaml -n default
}

showInfo() {
  echo ""
  echo ""
  echo "Execute 'kubectl proxy --port=8080' to expose the Tekton dashboard in the URL:"
  echo "http://localhost:8080/api/v1/namespaces/tekton-pipelines/services/tekton-dashboard:http/proxy/#/namespaces/cicd/pipelineruns"
  echo "-----"

  echo "Execute 'kubectl port-forward svc/argocd-server -n argocd 9080:443' to expose the Argo CD console "
  echo "http://localhost:9080"
  echo "User/Password: admin/admin123"
  echo ""
  echo ""
}

main() {
  initK8SResources
  installPoCResources
  showInfo
}

main
