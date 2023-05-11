### Note :: Pods

```sh
# create a cluster with k3d
k3d cluster create mycluster
kubectl get nodes
# NAME                     STATUS   ROLES                  AGE     VERSION
# k3d-mycluster-server-0   Ready    control-plane,master   2m50s   v1.21.5+k3s1
```
- NOTE: In gitpod, we cannot install k3s, so we decide to create a new cluster on any public cloud instead.

```sh
# Create Pods with a single command like `docker run` 
kubectl run db --image mongo

# verify (may take some time before it is in running stage)
kubectl get pods
# NAME   READY   STATUS    RESTARTS   AGE
# db     1/1     Running   0          34s

# clean up
kubectl delete pod db
```

### LAB001 :: Pods

```sh
cd lab001

# create a pod declaratively
kubectl create -f db.yml

# verify
kubectl get pods
# NAME   READY   STATUS    RESTARTS   AGE
# db     1/1     Running   0          40s

# verify in various formats
kubectl get pods -o wide
kubectl get pods -o json
kubectl get pods -o yaml

# get more detail of the pod
kubectl describe pod db

# if you cannot remember the pod name
kubectl describe -f db.yml
```

```sh
# Just as with Docker container, we can execute a new process inside a running container inside a Pod.
kubectl exec db -- ps aux
# USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
# root           1  0.8  2.9 286092 59280 ?        Ssl  00:43   0:02 mongod --rest --httpinterface
# root          25  0.0  0.1  17504  2100 ?        Rs   00:47   0:00 ps aux

# NOTE: Since our Pod defines only one container, this container and the first container are one and the same. 
#       The --container (or -c) argument can be set to specify which container should be used. 
#       That is particularly useful when running multiple containers in a Pod.
# kubectl exec db -c <container-name> -- ps aux
kubectl exec db -c db -- ps aux

# we can make the execution interactive with -i (stdin) and -t (terminal) arguments and run shell inside a container.
kubectl exec -it db -- sh
# (inside the first container of db pod, please try this.)
# # echo 'db.stats()' | mongo localhost:27017/test

# to see logs of a container in a Pod.
kubectl logs db
kubectl logs db -f
# kubectl logs db -f -c <container-name>
kubectl logs db -f -c db

# Let’s simulate a failure and observe what happens.
kubectl exec db --  pkill mongod

kubectl get pods
# NAME   READY   STATUS      RESTARTS   AGE
# db     0/1     Completed   0          11m

# After a while

kubectl get pods
# NAME   READY   STATUS    RESTARTS      AGE
# db     1/1     Running   1 (16s ago)   11m

# NOTE:
# Kubernetes guarantees that the containers inside a Pod are (almost) always running. 
# Please note that the RESTARTS field now has the value of 1. 
# Every time a container fails, Kubernetes will restart it.

# delete a pod
kubectl delete -f db.yml

# verify
kubectl get pods
# No resources found in default namespace.
```

```sh
kubectl create -f go-demo-2-1.yml

# Verify
kubectl get -f go-demo-2-1.yml
kubectl get -f go-demo-2-1.yml -o json

# Filter result
kubectl get -f go-demo-2-1.yml -o jsonpath="{.spec.containers[*].name}"
# db api

# Operation into more specific container
kubectl exec -it -c db go-demo-2 -- ps aux
kubectl logs go-demo-2 -c db

# Scaling api container
kubectl delete -f go-demo-2-1.yml
kubectl create -f go-demo-2-2.yml

# Verify
kubectl get -f go-demo-2-2.yml
# NAME        READY   STATUS   RESTARTS     AGE
# go-demo-2   2/3     Error    1 (4s ago)   10s
```

```sh
kubectl create -f go-demo-2-health.yml

kubectl get pods --watch
# NAME        READY   STATUS    RESTARTS   AGE
# go-demo-2   2/2     Running   0          11s
# go-demo-2   2/2     Running   1 (3s ago)   13s
# go-demo-2   2/2     Running   2 (3s ago)   23s
# go-demo-2   2/2     Running   3 (3s ago)   33s
# go-demo-2   1/2     CrashLoopBackOff   3 (1s ago)   41s
# go-demo-2   2/2     Running            4 (30s ago)   70s
# go-demo-2   1/2     CrashLoopBackOff   4 (1s ago)    76s
# go-demo-2   2/2     Running            5 (43s ago)   118s
# go-demo-2   1/2     CrashLoopBackOff   5 (0s ago)    2m5s

# We created the Pod with the probe. Now we must wait until the probe fails a few times. A minute is more than enough. Once we’re done waiting, we can describe the Pod.

kubectl describe -f go-demo-2-health.yml
# ...
# Events:
#   Type     Reason     Age                   From               Message
#   ----     ------     ----                  ----               -------
#   Normal   Scheduled  2m30s                 default-scheduler  Successfully assigned default/go-demo-2 to k8s-test-01-node-pool-7mr19
#   Normal   Pulled     2m29s                 kubelet            Container image "mongo:3.3" already present on machine
#   Normal   Created    2m29s                 kubelet            Created container db
#   Normal   Started    2m29s                 kubelet            Started container db
#   Normal   Pulled     2m27s                 kubelet            Successfully pulled image "vfarcic/go-demo-2" in 2.212069683s
#   Normal   Pulled     2m18s                 kubelet            Successfully pulled image "vfarcic/go-demo-2" in 2.179551326s
#   Normal   Pulled     2m8s                  kubelet            Successfully pulled image "vfarcic/go-demo-2" in 2.202096286s
#   Normal   Killing    2m (x3 over 2m20s)    kubelet            Container api failed liveness probe, will be restarted
#   Warning  Unhealthy  2m (x3 over 2m20s)    kubelet            Liveness probe failed: HTTP probe failed with statuscode: 404
#   Normal   Pulling    2m (x4 over 2m29s)    kubelet            Pulling image "vfarcic/go-demo-2"
#   Normal   Started    118s (x4 over 2m27s)  kubelet            Started container api
#   Normal   Created    118s (x4 over 2m27s)  kubelet            Created container api
#   Normal   Pulled     118s                  kubelet            Successfully pulled image "vfarcic/go-demo-2" in 2.279239642s
```

### LAB002 :: ReplicaSets

```sh
kubectl create -f go-demo-2.yml

# wait for a while and then verify
kubectl get rs
# NAME        DESIRED   CURRENT   READY   AGE
# go-demo-2   2         2         2       8s

# see events from the ReplicaSet
kubectl describe -f go-demo-2.yml
# Events:
#   Type    Reason            Age   From                   Message
#   ----    ------            ----  ----                   -------
#   Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: go-demo-2-f6xrj
#   Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: go-demo-2-cd97w

# verify 
kubectl get pods --show-labels
# NAME              READY   STATUS    RESTARTS   AGE   LABELS
# go-demo-2-cd97w   2/2     Running   0          46s   db=mongo,language=go,service=go-demo-2,type=backend
# go-demo-2-f6xrj   2/2     Running   0          46s   db=mongo,language=go,service=go-demo-2,type=backend


```
