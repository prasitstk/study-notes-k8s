### Push the docker image into your registry on docker hub

- NOTE: Replace `<DockerHubId>` with `<your-docker-hub-id>`

```sh
cd App

# Build the image#
# docker image build -t <DockerHubId>/qsk-course:1.0 .
docker image build -t <your-docker-hub-id>/qsk-course:1.0 .

# Host the image on a registry#

## Login into your dockerhub account.
# docker login --username <DockerHubId>
docker login --username <your-docker-hub-id>

## Push the image into the registry (docker hub)
# docker image push <DockerHubId>/qsk-course:1.0
docker image push <your-docker-hub-id>/qsk-course:1.0
```







### Set up DigitalOcean resources

#### Set up doctl

Step 1: Install doctl
```sh
brew install doctl
```


Step 2: Create an API token

- Create a DigitalOcean API token for your account with read and write access from the Applications & API page in the control panel. The token string is only displayed once, so save it in a safe place.

- API (Applications & API) > Tokens/Keys > Generate new token > 
  - Name: k8s-test-01-token
  - Select scopes: 90 days
  - Select scopes: Read & Write
  - Generated token: dop_v1_468cff99e66e8397dc882adf85d352c901f9f4d36e8aa03a1e80bdd9533cf5b1


Step 3: Use the API token to grant account access to doctl

```sh
# doctl auth init --context <context_name>
doctl auth init --context playtorium
# Enter your access token: dop_v1_468cff99e66e8397dc882adf85d352c901f9f4d36e8aa03a1e80bdd9533cf5b1
```
- Authentication contexts let you switch between multiple authenticated accounts. You can repeat steps 2 and 3 to add other DigitalOcean accounts, then list and switch between authentication contexts
```sh
doctl auth list
# doctl auth switch --context <context_name>
doctl auth switch --context playtorium
```

Step 4: Validate that doctl is working

```sh
doctl account get
```


#### Set up a new Kubernetes cluster

Kubernetes > Create a Kubernetes cluster
- Region = SGP1
- Node pool name = k8s-test-01-node-pool
- Machine type = Basic
- Note plan = $12/monthper node
- Nodes = 2
- Cluster name = k8s-test-01-cluster





#### Set up DigitalOcean Container Registry

MANAGE > Container Registry > Create Registry
- Name: k8s-test-01-reg
- Region: SGP1
- Choose a plan: Starter (Free | 1 Repo | 500 MB)

Push image to Your Registry
```sh
# Authenticate Docker with your registry
doctl registry login

# Tag your image with the fully qualified destination path:
# docker tag <my-image> registry.digitalocean.com/<my-registry>/<my-image>
docker tag 2abce6a81cf2 registry.digitalocean.com/k8s-test-01-reg/qsk-course:1.0

# Upload your image
# docker push registry.digitalocean.com/<my-registry>/<my-image>
docker push registry.digitalocean.com/k8s-test-01-reg/qsk-course:1.0

# Try to run the image from other machine after pull it with
docker run -p 8082:8080 -d registry.digitalocean.com/k8s-test-01-reg/qsk-course:1.0
```

Use Images in Your Registry with Kubernetes
- Container Registry > Settings > DigitalOcean Kubernetes integration > Select `k8s-test-01-cluster`







### Connect to the Kubernetes cluster on your DigitalOcean account

```sh
# doctl kubernetes cluster kubeconfig save <cluster_ID>
doctl kubernetes cluster kubeconfig save 3894b206-29b7-4b1b-adfd-1e9640afccb1
# Notice: Adding cluster credentials to kubeconfig file found in "/Users/<username>/.kube/config"
# Notice: Setting current-context to do-sgp1-k8s-test-01-cluster

# Now you should see the current context is do-sgp1-k8s-test-01-cluster
kubectl config get-contexts
URRENT   NAME                          CLUSTER                       AUTHINFO                            NAMESPACE
*         do-sgp1-k8s-test-01-cluster   do-sgp1-k8s-test-01-cluster   do-sgp1-k8s-test-01-cluster-admin   
          docker-desktop                docker-desktop                docker-desktop

# View kubeconfig
kubectl config view

# Shows which is the active context
kubectl config current-context

# Allows you to switch between contexts using their name
# kubectl config use-context <CONTEXT_NAME>
kubectl config use-context docker-desktop
kubectl config use-context do-sgp1-k8s-test-01-cluster

# Verify cluster connectivity
## List your clusters on your DigitalOcean account
doctl kubernetes cluster list

## Show your cluster's kubeconfig YAML
# doctl kubernetes cluster kubeconfig show <cluster-id|cluster-name>
doctl kubernetes cluster kubeconfig show k8s-test-01-cluster

## Display addresses of the control plane and cluster services
kubectl cluster-info

## Display the client and server k8s version
kubectl version

## List all nodes created in the cluster
kubectl get nodes
```






### Start local kubernetes cluster on docker-desktop

Set Up Kubernetes Locally With Docker Desktop
- Docker Desktop Icon > Preferences > Kubernetes > Enable Kubernetes = true
- Wait for a single-node Kubernetes cluster running
- Verifying
```sh
docker --version
kubectl version -o yaml
```
- At this point, you have Docker and a single-node Kubernetes cluster running on your laptop.

If needed, switch kubectl context to docker-desktop
```sh
kubectl config use-context docker-desktop
```



### Follow `Getting Started with Kubernetes` educative.io tutorial on local cluster

If needed, switch kubectl context to docker-desktop
```sh
kubectl config use-context docker-desktop
```

Deploy a pod on the local cluster:
```sh
kubectl get nodes
# NAME             STATUS   ROLES                  AGE   VERSION
# docker-desktop   Ready    control-plane,master   3d    v1.22.5

# If currently you are in App folder
# cd ..
kubectl apply -f pod.yml

# Wait for sometime until the pod status is READY
kubectl get pods
# NAME        READY   STATUS    RESTARTS   AGE
# first-pod   1/1     Running   0          101s

# Get more detail about the pod
kubectl describe pod first-pod

# Once the Pod is in the running state, you can ensure that the application is running as intended by executing the following command in the terminal:
kubectl port-forward --address 0.0.0.0 first-pod 8082:8080
# Now you can access the remote pod on k8s DO cluster by: http://localhost:8082/
# Exit by Ctrl+C or Cmd+C

```


Deploy a service on the local cluster for pod connectivity
```sh
# Deploy a service on the local cluster
kubectl apply -f svc-local.yml

# Verify the Service is up and running.
kubectl get svc
# AME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          3d1h
# svc-local    NodePort    10.103.38.120   <none>        8080:31111/TCP   3m24s

# The CLUSTER-IP value is an IP address on the internal Kubernetes Pod network and is used by other Pods and applications running on the cluster. You won’t be connecting to that address.

# As this is a NodePort Service, it can be accessed by connecting to *any cluster Node* on port 31111 as is specified in the PORT(S) column.

# Your output will list another Service called Kubernetes. This is used internally by Kubernetes for Service discovery.

# you can connect to the application and view the web page in the browser tab: http://localhost:31111/

```

Clean up
```sh
kubectl delete svc svc-local
kubectl delete pod first-pod
```






### Follow `Getting Started with Kubernetes` educative.io tutorial on DigitalOcean Kubernetes cluster

If needed, switch kubectl context to do-sgp1-k8s-test-01-cluster
```sh
kubectl config use-context do-sgp1-k8s-test-01-cluster
```

Deploy a pod on the cluster:
```sh
kubectl get nodes
# NAME                          STATUS   ROLES    AGE     VERSION
# k8s-test-01-node-pool-7nfmh   Ready    <none>   93m     v1.23.9
# k8s-test-01-node-pool-7nyr6   Ready    <none>   2m32s   v1.23.9

# If currently you are in App folder
# cd ..
kubectl apply -f pod.yml

# Wait for sometime until the pod status is READY
kubectl get pods
# NAME        READY   STATUS    RESTARTS   AGE
# first-pod   1/1     Running   0          101s

# Get more detail about the pod
kubectl describe pod first-pod

# Once the Pod is in the running state, you can ensure that the application is running as intended by executing the following command in the terminal:
kubectl port-forward --address 0.0.0.0 first-pod 8082:8080
# Now you can access the remote pod on k8s DO cluster by: http://localhost:8082/
# Exit by Ctrl+C or Cmd+C

```


Deploy a service on the cloud (DO) for pod connectivity
```sh
# Deploys a load-balancer Service
kubectl apply -f svc-cloud.yml
# This will create a DO Load Balancer on DigitalOcean account as a resource of the cluster

# Verify its status
kubectl get svc
# Wait until its EXTERNAL-IP appears
# NAME         TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
# cloud-lb     LoadBalancer   10.245.169.69   139.59.217.129   80:32480/TCP   3m48s
# kubernetes   ClusterIP      10.245.0.1      <none>           443/TCP        3h38m

# See its detail
kubectl describe svc cloud-lb

# Now you can connect to your application with http://139.59.217.129:80

# Alternatively, you can also port-forward by using the following command in the terminal:
kubectl port-forward --address 0.0.0.0 service/cloud-lb 8083:80

# Now you can connect to your application with http://localhost:8083

# The value to the right of the colon in the PORT(S) column is the port the application is exposed on, via each cluster Node. For example, if you know the IP addresses of your cluster Nodes, you can connect to the application by connecting to any Node’s IP on the port listed to the right of the colon.
```

Let’s delete the Pod and the Service, so that you have a clean cluster at the start of the next chapter.
```sh
kubectl delete svc cloud-lb
# This will also delete DO Loab balancer

kubectl delete pod first-pod
```


Deploy Deployment and demonstrate pod self-healing
```sh
# deploy the Deployment to your cluster
kubectl apply -f deploy.yml

# Vefify deployment and pods
kubectl get deployments
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# qsk-deploy   5/5     5            5           41s

kubectl get pods
# NAME                          READY   STATUS    RESTARTS   AGE
# qsk-deploy-7fb59d8b85-4cxz9   1/1     Running   0          35s
# qsk-deploy-7fb59d8b85-6ltmt   1/1     Running   0          35s
# qsk-deploy-7fb59d8b85-bl6xd   1/1     Running   0          35s
# qsk-deploy-7fb59d8b85-nr62g   1/1     Running   0          35s
# qsk-deploy-7fb59d8b85-x9gml   1/1     Running   0          35s

# Demo pod failure by manually deleting one of the Pods
kubectl delete pod qsk-deploy-7fb59d8b85-x9gml

# After self-healing
kubectl get pods
# NAME                          READY   STATUS    RESTARTS   AGE
# qsk-deploy-7fb59d8b85-4cxz9   1/1     Running   0          3m56s
# qsk-deploy-7fb59d8b85-5m7gr   1/1     Running   0          34s    <<< This pod is newly created to replace the failed one.
# qsk-deploy-7fb59d8b85-6ltmt   1/1     Running   0          3m56s
# qsk-deploy-7fb59d8b85-bl6xd   1/1     Running   0          3m56s
# qsk-deploy-7fb59d8b85-nr62g   1/1     Running   0          3m56s

# lists all of the Pods on your cluster and the Node each Pod is running on. 
kubectl get pods -o wide
# NAME                          READY   STATUS    RESTARTS   AGE     IP             NODE                          NOMINATED NODE   READINESS GATES
# qsk-deploy-7fb59d8b85-4cxz9   1/1     Running   0          7m9s    10.244.0.194   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-5m7gr   1/1     Running   0          3m47s   10.244.0.81    k8s-test-01-node-pool-7nfmh   <none>           <none>
# qsk-deploy-7fb59d8b85-6ltmt   1/1     Running   0          7m9s    10.244.0.80    k8s-test-01-node-pool-7nfmh   <none>           <none>
# qsk-deploy-7fb59d8b85-bl6xd   1/1     Running   0          7m9s    10.244.0.175   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-nr62g   1/1     Running   0          7m9s    10.244.0.150   k8s-test-01-node-pool-7nyr6   <none>           <none>

# The next step will delete a Node and take any Pods with it. 
# The example will delete the k8s-test-01-node-pool-7nfmh Node on DigitalOcean directly

kubectl get nodes
# NAME                          STATUS   ROLES    AGE    VERSION
# k8s-test-01-node-pool-7nyr6   Ready    <none>   7h9m   v1.23.9

kubectl get deployments
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# qsk-deploy   3/5     5            3           11m

# Wait for a while

kubectl get deployments
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# qsk-deploy   5/5     5            5           12m

kubectl get pods -o wide
# NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                          NOMINATED NODE   READINESS GATES
# qsk-deploy-7fb59d8b85-2xgq6   1/1     Running   0          66s   10.244.0.240   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-4cxz9   1/1     Running   0          13m   10.244.0.194   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-bl6xd   1/1     Running   0          13m   10.244.0.175   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-lfrdg   1/1     Running   0          66s   10.244.0.231   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-nr62g   1/1     Running   0          13m   10.244.0.150   k8s-test-01-node-pool-7nyr6   <none>           <none>

# NOTE: The output shows that Kubernetes has created two new Pods to replace those lost when the k8s-test-01-node-pool-7nfmh Node was deleted. 
# All new Pods were scheduled to k8s-test-01-node-pool-7nyr6, as it was the only surviving Node in the cluster.

# On DO cluster, change the node size back to 2 and see that all pods still in k8s-test-01-node-pool-7nyr6 even if nodes are back to 2.
kubectl get nodes
# NAME                          STATUS   ROLES    AGE     VERSION
# k8s-test-01-node-pool-7nr3a   Ready    <none>   6m58s   v1.23.9
# k8s-test-01-node-pool-7nyr6   Ready    <none>   7h23m   v1.23.9

# NOTE: Although your cluster is back to having two Nodes, Kubernetes will not rebalance the Pods across both Nodes. As a result, you will end up with a two-node cluster and with all 5 Pods running on a single Node.

```


Deploy Deployment and demonstrate pod scaling
```sh
# Edit the deploy.yml file and set the spec.replicas field to 10.

# Use kubectl to re-send the updated file to Kubernetes. 
kubectl apply -f deploy.yml

# Wait for a while

# Verify 
kubectl get deployments
kubectl get deployment qsk-deploy
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# qsk-deploy   10/10   10           10          31m

# If you have been following the examples from the previous chapter, the 5 new Pods will probably all be scheduled on the new Node. This proves that Kubernetes is intelligent enough to schedule the new Pods, so that all 10 are balanced across the available Nodes in the cluster.
kubectl get pods -o wide
# NAME                          READY   STATUS    RESTARTS   AGE     IP             NODE                          NOMINATED NODE   READINESS GATES
# qsk-deploy-7fb59d8b85-2xgq6   1/1     Running   0          21m     10.244.0.240   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-4cxz9   1/1     Running   0          33m     10.244.0.194   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-7kqk7   1/1     Running   0          3m59s   10.244.0.71    k8s-test-01-node-pool-7nr3a   <none>           <none>
# qsk-deploy-7fb59d8b85-85kp9   1/1     Running   0          3m59s   10.244.0.86    k8s-test-01-node-pool-7nr3a   <none>           <none>
# qsk-deploy-7fb59d8b85-9znz9   1/1     Running   0          3m59s   10.244.0.43    k8s-test-01-node-pool-7nr3a   <none>           <none>
# qsk-deploy-7fb59d8b85-bl6xd   1/1     Running   0          33m     10.244.0.175   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-lfrdg   1/1     Running   0          21m     10.244.0.231   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-nr62g   1/1     Running   0          33m     10.244.0.150   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-wjjhq   1/1     Running   0          3m59s   10.244.0.77    k8s-test-01-node-pool-7nr3a   <none>           <none>
# qsk-deploy-7fb59d8b85-zzkrn   1/1     Running   0          3m59s   10.244.0.112   k8s-test-01-node-pool-7nr3a   <none>           <none>

# Manually scale the number of Pods back down to 5.
kubectl scale --replicas 5 deployment/qsk-deploy

# Wait for a while

# Verify
kubectl get pods -o wide
# NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                          NOMINATED NODE   READINESS GATES
# qsk-deploy-7fb59d8b85-2xgq6   1/1     Running   0          25m   10.244.0.240   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-4cxz9   1/1     Running   0          37m   10.244.0.194   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-bl6xd   1/1     Running   0          37m   10.244.0.175   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-lfrdg   1/1     Running   0          25m   10.244.0.231   k8s-test-01-node-pool-7nyr6   <none>           <none>
# qsk-deploy-7fb59d8b85-nr62g   1/1     Running   0          37m   10.244.0.150   k8s-test-01-node-pool-7nyr6   <none>           <none>

# IMPORTANT: If you’ve been following along, you’ll have 5 replicas running on the cluster. 
# However, the deploy.yml file still defines 10. 
# If at a later date you edit the deploy.yml file to specify a new version of the container image and re-send that to Kubernetes, you’ll also increase the number of replicas back up to 10. 
# This might not be what you want.

# So, edit deploy.yml on replicas = 5 along with the updated pod number
```

Deploy Deployment and Service to demonstrate pod scaling
```sh
kubectl apply -f deploy.yml -f svc-cloud.yml

# Verify
kubectl get deployments

kubectl get svc

# You’ll configure a rolling update that will force Kubernetes to update one replica at a time in a methodical manner until all 5 replicas are running on the new version.
# Edit deploy.yml and save it into rolling-update.yml by adding the following section:
#  minReadySeconds: 20
#  strategy:
#    type: RollingUpdate
#    rollingUpdate:
#      maxUnavailable: 0
#      maxSurge: 1

# Pull educative1/qsk-course:1.1 image to local docker registry
docker image pull educative1/qsk-course:1.1

# Tag the downloaded image as registry.digitalocean.com/k8s-test-01-reg/qsk-course:1.1
docker tag afdeb8378cb4 registry.digitalocean.com/k8s-test-01-reg/qsk-course:1.1

# Push the new image tag to DO Docker registry
docker push registry.digitalocean.com/k8s-test-01-reg/qsk-course:1.1

# Once you have made the changes, you will send the updated file to Kubernetes using the following command:
kubectl apply -f rolling-update.yml

# Kubernetes will now start replacing the Pods, one at a time, with a 20 second wait between each replacement.
# Monitor the progress
kubectl rollout status deployment qsk-deploy
# Waiting for deployment "qsk-deploy" rollout to finish: 3 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 3 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "qsk-deploy" rollout to finish: 1 old replicas are pending termination...
# Waiting for deployment "qsk-deploy" rollout to finish: 1 old replicas are pending termination...
# Waiting for deployment "qsk-deploy" rollout to finish: 1 old replicas are pending termination...
# deployment "qsk-deploy" successfully rolled out

# Run the following command and you will be able to review the updated application in the browser tab:
kubectl port-forward --address 0.0.0.0 service/cloud-lb 8083:80
# Now you can access the service by: http://localhost:8083/
```

Clean up
```sh
kubectl delete svc cloud-lb
kubectl delete deployment qsk-deploy
```





### References
- [Module 1 of Path: Kubernetes Essentials/Getting Started with Kubernetes]https://www.educative.io/module/1j8yMXCkjGqYGZ9Py/10370001/6734573953613824

- https://docs.digitalocean.com/products/kubernetes/quickstart/

- https://medium.com/@andrew.kaczynski/gitops-in-kubernetes-argo-cd-and-gitlab-ci-cd-5828c8eb34d6

- https://docs.digitalocean.com/reference/doctl/how-to/install/

- https://docs.digitalocean.com/products/container-registry/quickstart/

- https://www.containiq.com/post/kubectl-config-set-context-tutorial-and-best-practices

- https://stackoverflow.com/questions/37016546/kubernetes-how-do-i-delete-clusters-and-contexts-from-kubectl-config

- https://www.bmc.com/blogs/kubernetes-port-targetport-nodeport/

- https://phoenixnap.com/kb/kubectl-port-forward

