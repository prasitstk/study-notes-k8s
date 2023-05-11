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


### LAB001: Let's Run Our First Application on local cluster

Related files:
- lab001/nginx.yaml
- lab001/apache.yaml

Try with `nginx`:
```sh
cd lab001
# Check some nodes exist
kubectl get nodes

# Check no pods in the cluster
kubectl get pods

# Deploy a pod in nginx.yaml
kubectl apply -f nginx.yaml

# Verify
kubectl get pods
# NAME        READY   STATUS              RESTARTS
# nginx       0/1     ContainerCreating   0   
# NOTE: The ContainerCreating status means Kubernetes is downloading the nginx image so we can run it locally. After a few seconds, if you run this command again, you will see the pod is now in the Running state.

kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          58s

# The nginx image is downloaded
docker image ls
# REPOSITORY                                                                   TAG                                                     IMAGE # ID       CREATED         SIZE
# nginx                                                                        latest                                                  b692a91e4e15   2 days ago      142MB

# The nginx docker container also running
docker image ps
# CONTAINER ID   IMAGE     COMMAND                  CREATED              STATUS              PORTS     NAMES
# 1352e2787016   nginx     "/docker-entrypoint.…"   About a minute ago   Up About a minute             k8s_nginx-container_nginx_default_1bd9d76d-64f6-456f-bcde-ca08370db5f1_0

# With the below command, you can access to nginx with: http://localhost:3000
kubectl port-forward --address 0.0.0.0 nginx 3000:80
# NOTE: Please wait for the pods to be in a running state before executing the port-forward command.

# If you would like to run it on background:
nohup kubectl port-forward --address 0.0.0.0 nginx 3000:80 > /dev/null 2>&1 &

# To see everything the logging of the pod to stdout.
# NOTE: tells kubectl to keep streaming the logs live, instead of just printing and exiting 
kubectl logs --follow nginx

# We can also execute arbitrary commands in a container running in our pod.
# For example, run the `ls` command in our nginx container:
kubectl exec nginx -- ls

# We can also run an interactive session using the -it flags. 
# For example, we can start a bash session in this container:
kubectl exec -it nginx -- bash
# root@nginx:/# 

# Let’s try to change something in this container to see what happens:
# root@nginx:/ echo "it works!" > /usr/share/nginx/html/index.html
# Now if you try refreshing the page, you will see this change.

# NOTE: our changes are lost as soon as we restart the pod.

# Exit from the pod
# root@nginx:/# exit

# Killing pods
kubectl delete pod nginx
# OR
kubectl delete -f nginx.yaml

# Verify
kubectl get pods
```

Try with `apache`
```sh
kubectl apply -f apache.yaml
kubectl get pods
nohup kubectl port-forward --address 0.0.0.0 apache 3001:80 > /dev/null 2>&1 &
kubectl exec -it apache -- sh
echo "Welcome to Apache!" > /usr/local/apache2/htdocs/index.html
# Check with http://localhost:3001 to see the updated home page.
```

### LAB002: Deployments

Self-healing by Deployment
```sh
cd lab002

# Log in to DockerHub
docker login --username <your-docker-hub-id>

# Build the image
docker image build -t <your-docker-hub-id>/hellok8s:v1 .

# Push the image into the DockerHub
docker image push <your-docker-hub-id>/hellok8s:v1

# Create a deployment object on the cluster
kubectl apply -f deployment.yaml

# Verify
kubectl get deployments
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# hellok8s   1/1     1            1           8s

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-846dfb6b77-n7jxx   1/1     Running   0          12s

# After run the below command, go to http://localhost:3003 to see something.
nohup kubectl port-forward --address 0.0.0.0 hellok8s-846dfb6b77-n7jxx 3003:4567 > /dev/null 2>&1 &
# NOTE: --address 0.0.0.0 is optional if you run on local, not in educative platform

# Try to kill the running pod
kubectl delete pod hellok8s-846dfb6b77-n7jxx

# Wait for a while and try to verify that the deployment create a NEW pod to replace the old one.
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-846dfb6b77-7rg4r   1/1     Running   0          9s

# Verify that it is still workable at http://localhost:3003
nohup kubectl port-forward --address 0.0.0.0 hellok8s-846dfb6b77-7rg4r 3003:4567 > /dev/null 2>&1 &
```

Scale up/down by Deployment
```sh
# Change deployment.yaml from replicas: 1 to replicas: 10 and then save it to scaleup.yaml and then:
kubectl apply -f scaleup.yaml

# Verify = 10 running pods
kubectl get deployments
kubectl get pods

# For scale down the cluster, do the same thing but change to replicas: 2 and reapply again:
kubectl apply -f scaledown.yaml

# Verify = 2 running pods
kubectl get deployments
kubectl get pods
```

Rolling update by Deployment
```sh
# Update app.rb and rebuild it and push it to the DockerHub
docker image build -t <your-docker-hub-id>/hellok8s:v2 .
docker image push <your-docker-hub-id>/hellok8s:v2

# Before rolling update
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-846dfb6b77-7rg4r   1/1     Running   0          30m
# hellok8s-846dfb6b77-npllv   1/1     Running   0          18m

# Copy scaledown.yaml to rollingupdate.yaml and edit the image to `image: <your-docker-hub-id>/hellok8s:v2`
# Re-apply the Deployment
kubectl apply -f rollingupdate.yaml

# Verify 
kubectl get pods --watch
# NOTE: We can use the --watch flag to watch changes to a command output. For example, kubectl get pods --watch will print a new line for every change in its output.

# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-846dfb6b77-7rg4r   1/1     Running   0          32m
# hellok8s-846dfb6b77-npllv   1/1     Running   0          21m
# hellok8s-768f44c896-pcmsk   0/1     Pending   0          0s
# hellok8s-768f44c896-pcmsk   0/1     Pending   0          0s
# hellok8s-768f44c896-pcmsk   0/1     ContainerCreating   0          0s
# hellok8s-768f44c896-pcmsk   1/1     Running             0          2s
# hellok8s-846dfb6b77-7rg4r   1/1     Terminating         0          33m
# hellok8s-768f44c896-wv2wf   0/1     Pending             0          0s
# hellok8s-768f44c896-wv2wf   0/1     Pending             0          0s
# hellok8s-768f44c896-wv2wf   0/1     ContainerCreating   0          0s
# hellok8s-846dfb6b77-7rg4r   0/1     Terminating         0          33m
# hellok8s-846dfb6b77-7rg4r   0/1     Terminating         0          33m
# hellok8s-846dfb6b77-7rg4r   0/1     Terminating         0          33m
# hellok8s-768f44c896-wv2wf   1/1     Running             0          3s
# hellok8s-846dfb6b77-npllv   1/1     Terminating         0          22m
# hellok8s-846dfb6b77-npllv   0/1     Terminating         0          22m
# hellok8s-846dfb6b77-npllv   0/1     Terminating         0          22m
# hellok8s-846dfb6b77-npllv   0/1     Terminating         0          22m

# Now if we apply this manifest and keep watching the pods we have running, we will see Kubernetes starting new pods that use the v2 image but terminating the old pods.

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-768f44c896-pcmsk   1/1     Running   0          44s
# hellok8s-768f44c896-wv2wf   1/1     Running   0          41s

# After run the below command, go to http://localhost:3003 to see something updated!
nohup kubectl port-forward hellok8s-768f44c896-pcmsk 3003:4567 > /dev/null 2>&1 &

# NOTE:
# The kind of release that was done is called a RollingUpdate, which means we first create one pod with the new version. 
# And after it’s running, we terminate one pod running the previous versions, and we keep doing that until all the pods running are using the desired version.
```

Rolling update with `maxSurge` and `maxUnavailable`
- NOTE: Kubernetes will ensure that during this rollout we will have `a minimum of 2 (desired - maxUnavailable)` and `maximum of 4 (desired + maxSurge)` replicas.
```sh
# Copy and update rollingupdate.yaml to rollingupdate-2.yaml with
#  spec:
# +  strategy:
# +    rollingUpdate:
# +     maxSurge: 1
# +     maxUnavailable: 1
# * replicas: 3

# Apply deployment change to the cluster
kubectl apply -f rollingupdate-2.yaml
# During this rollout Kubernetes will ensure that we will have a minimum of 2 pods and maximum of 4 pod replicas.

# Verify 
kubectl get pods --watch
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-768f44c896-pcmsk   1/1     Running   0          16m
# hellok8s-768f44c896-vkztm   1/1     Running   0          17s
# hellok8s-768f44c896-wv2wf   1/1     Running   0          16m

```

Recreate instead of Rolling update by Deployment
- NOTE: 
  - As you may have noticed, when we are using the `rollingUpdate` strategy (which is the default) we will have, 
    - ** for a period of time, both versions of our application (v1 and v2) running in parallel. 
  - If we don’t want that to happen for any reason, we can configure the Deployments with a different strategy called `Recreate`:
- NOTE:
  - After apply, ALL our pods will be terminated! then pods using the new version will be created. 
  - ** Unfortunately, this creates a period of downtime while the new pods are being created:
```sh
# Update the Deployment manifest to:
# *  strategy:
# *    type: Recreate
# -  strategy:
# -    rollingUpdate:
# -      maxSurge: 1
# -      maxUnavailable: 1
```

Manually blocking the bad release (= Undo the latest deployment back to the previous one)
```sh
# Edit app.rb to the buggy version

# Re-build and push the buggy image to the DockerHub
docker image build -t <your-docker-hub-id>/hellok8s:buggy .
docker image push <your-docker-hub-id>/hellok8s:buggy

# Update rollingupdate-2.yaml to rollingupdate-3.yaml with:
# * - image: <your-docker-hub-id>/hellok8s:buggy

# Apply the buggy version
kubectl apply -f rollingupdate-3.yaml

# Verify
kubectl get pods --watch
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-5bdc8fc7cb-2sl6q   1/1     Running   0          21s
# hellok8s-5bdc8fc7cb-fms4b   1/1     Running   0          20s
# hellok8s-5bdc8fc7cb-j8mfz   1/1     Running   0          15s

# After run the below command, go to http://localhost:3003 to see something failed after three times!
nohup kubectl port-forward hellok8s-5bdc8fc7cb-2sl6q 3003:4567 > /dev/null 2>&1 &

# we can easily rollback this release with:
kubectl rollout undo deployment hellok8s

# Verify
kubectl get pods --watch
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-768f44c896-fsghc   1/1     Running   0          22s
# hellok8s-768f44c896-htdkb   1/1     Running   0          16s
# hellok8s-768f44c896-zxwxz   1/1     Running   0          23s

# After run the below command, go to http://localhost:3003 to see the v2 is back!
nohup kubectl port-forward hellok8s-768f44c896-fsghc 3003:4567 > /dev/null 2>&1 &
```

Automatically blocking bad releases with `readinessProbe`:
```sh
# copy rollingupdate-2.yaml to rollingupdate-2-readinessProbe.yaml and update it:
#        containers:
#        - image: brianstorti/hellok8s:v2 # Still using v2
#          name: hellok8s-container
# +        readinessProbe:
# +          periodSeconds: 1
# +          successThreshold: 5
# +          httpGet:
# +            path: /
# +            port: 4567
# NOTE: Here’s what this is doing; We are telling Kubernetes that it should consider this container ready to start receiving requests ONLY after it has received five successful responses from a GET request to the / path on port 4567. And that it should send this request once every second.

# Re-apply change
kubectl apply -f rollingupdate-2-readinessProbe.yaml

# Verify 
kubectl get pods --watch
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-679f78bc75-4gxpm   1/1     Running   0          45s
# hellok8s-679f78bc75-797tn   1/1     Running   0          52s
# hellok8s-679f78bc75-hk8jg   1/1     Running   0          53s

# Try to update to buggy version by edit rollingupdate-2-readinessProbe.yaml to rollingupdate-3-readinessProbe.yaml:
# * - image: <your-docker-hub-id>/hellok8s:buggy

# Re-apply change
kubectl apply -f rollingupdate-3-readinessProbe.yaml

# Verify 
kubectl get pods --watch
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-679f78bc75-4gxpm   1/1     Running   0          2m6s
# hellok8s-679f78bc75-797tn   1/1     Running   0          2m13s
# hellok8s-8479dc9bcf-l5mm8   0/1     Running   0          34s
# hellok8s-8479dc9bcf-wqqwx   0/1     Running   0          33s

# NOTE: 
# - Now we can see that Kubernetes created a new pod (hellok8s-68f47f657c-zwn6g) and that this pod is running. 
# - But if we check the READY column, it says 0/1. That is, from the 1 container we had to run in this pod 0 are ready, which will prevent Kubernetes from sending it any requests. 
# - But more importantly, it will prevent Kubernetes from terminating the pods that we currently have running.

# To debug exactly what is happening, we can use:
kubectl describe pod hellok8s-8479dc9bcf-l5mm8
kubectl describe pod hellok8s-8479dc9bcf-wqqwx

# A readinessProbe can be used to prevent bad releases from happening in obvious cases like this, but it can also be used to ensure everything is ready for this pod to start receiving requests. 
# It could, for example, warm a cache, or check that another external dependency is available. Only then, signal to Kubernetes that it is ready.

# we can easily rollback this release with:
kubectl rollout undo deployment hellok8s

# Verify
kubectl get pods --watch
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-679f78bc75-4gxpm   1/1     Running   0          5m44s
# hellok8s-679f78bc75-797tn   1/1     Running   0          5m51s
# hellok8s-679f78bc75-tbs6w   1/1     Running   0          38s    >>> NOTE: This is the new one that replace the failed one

# After run the below command, go to http://localhost:3003 to see the v2 is back!
nohup kubectl port-forward hellok8s-679f78bc75-tbs6w 3003:4567 > /dev/null 2>&1 &

```

Keeping Applications Healthy with Liveness Probes
```sh
# copy rollingupdate-2-readinessProbe.yaml to rollingupdate-2-livenessProbe.yaml and update it:
#       - image: brianstorti/hellok8s:v2
#         name: hellok8s-container
#         readinessProbe:
#           periodSeconds: 1
#           successThreshold: 5
#           httpGet:
#             path: /
#             port: 4567
# +        livenessProbe:
# +          httpGet:
# +            path: /
# +            port: 4567
# NOTE: 
# - This will keep pinging the / path every few seconds to make sure the container is healthy. 
# - The period is 10 seconds by default, but this can also be changed with the periodSeconds attribute. 
# - If it starts receiving a 5xx status code from this endpoint, 
#  - ** it will automatically restart the container.

# Re-apply change
kubectl apply -f rollingupdate-2-livenessProbe.yaml

# Verify 
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-6577fc8554-kd62m   1/1     Running   0          24s
# hellok8s-6577fc8554-vkfhf   1/1     Running   0          17s
# hellok8s-6577fc8554-xbbdx   1/1     Running   0          25s



# NOTE: we can also define a custom command to run in the container. If the command exits with a success status code, the probe passes or otherwise it fails.

# For example, let’s say our container has a script called check_health.sh that will do all the necessary checks to decide if the container is in good shape or not. We could define that in our manifest like this:
#      containers:
#      - image: brianstorti/hellok8s:v2
#        name: hellok8s-container
#        readinessProbe:
#          periodSeconds: 1
#          successThreshold: 5
#          httpGet:
#            path: /
#            port: 4567
# +      livenessProbe:
# +        exec:
# +          command:
# +            - check_health.sh

# Kubernetes would then run this script every few seconds, just like it did for our http requests and consider the container healthy while the script returns a 0 (success) status code.
```


### LAB003: Services

Set up and build updated image
```sh
# make sure that we live in the docker-desktop kubectl context
kubectl config get-contexts
kubectl config use-context docker-desktop

cd lab003

# Log in to DockerHub
docker login --username <your-docker-hub-id>

# Build the image
docker image build -t <your-docker-hub-id>/hellok8s:v3 .

# Push the image into the DockerHub
docker image push <your-docker-hub-id>/hellok8s:v3
```

Demo: Same hostname to nodePort of the NodePort service will randomly distribute requrests to all the pods behine the service.
```sh
kubectl apply -f deployment.yaml
# verify
kubectl get deployments
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# hellok8s   2/2     2            2           2m48s

kubectl apply -f service.yaml
# verify
kubectl get svc
# NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
# hellok8s-svc   NodePort    10.105.114.193   <none>        4567:30001/TCP   2m50s

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-74bd687bcf-fmsq5   1/1     Running   0          4m9s
# hellok8s-74bd687bcf-n42sb   1/1     Running   0          4m9s

# Try with http://localhost:30001 you should see:
# [v3] Hello, Kubernetes, from hellok8s-74bd687bcf-fmsq5!
# or sometime you can see
# [v3] Hello, Kubernetes, from hellok8s-74bd687bcf-n42sb!
# randomly...

# Clean up
kubectl delete svc hellok8s-svc
kubectl delete deployment hellok8s
```

Demo: ClusterIP service type (default service type)
```sh
kubectl apply -f nginx.yaml
kubectl apply -f deployment.yaml

# verify
kubectl get svc
# NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
# clusterip-svc   ClusterIP   10.100.181.251   <none>        80/TCP    25s
# kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP   8d

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-74bd687bcf-ll9q4   1/1     Running   0          21s
# hellok8s-74bd687bcf-qhmsv   1/1     Running   0          21s
# nginx                       1/1     Running   0          112s

# access to one of the pods of hellok8s-74bd687bcf-*
kubectl exec -it hellok8s-74bd687bcf-ll9q4 -- sh

# Inside the pod, curl to the clusterip-svc Cluster IP: 10.100.181.251, you should see nginx welcome page.
> curl http://10.100.181.251:80
> exit

# clean up
kubectl delete svc clusterip-svc
kubectl delete deployment hellok8s
kubectl delete pod nginx
```

Demo: Access from a pod to a service with its service name (internal DNS) instead of its Cluster IP (that can be changed after recreating the service)
```sh
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f nginx.yaml

kubectl get svc
# NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
# clusterip-svc   ClusterIP   10.105.163.189   <none>        80/TCP           26s
# hellok8s-svc    NodePort    10.107.73.117    <none>        4567:30001/TCP   31s
# kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP          8d

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-74bd687bcf-b8pxv   1/1     Running   0          45s
# hellok8s-74bd687bcf-rgx4x   1/1     Running   0          45s
# nginx                       1/1     Running   0          37s

# access to nginx pod to curl to the hellok8s-svc service with both Cluster IP and its service name (internal DNS)
# We should see the same result but can be different pod name to execute it.
kubectl exec -it nginx -- sh

# Try to request the service with its Cluster IP
# NOTE: we access by port (4567) not nodePort (30001)
> curl http://10.107.73.117:4567
[v3] Hello, Kubernetes, from hellok8s-74bd687bcf-b8pxv!

# Try to request the service with its service name
# NOTE: we access by port (4567) not nodePort (30001)
> curl http://hellok8s-svc:4567
[v3] Hello, Kubernetes, from hellok8s-74bd687bcf-rgx4x!

# clean up (with one-liner command)
kubectl delete deployment,service --all
```


### LAB004: Ingress

Start nginx ingress controller
```sh
cd lab004

# NOTE: Make sure that you already delete nginx pod from the previous labs, if not, just.
kubectl delete pod nginx

# You can run the nginx ingress controller by applying this manifest file:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml

# And you can confirm the controller is running with:
kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx
# or just
kubectl get pods --namespace=ingress-nginx

# NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
# ingress-nginx   ingress-nginx-admission-create--1-k9xqt     0/1     Completed   0          105s
# ingress-nginx   ingress-nginx-admission-patch--1-kg5sq      0/1     Completed   1          104s
# ingress-nginx   ingress-nginx-controller-55dcf56b68-4g5dq   1/1     Running     0          105s

# If you see a pod running and ready, you’re good to go.
```
- References
  - https://kubernetes.github.io/ingress-nginx/deploy/#docker-desktop


Deploy two applications behind their own service
```sh
# Deploy
kubectl apply -f hellok8s-app.yaml
kubectl apply -f nginx-app.yaml

# Verify
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-74bd687bcf-dq4hq   1/1     Running   0          32s
# hellok8s-74bd687bcf-pfsmd   1/1     Running   0          32s
# nginx-d47fd7f66-g72jc       1/1     Running   0          25s
# nginx-d47fd7f66-rhc9k       1/1     Running   0          25s

kubectl get svc
# NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
# hellok8s-svc   ClusterIP   10.103.250.104   <none>        4567/TCP   52s
# kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP    2d1h
# nginx-svc      ClusterIP   10.99.175.15     <none>        1234/TCP   47s

# NOTE: So all the pods are running fine, and we have two ClusterIP services, one listening on port 4567 and the other on port 1234.
```

Right now these services are only reachable from inside the cluster, so let’s see how we can expose them with an `Ingress`.
```sh
# IMPORTANT: we add `kubernetes.io/ingress.class: "nginx"` in addition to what provides by educative.io; otherwist, it will always 404 not found from ingress-nginx

kubectl apply -f ingress.yaml
# ingress.extensions/hello-ingress created

# Please enter the following command if you get an error while applying the ingress 
# and then reapply the ingress using the above command
# If not, you can skip this command and move ahead
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

# Verify
kubectl get ingress
# NAME            CLASS    HOSTS   ADDRESS     PORTS   AGE
# hello-ingress   <none>   *       localhost   80      28m

# NOTE: If `kubernetes.io/ingress.class: "nginx"` does not exist, ADDRESS will be empty.

# Test with http://localhost:80 it should go to nginx-svc service.

# Update the ingress
kubectl apply -f ingress-updated.yaml

# Verify
kubectl get ingress
# NAME            CLASS    HOSTS   ADDRESS     PORTS   AGE
# hello-ingress   <none>   *       localhost   80      28m

# Test with http://localhost:80/hello it should go to hellok8s-svc service.

# If you would like to view logs on nginx-ingress:
## get its pod ID
kubectl get pods --namespace=ingress-nginx
# NAME                                        READY   STATUS      RESTARTS   AGE
# ingress-nginx-admission-create--1-v8xrx     0/1     Completed   0          34m
# ingress-nginx-admission-patch--1-sns8t      0/1     Completed   1          34m
# ingress-nginx-controller-55dcf56b68-xdcqp   1/1     Running     0          34m

## view its log by:
kubectl logs ingress-nginx-controller-55dcf56b68-xdcqp --namespace=ingress-nginx
```
- References
  - https://stackoverflow.com/questions/69468100/nginx-ingress-404-not-found-using-docker-desktop-on-windows-not-minikube


Serving services in different hosts
```sh
# apply change
kubectl apply -f ingress-updated-2.yaml

# verify
kubectl get ingress
# NAME            CLASS    HOSTS                             ADDRESS     PORTS   AGE
# hello-ingress   <none>   nginx.local.com,hello.local.com   localhost   80      41m

# NOTE: we can’t access these services using localhost anymore because
#       When our Ingress receives a request, it will check the Host HTTP header to determine which rule will match. We currently have two rules defined, one for nginx.local.com and another for hello.local.com. But when we try to access http://localhost, what is sent in this header is the string "localhost":


# Test method 1: Using the --header flag with curl
curl --header 'Host: hello.local.com' localhost
curl --header 'Host: nginx.local.com' localhost


# Test method 2: changing the /etc/hosts file or C:\windows\system32\drivers\etc\hosts on Windows:
sudo echo "127.0.0.1 hello.local.com" >> /etc/hosts
sudo echo "127.0.0.1 nginx.local.com" >> /etc/hosts

curl http://hello.local.com
curl http://nginx.local.com
# ** And it should work the same way in our browser.

# clean up by
kubectl delete deployment,service,ingress --all
```

### LAB005: Configmaps

```sh
cd lab005

cd lab002

# Log in to DockerHub
docker login --username <your-docker-hub-id>

# Build the image
docker image build -t <your-docker-hub-id>/hellok8s:v4 .

# Push the image into the DockerHub
docker image push <your-docker-hub-id>/hellok8s:v4

# create service and deployment
kubectl apply -f hello8ks.yaml

# verify
kubectl get pods
# NAME                       READY   STATUS    RESTARTS   AGE
# hellok8s-c65959566-4s526   1/1     Running   0          39s
# hellok8s-c65959566-t625z   1/1     Running   0          39s

kubectl get svc 
# NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
# hellok8s-svc   NodePort    10.109.233.140   <none>        4567:30001/TCP   44s
# kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP          70m

kubectl get deployment
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# hellok8s   2/2     2            2           47s

# Test by http://localhost:30001 you should see like:
# [v4] Hello, Kubernetes (from hellok8s-6d4897cd67-wvzv5)

# add a environment variable
kubectl apply -f hello8ks-2.yaml

# Test by http://localhost:30001 you should see like:
# [v4] It works! (from hellok8s-6d4897cd67-wvzv5)
```

Extracting Configs to a ConfigMap
```sh
# apply change
kubectl apply -f hellok8s-config.yaml
kubectl apply -f hello8ks-3.yaml

# Test by http://localhost:30001 you should see like:
# [v4] It works with a ConfigMap! (from hellok8s-59bf555456-gxwzp)

# apply change
kubectl apply -f hello8ks-4.yaml

# Test by http://localhost:30001 you should see like:
# [v4] It works with a ConfigMap! (from hellok8s-59bf555456-gxwzp)
```

Exposing ConfigMap as files
```sh
# Instead of injecting a ConfigMap as environment variables as we have done so far, we can also expose it as files that are mounted into the container.
# that can be useful when we are storing things like config files in a ConfigMap instead of only simple strings.

# apply change
kubectl apply -f hello8ks-5.yaml

# verify
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-7bccff9c64-vgzqr   1/1     Running   0          8s
# hellok8s-7bccff9c64-wcrtf   1/1     Running   0          14s

kubectl get configmap

# check file inside the pod
kubectl exec -it hellok8s-7bccff9c64-vgzqr -- sh
# / # ls /config
# MESSAGE
# / # cat /config/MESSAGE 
# It works with a ConfigMap!

# clean up
kubectl delete deployment,service,configmap --all
```


### LAB006: Secret

```sh
cd lab006

# NOTE: In hellok8s-secret, We can create this string using something like:
echo 'It works with a Secret' | base64
# SXQgd29ya3Mgd2l0aCBhIFNlY3JldAo=
# Input it in hellok8s-secret.yaml

# NOTE: When we read a Secret, we will get the data base64 encoded. This is mostly so we can store binary values in a secret, not much of a security feature as base64 is easily decoded.

# apply
kubectl apply -f hellok8s-secret.yaml
kubectl apply -f deployment.yaml

# verify
kubectl get secret hellok8s-secret
#NAME              TYPE     DATA   AGE
#hellok8s-secret   Opaque   1      3m8s

kubectl get secret hellok8s-secret -o yaml
#apiVersion: v1
#data:
#  SECRET_MESSAGE: SXQgd29ya3Mgd2l0aCBhIFNlY3JldAo=
#kind: Secret
#metadata:
#  annotations:
#    kubectl.kubernetes.io/last-applied-configuration: |
#      {"apiVersion":"v1","data":{"SECRET_MESSAGE":"SXQgd29ya3Mgd2l0aCBhIFNlY3JldAo="},"kind":"Secret","metadata":{"annotations":{},"name":"hellok8s-secret","namespace":"default"}}
#  creationTimestamp: "2022-08-12T23:12:44Z"
#  name: hellok8s-secret
#  namespace: default
#  resourceVersion: "168801"
#  uid: 65d7e080-bb25-413e-b9d1-4074dd2b962e
#type: Opaque

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-796f7c7645-7wdts   1/1     Running   0          4m18s
# hellok8s-796f7c7645-nwwxl   1/1     Running   0          4m18s

# Replace the pod name to what you have running locally
kubectl exec -it hellok8s-796f7c7645-7wdts --  env | grep MESSAGE
# MESSAGE=It works with a Secret

# clean up
kubectl delete deployment,secret --all
```

It can be annoying to have to base64-encode every string before creating a Secret. And if all we need is a string like we’ve used here and not a binary value, we can use the `stringData` field to create secrets in raw format:
```sh
# apply
kubectl apply -f hellok8s-secret-stringData.yaml
kubectl apply -f deployment.yaml

# verify
kubectl get secret hellok8s-secret
#NAME              TYPE     DATA   AGE
#hellok8s-secret   Opaque   1      3m8s

kubectl get secret hellok8s-secret -o yaml
#apiVersion: v1
#data:
#  SECRET_MESSAGE: SXQgd29ya3Mgd2l0aCBhIFNlY3JldA==
#kind: Secret
#metadata:
#  annotations:
#    kubectl.kubernetes.io/last-applied-configuration: |
#      {"apiVersion":"v1","kind":"Secret","metadata":{"annotations":{},"name":"hellok8s-secret","namespace":"default"},"stringData":{"SECRET_MESSAGE":"It works with a Secret"}}
#  creationTimestamp: "2022-08-12T23:24:11Z"
#  name: hellok8s-secret
#  namespace: default
#  resourceVersion: "169848"
#  uid: fb4fe917-39fa-4848-a984-f8e25940354f
#type: Opaque

# NOTE: You can see that it is still encoded with base64 after applying it.

kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-796f7c7645-594tq   1/1     Running   0          113s
# hellok8s-796f7c7645-qs5zb   1/1     Running   0          113s

# Replace the pod name to what you have running locally
kubectl exec -it hellok8s-796f7c7645-594tq --  env | grep MESSAGE
# MESSAGE=It works with a Secret

# clean up
kubectl delete deployment,secret --all
```

Mounting Secrets as Files
```sh
# apply change to deployment
kubectl apply -f deployment-2.yaml

# verify
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-5564f7b4b9-8gqjc   1/1     Running   0          42s
# hellok8s-5564f7b4b9-fnd6l   1/1     Running   0          39s

kubectl exec -it hellok8s-5564f7b4b9-8gqjc -- \
cat /secrets/SECRET_MESSAGE
# It works with a Secret
```

### LAB007: Job

Run echo job
```sh
kubectl apply -f echo-job.yaml

kubectl get pods
# NAME                        READY   STATUS      RESTARTS   AGE
# echo-job--1-mfj27           0/1     Completed   0          26s

kubectl logs echo-job--1-mfj27
# Running in a job

kubectl get jobs
# NAME       COMPLETIONS   DURATION   AGE
# echo-job   1/1           19s        66s
```

Running multiple pods
```sh
# Jobs are immutable, so delete it first if you already have one running.
kubectl delete job echo-job
# NOTE: This will also delete all pods generated during the same job name.

kubectl apply -f echo-job-2.yaml

# After a few seconds...
kubectl get pods
# NAME                        READY   STATUS      RESTARTS   AGE
# echo-job--1-2fm8c           0/1     Completed   0          42s
# echo-job--1-g9gdv           0/1     Completed   0          20s
# echo-job--1-htt7b           0/1     Completed   0          42s
# echo-job--1-nwz4s           0/1     Completed   0          27s
# echo-job--1-wjs4n           0/1     Completed   0          42s

# Or see its progress
kubectl get pods --watch

kubectl get jobs
# NAME       COMPLETIONS   DURATION   AGE
# echo-job   5/5           41s        2m13s
```

When Jobs Fail
```sh
kubectl delete job echo-job

kubectl apply -f echo-job-fail.yaml

kubectl get pods

kubectl get pods --watch
```

Cron job
```sh
kubectl apply -f echo-cronjob.yaml

kubectl get jobs

kubectl get cronjobs

kubectl get pods

# NOTE: Every one minutes the job will be started with a new pod.
kubectl get pods --watch
# NAME                             READY   STATUS      RESTARTS   AGE
# echo-cronjob-27672645--1-cjb9t   0/1     Completed   0          2m29s
# echo-cronjob-27672646--1-j8fww   0/1     Completed   0          89s
# echo-cronjob-27672647--1-ct5nw   0/1     Completed   0          29s

kubectl logs echo-cronjob-27672647--1-ct5nw
# Triggered by a CronJob

kubectl delete cronjob echo-cronjob

# if not yet delete from previous labs
kubectl delete job,configmap,secret,svc,deployment --all
```



### LAB008: Namespace

```sh
cd lab008

kubectl apply -f namespace.yaml

# verify
kubectl get namespaces
# NAME              STATUS   AGE
# default           Active   13d
# ingress-nginx     Active   2d21h
# kube-node-lease   Active   13d
# kube-public       Active   13d
# kube-system       Active   13d
# my-namespace      Active   2s

# We can, however, see resources from a specific namespace using the -n flag with kubectl:
kubectl get pods -n ingress-nginx
# NAME                                        READY   STATUS      RESTARTS   AGE
# ingress-nginx-admission-create--1-v8xrx     0/1     Completed   0          2d21h
# ingress-nginx-admission-patch--1-sns8t      0/1     Completed   1          2d21h
# ingress-nginx-controller-55dcf56b68-xdcqp   1/1     Running     0          2d21h

# We can also use the --all-namespaces flag to see resources from all namespaces, 
kubectl get pods --all-namespaces

# and we can combine that with kubectl get all to see everything we have running in our cluster:
kubectl get all --all-namespaces

# create and apply the pod to default namespace
kubectl apply -f nginx-pod.yaml

# verify
kubectl get pods -n default
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          28s

kubectl get pods -n my-namespace
# No resources found in my-namespace namespace.

# create and apply the pod to my-namespace namespace
kubectl apply -f nginx-pod.yaml -n my-namespace

# verify: we should have one pod running in each namespace now:
kubectl get pods -n default
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          28s

kubectl get pods -n my-namespace
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          28s

# create the pod to my-namespace namespace without the need to apply it.
kubectl apply -f nginx-pod-2.yaml

# verify
kubectl get pods -n default
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          3m11s

kubectl get pods -n my-namespace
# NAME     READY   STATUS    RESTARTS   AGE
# nginx    1/1     Running   0          108s
# nginx2   1/1     Running   0          15s

# clean up
kubectl delete pod nginx
kubectl delete pod nginx -n my-namespace
kubectl delete pod nginx2 -n my-namespace

```

Accessing service’s DNS using namespace
```sh
# create each pod in different namespaces
kubectl apply -f nginx-pods.yaml

# verify
kubectl get pod --all-namespaces
# NAMESPACE       NAME                                        READY   STATUS      RESTARTS        AGE
# default         hellok8s                                    1/1     Running     0               20s
# ...
# my-namespace    hellok8s                                    1/1     Running     0               19s

# create each service for each pod in different namespaces
kubectl apply -f service.yaml -n default
kubectl apply -f service.yaml -n my-namespace

# verify
kubectl get svc --all-namespaces
# NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
# default         hellok8s-svc                         ClusterIP      10.99.241.145    <none>        4567/TCP                     3m31s
# ...
# my-namespace    hellok8s-svc                         ClusterIP      10.107.225.193   <none>        4567/TCP                     3m28s

# NOTE: Now that we have one pod and one service running in each namespace,



# open an interactive session in our container running in the default namespace:
kubectl exec -it hellok8s -- sh

# Now inside the container

curl http://hellok8s-svc:4567
# [v4] Hello, Kubernetes (from hellok8s)

curl http://hellok8s-svc.default:4567
# [v4] Hello, Kubernetes (from hellok8s)

curl http://hellok8s-svc.my-namespace:4567
# [v3] Hello, Kubernetes, from hellok8s!





# open an interactive session in our container running in the my-namespace namespace:
kubectl exec -it hellok8s -n my-namespace -- sh

# Now inside the container

curl http://hellok8s-svc:4567
# [v3] Hello, Kubernetes, from hellok8s!
# NOTE: This is because the current namespace is my-namespace

curl http://hellok8s-svc.default:4567
# [v4] Hello, Kubernetes (from hellok8s)

curl http://hellok8s-svc.my-namespace:4567
# [v3] Hello, Kubernetes, from hellok8s!

# clean up
kubectl delete svc hellok8s-svc
kubectl delete pod hellok8s

kubectl delete svc hellok8s-svc -n my-namespace
kubectl delete pod hellok8s -n my-namespace
```


### LAB009 :: Resource usage

```sh
cd lab009

# get our constraints on node resources (CPU, Memory, etc)
kubectl describe nodes
# ...
# Allocatable:
#   cpu:                2
#   ephemeral-storage:  56453061334
#   hugepages-1Gi:      0
#   hugepages-2Mi:      0
#   memory:             3926792Ki
#   pods:               110
# ...
#Non-terminated Pods:          (12 in total)
#  Namespace                   Name                                         CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
#  ---------                   ----                                         ------------  ----------  ---------------  -------------  ---
#  default                     hellok8s                                     0 (0%)        0 (0%)      0 (0%)           0 (0%)         40m
#  ingress-nginx               ingress-nginx-controller-55dcf56b68-xdcqp    100m (5%)     0 (0%)      90Mi (2%)        0 (0%)         3d23h
#  kube-system                 coredns-78fcd69978-l7qc9                     100m (5%)     0 (0%)      70Mi (1%)        170Mi (4%)     14d
#  kube-system                 coredns-78fcd69978-vfrnn                     100m (5%)     0 (0%)      70Mi (1%)        170Mi (4%)     14d
#  kube-system                 etcd-docker-desktop                          100m (5%)     0 (0%)      100Mi (2%)       0 (0%)         14d
#  kube-system                 kube-apiserver-docker-desktop                250m (12%)    0 (0%)      0 (0%)           0 (0%)         14d
#  kube-system                 kube-controller-manager-docker-desktop       200m (10%)    0 (0%)      0 (0%)           0 (0%)         14d
#  kube-system                 kube-proxy-ft6sr                             0 (0%)        0 (0%)      0 (0%)           0 (0%)         14d
#  kube-system                 kube-scheduler-docker-desktop                100m (5%)     0 (0%)      0 (0%)           0 (0%)         14d
#  kube-system                 storage-provisioner                          0 (0%)        0 (0%)      0 (0%)           0 (0%)         14d
#  kube-system                 vpnkit-controller                            0 (0%)        0 (0%)      0 (0%)           0 (0%)         14d
#  my-namespace                hellok8s                                     0 (0%)        0 (0%)      0 (0%)           0 (0%)         40m
# ...

# Summary: 
# - So, this node right now we only have around 2 - (0.1*5 + 0.2 + 0.25) = 1.05 CPUs available (1050m) for our pods to run.
# - For memory, we only have 4 - (0.1 + 2*0.7 + 0.9) = 1.6 GB for our pods to run.

kubectl apply -f busybox.yaml

kubectl exec -it busybox -- top
# Mem: 3847544K used, 181648K free, 333056K shrd, 305888K buff, 2437412K cached
# CPU: 36.0% usr 40.8% sys  0.0% nic 22.3% idle  0.1% io  0.0% irq  0.7% sirq
# Load average: 2.24 1.51 1.67 3/992 14
#   PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
#     1     0 root     R     1324  0.0   1 52.8 dd if /dev/zero of /dev/null
#     8     0 root     R     1332  0.0   0  0.1 top

# NOTE: CPU = 52.8% because we have 2 CPU and the contain use all resource in 1 CPU (1000m) because it is run in a thread and never to use more than that.

# Let’s now try to create another container requesting 700m, which is more than we have available (500m + 700m is more than the 1050m we have),

kubectl apply -f hungry-busybox.yaml

# verify
kubectl get pods
# NAME             READY   STATUS    RESTARTS   AGE
# busybox          1/1     Running   0          4m40s
# hellok8s         1/1     Running   0          57m
# hungry-busybox   0/1     Pending   0          18s

# NOTE: ven though kubectl can successfully apply this manifest, it still stays Pending because no requested resource available.

kubectl describe pod hungry-busybox
# ...
# Events:
#   Type     Reason            Age   From               Message
#   ----     ------            ----  ----               -------
#   Warning  FailedScheduling  90s   default-scheduler  0/1 nodes are available: 1 Insufficient cpu.
#   Warning  FailedScheduling  28s   default-scheduler  0/1 nodes are available: 1 Insufficient cpu.

# try to remove the first pod
kubectl delete pod busybox

# verify
kubectl get pods
# NAME             READY   STATUS    RESTARTS   AGE
# hellok8s         1/1     Running   0          60m
# hungry-busybox   1/1     Running   0          3m33s

# NOTE: hungry-busybox can run now

kubectl exec -it hungry-busybox -- top
# Mem: 3833004K used, 196188K free, 333056K shrd, 306160K buff, 2438104K cached
# CPU: 38.9% usr 39.8% sys  0.0% nic 20.6% idle  0.0% io  0.0% irq  0.6% sirq
# Load average: 3.83 3.09 2.37 4/994 14
#   PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
#     1     0 root     R     1324  0.0   0 50.2 dd if /dev/zero of /dev/null
#     7     0 root     R     1332  0.0   0  0.0 top

# NOTE: CPU is around 50% again because it is still use one entire CPU due to it is running in one thread fully.

# clean up
kubectl delete pod hungry-busybox

# To limit its usage, use `limit` property specified in the manifest file.

kubectl apply -f limited-busybox.yaml

kubectl exec -it limited-busybox -- top

# NOTE: This container is now limited to 500m. 
# That, in our case, will be around 25% of the CPU available (25% of 2 CPUs).

# Mem: 3836840K used, 192352K free, 333056K shrd, 306332K buff, 2439016K cached
# CPU: 23.7% usr 30.2% sys  0.0% nic 45.4% idle  0.0% io  0.0% irq  0.5% sirq
# Load average: 3.82 4.10 3.14 8/993 14
#   PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
#     1     0 root     R     1324  0.0   0 28.9 dd if /dev/zero of /dev/null
#     7     0 root     R     1332  0.0   0  0.0 top

# clean up
kubectl delete pod limited-busybox
```

Defining Default Limits and Requests with Limitrange
- If we apply this LimitRange to a namespace, every container that it runs that doesn’t define a request and limit will use these default values
```sh
kubectl apply -f default-limit-range.yaml
# limitrange/memory-limit-range created

# verify
kubectl get limitrange
# NAME                 CREATED AT
# memory-limit-range   2022-08-20T02:37:26Z

kubectl apply -f hellok8s.yaml
# pod/hellok8s created

kubectl describe pod hellok8s
# ...
# Limits:
#   cpu:     200m
#   memory:  500Mi
# Requests:
#   cpu:        100m
#   memory:     100Mi
# ...

# clean up
kubectl delete pod hellok8s
kubectl delete limitrange memory-limit-range
```

### LAB010 :: Understanding Kubeconfig file

```sh
# When we run kubectl, it will always look at what is the current-context defined in the kubeconfig file. We can double check the context that is being used:
kubectl config current-context

# If we have more than one context, we can either change the current-context so all the subsequent commands are run using that context:
kubectl config use-context production

# Or define the context we want to use for individual kubectl commands:
kubectl get pods --context production

# By default, kubectl will look for a config file at ~/.kube/config, but we can override that using the --kubeconfig flag:
kubectl --kubeconfig="path/to/config" get pods
```

### Others

```sh
kubectl cluster-info
# Kubernetes control plane is running at https://kubernetes.docker.internal:6443
# CoreDNS is running at https://kubernetes.docker.internal:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

docker info

# To run the Kubernetes Dashboard, we will use the manifest file provided in the dashboard github repository:
# https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
# It’s a single manifest file that will create a deployment, service, and the necessary permissions for the dashboard to run. 
# All these resources will be created in the kubernetes-dashboard namespace.
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

# After all the resources are created, we should be ready to start using the dashboard. We will create a proxy to be able to connect to the Kubernetes API Server from our local machine:
kubectl proxy
# Starting to serve on 127.0.0.1:8001
# Now you can access dashboard at:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.

# We have two ways to authenticate: Using a kubeconfig file or with an authentication token. Let’s use a token for now.
kubectl describe secret default-token
# ...
# token: 

# We can then select Token in the sign in page as the authentication method and use the token that is printed by this command to sign in.

# This would also work the same way if our cluster were running in a cloud provider; we just run kubectl proxy, and we’ll be able to access it from our local machine without needing to have it exposed to the outside world. How convenient!

```
References
- https://github.com/kubernetes/dashboard

### LAB010 :: Try to create a cluster on DigitalOcean

Kubernetes > Create a Kubernetes cluster
- Region = SGP1
- Node pool name = kubernetesinpractice-node-pool
- Machine type = Basic
- Note plan = $12/monthper node
- Nodes = 2
- Cluster name = kubernetesinpractice

On kubernetesinpractice cluster > Actions > Download Config > Save it into `lab010/kubernetesinpractice-kubeconfig.yaml`
- Apply the current context to this cluster by:
```sh
cd lab010
export KUBECONFIG=/path/to/lab010/kubernetesinpractice-kubeconfig.yaml

# verify

## Check the current context
kubectl config get-contexts
# CURRENT   NAME                           CLUSTER                        AUTHINFO                             NAMESPACE
# *         do-sgp1-kubernetesinpractice   do-sgp1-kubernetesinpractice   do-sgp1-kubernetesinpractice-admin

## Check the nodes
kubectl get nodes
# NAME                                   STATUS   ROLES    AGE   VERSION
# kubernetesinpractice-node-pool-77her   Ready    <none>   14m   v1.23.9
# kubernetesinpractice-node-pool-77hrb   Ready    <none>   35m   v1.23.9
```

deploying-an-application
```sh
cd deploying-an-application

kubectl apply -f hellok8s.yaml

# verify to see pods runing in multiple nodes
kubectl get pods -o wide
# NAME                        READY   STATUS    RESTARTS   AGE    IP             NODE                                   NOMINATED NODE   READINESS GATES
# hellok8s-58c9487748-4bz4n   1/1     Running   0          102s   10.244.0.23    kubernetesinpractice-node-pool-77hrb   <none>           <none>
# hellok8s-58c9487748-6scld   1/1     Running   0          102s   10.244.0.187   kubernetesinpractice-node-pool-77her   <none>           <none>
# hellok8s-58c9487748-99zrp   1/1     Running   0          102s   10.244.0.68    kubernetesinpractice-node-pool-77hrb   <none>           <none>
# hellok8s-58c9487748-cd9kp   1/1     Running   0          102s   10.244.0.198   kubernetesinpractice-node-pool-77her   <none>           <none>
# hellok8s-58c9487748-g5d7b   1/1     Running   0          102s   10.244.0.131   kubernetesinpractice-node-pool-77her   <none>           <none>
# hellok8s-58c9487748-j9llk   1/1     Running   0          102s   10.244.0.59    kubernetesinpractice-node-pool-77hrb   <none>           <none>
# hellok8s-58c9487748-nj6jw   1/1     Running   0          102s   10.244.0.251   kubernetesinpractice-node-pool-77her   <none>           <none>
# hellok8s-58c9487748-s6s4p   1/1     Running   0          102s   10.244.0.189   kubernetesinpractice-node-pool-77her   <none>           <none>
# hellok8s-58c9487748-tbk42   1/1     Running   0          102s   10.244.0.120   kubernetesinpractice-node-pool-77hrb   <none>           <none>
# hellok8s-58c9487748-vrt2s   1/1     Running   0          102s   10.244.0.77    kubernetesinpractice-node-pool-77hrb   <none>           <none>

# With the below command, you can access to one of the pod with: http://localhost:30000
kubectl port-forward hellok8s-58c9487748-4bz4n 30000:4567
```

exposing-our-application
```sh
cd exposing-our-application

kubectl apply -f service.yaml

# verify
## Service is created
kubectl get svc
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# hellok8s-svc   NodePort    10.245.237.24   <none>        4567:30001/TCP   47s

# NOTE: The EXTERNAL-IP is empty because to access a NodePort service, we will instead use the worker nodes’ IPs. Let’s try that.

# output formatted for readability
kubectl get nodes -o wide
# NAME                                   STATUS   ROLES    AGE    VERSION   INTERNAL-IP    EXTERNAL-IP      OS-IMAGE                       KERNEL-VERSION          CONTAINER-RUNTIME
# kubernetesinpractice-node-pool-77her   Ready    <none>   120m   v1.23.9   10.130.107.7   128.199.102.76   Debian GNU/Linux 10 (buster)   5.10.0-0.bpo.15-amd64   containerd://1.4.13
# kubernetesinpractice-node-pool-77hrb   Ready    <none>   141m   v1.23.9   10.130.107.2   159.223.61.94    Debian GNU/Linux 10 (buster)   5.10.0-0.bpo.15-amd64   containerd://1.4.13

# And now, we should be able to use any node’s External IP address on port 30001 to access our app:
# http://128.199.102.76:30001
# http://159.223.61.94:30001

```

using-a-load-balancer
```sh
cd using-a-load-balancer

kubectl apply -f service.yaml

# Wait for a while and keep running the command below until we get the External IP from the first DO load balancer
kubectl get svc
# NAME           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
# hellok8s-svc   LoadBalancer   10.245.237.24   139.59.220.112   80:30001/TCP   15m

# Test below
# http://139.59.220.112
```

deploying-nginx
```sh
cd deploying-nginx

kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# verify
kubectl get deployment
# NAME                        READY   STATUS    RESTARTS   AGE    IP             NODE                                   NOMINATED NODE   READINESS GATES
# ...
# nginx-67d996548-4c458       1/1     Running   0          115s   10.244.0.88    kubernetesinpractice-node-pool-77hrb   <none>           <none>
# nginx-67d996548-bkcjw       1/1     Running   0          115s   10.244.0.66    kubernetesinpractice-node-pool-77hrb   <none>           <none>
# nginx-67d996548-cpz98       1/1     Running   0          115s   10.244.0.114   kubernetesinpractice-node-pool-77hrb   <none>           <none>
# nginx-67d996548-fd44v       1/1     Running   0          115s   10.244.0.222   kubernetesinpractice-node-pool-77her   <none>           <none>
# nginx-67d996548-km6j8       1/1     Running   0          115s   10.244.0.175   kubernetesinpractice-node-pool-77her   <none>           <none>
# nginx-67d996548-kpdls       1/1     Running   0          115s   10.244.0.191   kubernetesinpractice-node-pool-77her   <none>           <none>
# nginx-67d996548-l2hfp       1/1     Running   0          115s   10.244.0.188   kubernetesinpractice-node-pool-77her   <none>           <none>
# nginx-67d996548-stg6n       1/1     Running   0          115s   10.244.0.29    kubernetesinpractice-node-pool-77hrb   <none>           <none>
# nginx-67d996548-vh58j       1/1     Running   0          115s   10.244.0.204   kubernetesinpractice-node-pool-77her   <none>           <none>
# nginx-67d996548-xlr9r       1/1     Running   0          115s   10.244.0.54    kubernetesinpractice-node-pool-77hrb   <none>           <none>

# Wait until the following shows its external IP
kubectl get svc
# NAME           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
# ...
# nginx-svc      LoadBalancer   10.245.57.109   146.190.194.19   80:32233/TCP   3m3s

# After that, we should see a second load balancer being created on DigitalOcean.
# We should be able to access it using this second load balancer external IP address.
# http://146.190.194.19
```

Problem from previous one
- So this is working fine, but right now we need to have one load balancer for each service we deploy. We are charged per load balancer, so that can start to get expensive depending on how many services we need to run.
Solution
- As we have seen, an Ingress can help us solve this problem. Let’s try to replicate what we have now, using a single load balancer with an Ingress.

using-an-ingress
```sh
cd using-an-ingress

# clean up
kubectl delete svc hellok8s-svc nginx-svc

# Please verify that two DO load balancers are deleted

# Now, to use a Kubernetes Ingress, we will need to run an Ingress Controller in our cluster, just as we did locally. We will use the same nginx controller we used when we talked about ingresses:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml

# continue cleaning up
kubectl delete deployment --all

# verify that Ingress Controller is running on the cluster
kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx
# NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
# ingress-nginx   ingress-nginx-admission-create-cznjt        0/1     Completed   0          30s
# ingress-nginx   ingress-nginx-admission-patch-9q6fc         0/1     Completed   0          29s
# ingress-nginx   ingress-nginx-controller-54d587fbc6-rlb6m   1/1     Running     0          30s

# After creating the ingress controller, DO will create a load balancer.

# Deploy services (ClusterIP)
kubectl apply -f hellok8s.yaml
kubectl apply -f nginx.yaml

# Verify
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# hellok8s-77686cc8fc-5qcf8   1/1     Running   0          17s
# hellok8s-77686cc8fc-xh9l7   1/1     Running   0          26s
# nginx-67d996548-hkbg7       1/1     Running   0          63s
# nginx-67d996548-jh7g9       1/1     Running   0          63s

kubectl get svc
# NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
# hellok8s-svc   ClusterIP   10.245.111.142   <none>        4567/TCP   88s
# kubernetes     ClusterIP   10.245.0.1       <none>        443/TCP    3h4m
# nginx-svc      ClusterIP   10.245.102.237   <none>        80/TCP     85s

# Deploy ingress
# IMPORTANT: we add `kubernetes.io/ingress.class: "nginx"` in addition to what provides by educative.io; otherwist, it will always 404 not found from ingress-nginx
kubectl apply -f ingress.yaml

# Verify (Keep doing it until ADDRESS appear)
kubectl get ingress --watch
# NAME            CLASS    HOSTS                       ADDRESS   PORTS   AGE
# hello-ingress   <none>   nginx.do.com,hello.do.com             80      43m
# hello-ingress   <none>   nginx.do.com,hello.do.com   139.59.220.112   80      44m

# So here we see this ingress is handling requests to "nginx.do.com" and "hello.do.com", 
# and its external IP is "139.59.220.112".

# NOTE: I do not know why DO load balancer show that one node is down but everything still work fine?

# To test this Ingress, let’s use the same trick we used before, changing the /etc/hosts file:
sudo echo "139.59.220.112 hello.do.com" >> /etc/hosts
sudo echo "139.59.220.112 nginx.do.com" >> /etc/hosts

# Here, we are just saying that when we try to access hello.do.com or nginx.do.com, our DNS should resolve the IP of our load balancer.
# http://hello.do.com
# http://nginx.do.com

# And we should also be able to run arbitrary commands in this container that’s running in our remote cluster, just like we did when they were running locally:

# enter the container
kubectl get pods -o wide
# NAME                        READY   STATUS    RESTARTS   AGE   IP             NODE                                   NOMINATED NODE   READINESS GATES
# hellok8s-77686cc8fc-5qcf8   1/1     Running   0          60m   10.244.0.213   kubernetesinpractice-node-pool-77her   <none>           <none>
# hellok8s-77686cc8fc-xh9l7   1/1     Running   0          61m   10.244.0.3     kubernetesinpractice-node-pool-77hrb   <none>           <none>
# nginx-67d996548-hkbg7       1/1     Running   0          61m   10.244.0.133   kubernetesinpractice-node-pool-77her   <none>           <none>
# nginx-67d996548-jh7g9       1/1     Running   0          61m   10.244.0.93    kubernetesinpractice-node-pool-77hrb   <none>           <none>

# Replace the pod name by what you have running locally 
kubectl exec -it hellok8s-77686cc8fc-5qcf8 -- sh

# test our ClusterIP services
curl http://hellok8s-svc:4567
# [v3] Hello, Kubernetes, from hellok8s-77686cc8fc-xh9l7!
curl http://hellok8s-svc:4567
# [v3] Hello, Kubernetes, from hellok8s-77686cc8fc-5qcf8!

curl http://nginx-svc
# nginx welcome page
```
