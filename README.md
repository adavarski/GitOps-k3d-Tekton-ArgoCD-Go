## Kubernetes - CI/CD with Tekton & Argo CD (DevOps Cloud-native CI/CD GitOps with Tekton & ArgoCD PoC)

This is a PoC to check Tekton, Argo CD and how both tools can work together following a GitOps way.

With this repo to show how a modern and cloud native CI/CD could be implemented within a Kubernetes environment. We’ll use two different tools:

- Tekton: to implement CI stages
- Argo CD: to implement CD stages (GitOps)

Note: write REST API sample app in `golang`.

### Tekton?

Tekton is an Open Source framework to build CI/CD pipelines directly over a Kuberentes cluster. It was originally developed at Google and was known as Knative pipelines.

Tekton defines a series of Kubernetes custom resources (CRDs) extending the Kubernetes API. Sorry, what that means? Ok, if we go to the Kubernetes official page, we can read the following definition: `Kubernetes objects are persistent entities in the Kubernetes system. Kubernetes uses these entities to represent the state of your cluster.`

So, examples of Kubernetes objects are: Pod, Service, Deployment, etc. Tekton builds its own objects to Kubernetes and deploys them into the cluster. If you feel curious about custom objects, here the official documentation is and you can also check the Tekton Github to see how these objects are. For instance, [Pipeline](https://github.com/tektoncd/pipeline/blob/main/config/300-pipeline.yaml) or [Task](https://github.com/tektoncd/pipeline/blob/main/config/300-task.yaml).


### Argo CD?

Argo CD is a delivery tool (CD) built for Kubernetes, based on GitOps movement. So, what that means? Basically that Argo CD works synchronizing “Kubernetes files” between a git repository and a Kubernetes cluster. That is, if there is a change in a YAML file, Argo CD will detect that there are changes and will try to apply those changes in the cluster.

Argo CD, like Tekton, also creates its own Kubernetes custom resources that are installed into the Kubernetes cluster.

Are they ready to be adopted?

We are facing two young platforms and that may imply that there are not many examples, documentation or even maturity failures, but it’s true that both tools are called to be the standard cloud native CI/CD according to the principal cloud players.


For instance, Tekton:

- Google Cloud: https://cloud.google.com/tekton?hl=es
- Red Hat, Openshift Pipelines based on Tekton: (https://www.openshift.com/learn/topics/pipelines)
- IBM: https://www.ibm.com/cloud/blog/ibm-cloud-continuous-delivery-tekton-pipelines-tools-and-resources
- Tanzu: https://tanzu.vmware.com/developer/guides/ci-cd/tekton-what-is/
- Jenkins X: pipelines based on Tekton (https://jenkins-x.io/es/docs/concepts/jenkins-x-pipelines)


And, talking about Argo CD:

- Red Hat: https://developers.redhat.com/blog/2020/08/17/openshift-joins-the-argo-cd-community-kubecon-europe-2020/
- IBM: https://www.ibm.com/cloud/blog/simplify-and-automate-deployments-using-gitops-with-ibm-multicloud-manager-3-1-2


### CI/CD Cloud Native?

We’re talking a lot about “cloud native” associated to Tekton & Argo CD but, what do we mean by that? Both Tekton and Argo CD are installed in the Kubernetes cluster and they are based on extending Kubernetes API. Let’s see it in detail:

- Scalability: both tools are installed in the cluster and because of that, they work creating pods to perform tasks. Pods are the way in which applications can scale horizontally … so, scalabilly are guaranteed.

- Portabillity: both tools are based on extending Kubernetes API, creating new Kubernetes objects. These objects can be installed in every Kubernetes cluster.

- Reusability: the different elements within the CI/CD process use the Kubernetes objects defined by Tekton and Argo CD in the same way that you work with deployments o service objects. That means that stages, tasks or applications are YAML files that you can store in some repository and use in every cluster with Tekton and Argo CD installed. For instance, it’s possible to use artifacts from Tekton catalog or even, it’s possible to use the Openshift catalog or building a custom one.




### What are we going to build?
We are going to build a simple CI/CD process, on Kubernetes, with these stages:

<img src="poc/doc/img/pipeline-gitops.png?raw=true" width="1000">

Note: TODO -> Black part

In this pipeline, we can see two different parts:

#### CI part, implemented by Tekton and ending with a stage in which a push to a repository is done.
- Checkout: in this stage, source code repository is cloned
- Build image: in this stage, we build the image and publish to local registry
- Push to GitOps repo: this is the final CI stage, in which Kubernetes descriptors are cloned from the GitOps repository, they are modified in order to insert commit info and then, a push action is performed to upload changes to GitOps repository

#### CD part, implemented by Argo CD, in which Argo CD detects that the repository has changed and perform the sync action against the Kubernetes cluster.
Does it mean that we can not implement the whole process using Tekton? No, it doesn’t. It’s possible to implement the whole process using Tekton but in this case, we want to show the Gitops concept.


### Hands-on!
Requirements
To execute this PoC it’s you need to have:

A Kubernetes cluster. If you don’t have one, you can create a K3D one using the script `poc/create-local-cluster.sh` but, obviously, you need to have installed:

- [Docker](https://docs.docker.com/engine/install/ubuntu/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [k3d](https://k3d.io/#installation)
- [tkn](https://tekton.dev/docs/cli/) (Note: Tekton CLI)
- [Skaffold](https://skaffold.dev)  (Note: Local Kubernetes Development)


#### Repository structure
We’ve used a single repo to manage the different projects. 

Basically:

- poc: this is the main folder. Here, you can find three scripts:
   - create-local-cluster.sh: this script creates a local Kubernetes cluster based on K3D.
   - delete-local-cluster.sh: this script removes the local cluster
   - setup-poc.sh: this script installs and configure everything neccessary in the cluster (Tekton, Argo CD, etc)
- resources: this the folder used to manage the two repositories (code and gitops):
   - sources-repo: source code of the service used in this poc to test the CI/CD process
   - gitops_repo: repository where Kubernetes files associated to the service to be deployed are



1) Fork
The first step is to fork the repo `https://github.com/adavarski/GitOps-k3d-Tekton-ArgoCD-Go` because:

You have to modify some files to add a token & You need your own repo to perform Gitops operations

2) Add Github token
It’s necessary to add a Github Personal Access Token to Tekton can perform git operations, like push to gitops repo. If you need help to create this token, you can follow these instructions: https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token

The token needs to be allowed with “repo” grants.

Once the token is created, you have to copy it in these files (## INSERT TOKEN HERE):
```
poc/conf/argocd/git-repository.yaml

apiVersion: v1
kind: Secret
metadata:
  annotations:
    managed-by: argocd.argoproj.io
  name: repo-gitops
  namespace: argocd
type: Opaque
stringData:
  username: adavarski
  password: ## INSERT TOKEN HERE

poc/conf/tekton/git-access/secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: git-auth
  namespace: tekton-poc
  annotations:
    tekton.dev/git-0: https://github.com
type: kubernetes.io/basic-auth
stringData:
  username: tekton
  password: ## INSERT TOKEN HERE
```

Note: In fact, for Argo CD, create secret with the token isn’t necessary because the gitops repository in Github has public access but it’s interesting to keep it in order to know what you need to do in case the repository be private.

3) Create Kubernetes cluster (optional)
This step is optional. If you already have a cluster, perfect, but if not, you can create a local one based on K3D, just executing the script `poc/create-local-cluster.sh`. This script creates the local cluster and configure the private image registry to manage Docker images.

4) Setup -> Run `poc/setup-poc.sh`
This step is the most important because installs and configures everything necessary in the cluster:

- Installs Tekton & Argo CD, including secrets to access to Git repo
- Creates the volume and claim necessary to execute pipelines
- Deploys Tekton dashboard
- Installs Tekton tasks and pipelines
- Git-clone (from Tekton Hub)
- Buildah (from Tekton Hub)
- Push to GitOps repo (custom task: poc/conf/tekton/tasks/push-to-gitops-repo.yaml)
- Installs Argo CD application, configured to check changes in gitops repository (resources/gitops_repo)

5) Explore and play

Once everything is installed, you can play with this project:

#### Tekton Part
Tekton dashboard just open this url in the browser: http://tekton.192.168.1.99.nip.io:8888

By that link you’ll access to PipelineRuns options and you’ll see a pipeline executing.

<img src="poc/doc/img/gitops-k3d-argocd-tekton-tekton-pipelinesruns.png?raw=true" width="1000">

Note: If there is some error we can redeploy/rerun tekton pipeline and tasks :

```
  kubectl delete -f conf/tekton/git-access -n cicd
  kubectl delete -f conf/tekton/tasks -n cicd
  kubectl delete -f conf/tekton/pipelines -n cicd

  kubectl apply -f conf/tekton/git-access -n cicd
  kubectl apply -f conf/tekton/tasks -n cicd
  kubectl apply -f conf/tekton/pipelines -n cicd

  ### use `tkn` (Tekton CLI) to list/check/etc.
  tkn pipeline list -n cicd
  tkn taskrun list -n cicd
  tkn task list -n cicd
  tkn pipeline logs -n cicd

```


If you want to check what Tasks are installed in the cluster, you can navigate to Tasks option.

<img src="poc/doc/img/gitops-k3d-argocd-tekton-tekton-tasks.png?raw=true" width="1000">

If you click in this tasksrun you’ll see the different executed stages:

<img src="poc/doc/img/gitops-k3d-argocd-tekton-tekton-tasksruns.png?raw=true" width="1000">

Each stage is executed by a pod. For instance, you can execute:

```
kubectl get pods -n cicd -l "tekton.dev/pipelineRun=products-ci-pipelinerun"

### Example:
$  kubectl get pods -n cicd -l "tekton.dev/pipelineRun=products-ci-pipelinerun"
NAME                                              READY   STATUS      RESTARTS   AGE
products-ci-pipelinerun-checkout-pod              0/1     Completed   0          4m50s
products-ci-pipelinerun-build-image-pod           0/3     Completed   0          4m50s
products-ci-pipelinerun-push-changes-gitops-pod   0/1     Completed   0          87s
``` 
to see how different pods are created to execute different stages.

Note: Ingresses
```
$ kubectl get ing --all-namespaces
NAMESPACE          NAME               CLASS   HOSTS                          ADDRESS         PORTS   AGE
tekton-pipelines   tekton-ingress     nginx   tekton.192.168.1.99.nip.io     192.168.240.2   80      60m
argocd             argocd-ingress     nginx   argocd.192.168.1.99.nip.io     192.168.240.2   80      60m
default            products-ingress   nginx   products.192.168.1.99.nip.io   192.168.240.2   80      60m
```

As we said before, the last stage in CI part consist on performing a push action to GitOps repository. In this stage, content from GitOps repo is cloned, commit information is updated in cloned files (Kubernentes descriptors) and a push is done. The following picture shows an example of this changes:

<img src="poc/doc/img/gitops-k3d-argocd-tekton-tekton-pipelines-update-git-repo.png?raw=true" width="1000">

####  Argo CD Part

To access to Argo CD dashboard just open this url in the browser:  http://argocd.192.168.1.99.nip.io:8888 (admin / `$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`)

In this dashboard you should be the “product service” application that manages synchronization between Kubernetes cluster and GitOps repository

<img src="poc/doc/img/gitops-k3d-argocd-tekton-argocd-products.png?raw=true" width="1000">

<img src="poc/doc/img/gitops-k3d-argocd-tekton-argocd-products-app.png?raw=true" width="1000">

This application is “healthy” but as the objects associated with Product Service (Pods, Services, Deployment,…etc) aren’t still deployed to the Kubernetes cluster, you’ll find a “unknown” sync status.

Once the “pipelinerun” ends and changes are pushed to GitOps repository, Argo CD compares content deployed in the Kubernetes cluster (associated to Products Service) with content pushed to the GitOps repository and synchronize Kubernetes cluster against the repository:

Finally, the sync status become “Synced”:

### Note: https://github.com/adavarski/homelab -> We can add additional system (grafana/prometheus/etc.) Apps & ApplicationSet via ArgoCD manifests (bootstrap root)
```
$ git clone https://github.com/adavarski/homelab
$ cd homelab/bootstrap/root/
$ ./apply.sh 
```

6) Testing Go app
```

$ kubectl get ing
NAME               CLASS   HOSTS                          ADDRESS         PORTS   AGE
products-ingress   nginx   products.192.168.1.99.nip.io   192.168.240.2   80      38m

$ API_URL="http://products.192.168.1.99.nip.io:8888/api/v1/products"

curl $API_URL \
    --include \
    --header "Content-Type: application/json" \
    --request "POST" \
    --data '{"id": "1","name": "bike","value": 4009.99}' \

curl $API_URL \
    --include \
    --header "Content-Type: application/json" \
    --request "POST" \
    --data '{"id": "2","name": "ebook x","value": 5.00}'

curl $API_URL \
    --include \
    --header "Content-Type: application/json" \
    --request "POST" \
    --data '{"id": "3","name": "Server z","value": 90000.00}'

$ curl $API_URL
[{"CreatedAt":"2023-06-22T13:35:25.641Z","UpdatedAt":"2023-06-22T13:35:25.641Z","DeletedAt":null,"ID":"1","name":"bike","value":4009.99,"active":false},{"CreatedAt":"2023-06-22T13:34:00.088Z","UpdatedAt":"2023-06-22T13:34:00.088Z","DeletedAt":null,"ID":"2","name":"ebook x","value":5,"active":false},{"CreatedAt":"2023-06-22T13:34:01.382Z","UpdatedAt":"2023-06-22T13:34:01.382Z","DeletedAt":null,"ID":"3","name":"Server z","value":90000,"active":false}]

$ curl $API_URL/1
{"CreatedAt":"2023-06-22T13:35:25.641Z","UpdatedAt":"2023-06-22T13:35:25.641Z","DeletedAt":null,"ID":"1","name":"bike","value":4009.99,"active":false}

curl $API_URL/1 \
    --include \
    --header "Content-Type: application/json" \
    --request "PUT" \
    --data '{"value": 11500.99}' 


$ curl $API_URL/1
{"CreatedAt":"2023-06-22T13:35:25.641Z","UpdatedAt":"2023-06-22T13:37:47.929Z","DeletedAt":null,"ID":"1","name":"bike","value":11500.99,"active":false}

curl $API_URL/3 \
    --include \
    --header "Content-Type: application/json" \
    --request "DELETE"

$ curl $API_URL
[{"CreatedAt":"2023-06-22T13:35:25.641Z","UpdatedAt":"2023-06-22T13:37:47.929Z","DeletedAt":null,"ID":"1","name":"bike","value":11500.99,"active":false},{"CreatedAt":"2023-06-22T13:34:00.088Z","UpdatedAt":"2023-06-22T13:34:00.088Z","DeletedAt":null,"ID":"2","name":"ebook x","value":5,"active":false}]
```

7) Delete the local cluster (optional )
If you create a local cluster in step 3, there is an script to remove the local cluster. This script is `poc/delete-local-cluster.sh`


#### TODO: Use jfrog or dockerhub registry (instead of k3d docker registry)
Note: kubectl create secret generic dockerhub --from-file=.dockerconfigjson=$HOME/.docker/config.json --type=kubernetes.io/dockerconfigjson


###  Local Development with Skaffold

K8s local development environment using K3d and skaffold:

<img src="poc/doc/img/architecture-skaffold-dev.png?raw=true" width="800">

#### services
- `api` REST;
- `mySql` database.

#### Start k3d & Skaffold deploy
```
$ poc/create-local-cluster.sh
$ skaffold run
Examples: skaffold run --tail; skaffold dev --port-forward  --trigger polling; skaffold dev --default-repo=k3d-registry.localhost:12345; 
```
#### methods
- Set API_URL
``` 
API_URL="http://localhost:8080/api/v1/products"
curl $API_URL

### get ALL products
curl $API_URL

### post add one product
curl $API_UR \
    --include \
    --header "Content-Type: application/json" \
    --request "POST" \
    --data '{"id": "1","name": "bike","value": 4009.99}' \

curl $API_URL \
    --include \
    --header "Content-Type: application/json" \
    --request "POST" \
    --data '{"id": "2","name": "ebook x","value": 5.00}'

curl $API_URL \
    --include \
    --header "Content-Type: application/json" \
    --request "POST" \
    --data '{"id": "3","name": "Server z","value": 90000.00}'

### get ONE product
curl $API_URL/1

### put change ONE product
curl $API_URL/1 \
    --include \
    --header "Content-Type: application/json" \
    --request "PUT" \
    --data '{"value": 11500.99}'    

### delete ONE product
curl $API_URL/1 \
    --include \
    --header "Content-Type: application/json" \
    --request "DELETE"
```
### Note: Example production-like GitFlow branching strategy with Argo & Tekton (GitOps):

<img src="poc/doc/img/gitops.png?raw=true" width="800">

<img src="poc/doc/img/GIT-2-git-glow_branching_strategy.png?raw=true" width="600">

```
### Makefile
.PHONY: build release-major release-minor release-patch

build:
	go build ..... 

release-major:
	$(eval MAJORVERSION=$(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1+1".0.0"}'))
	git checkout master
	git pull
	git tag -a $(MAJORVERSION) -m 'Release $(MAJORVERSION)'
	git push origin --tags

release-minor:
	$(eval MINORVERSION=$(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1"."$$2+1".0"}'))
	git checkout master
	git pull
	git tag -a $(MINORVERSION) -m 'Release $(MINORVERSION)'
	git push origin --tags

release-patch:
	$(eval PATCHVERSION=$(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1"."$$2"."$$3+1}'))
	git checkout master
	git pull
	git tag -a $(PATCHVERSION) -m 'Release $(PATCHVERSION)'
	git push origin --tags
```



