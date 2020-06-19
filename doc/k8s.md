# Instala kubernetes


# Instala minikube

```bash
sudo apt-get update && sudo apt-get install -y curl wget apt-transport-https
sudo curl -Lo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64  
sudo chmod 755 /usr/local/bin/minikube

minikube version
```

# Instala kubectl

```bash
kubectl_version=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

sudo curl -Lo /usr/local/bin/kubectl  https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl
sudo chmod 755 /usr/local/bin/kubectl

kubectl version -o json


```

# Iniciamos minikube

```bash
minikube start

minikube start --vm-driver=virtualbox --host-only-cidr=192.168.199.1/24


minikube start --kubernetes-version v1.17.0

https_proxy=$https_proxy minikube start --docker-env http_proxy=$http_proxy --docker-env https_proxy=$https_proxy --docker-env no_proxy=192.168.99.0/24


minikube status
```

Para ver las opciones configuradas:

```bash

# VM Driver
cat ~/.minikube/machines/minikube/config.json | jq ".DriverName"

# ISO version
cat ~/.minikube/machines/minikube/config.json | jq ".Driver.Boot2DockerURL"


# Config en Yaml de kubectl:
cat ~/.kube/config
kubectl config view

```

# Uso de kubectl

```bash

kubectl cluster-info

# Dump en json de la config completa:
kubectl cluster-info dump

# ver dashboard
minikube dashboard

kubectl get nodes

# lista los contenedores que estan corriendo:
kubectl get pods --all-namespaces

# cual es el URL del dashboard
minikube dashboard --url


# Para ingresar por SSH a la VM Virtualbox con minikube:
minikube ssh

# detener el cluster
minikube stop

# eliminar la VM
minikube delete


```
# Deploy de aplicaciones

```bash

# el deployment que vamos a usar:

# https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/service/access/hello-application.yaml

# Run a Hello World application in your cluster: Create the application Deployment using the file above:

kubectl apply -f https://k8s.io/examples/service/access/hello-application.yaml

# Display information about the Deployment:
kubectl get deployments hello-world

kubectl describe deployments hello-world
Name:                   hello-world
Namespace:              default
CreationTimestamp:      Mon, 24 Feb 2020 21:27:04 -0300
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
                        kubectl.kubernetes.io/last-applied-configuration:
                          {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"name":"hello-world","namespace":"default"},"spec":{"replicas":2,...
Selector:               run=load-balancer-example
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  run=load-balancer-example
  Containers:
   hello-world:
    Image:        gcr.io/google-samples/node-hello:1.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   hello-world-77b74d7cc8 (2/2 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  18m   deployment-controller  Scaled up replica set hello-world-77b74d7cc8 to 2


# Display information about your ReplicaSet objects:
kubectl get replicasets
kubectl describe replicasets

# Create a Service object that exposes the deployment:
kubectl expose deployment hello-world --type=NodePort --name=example-service

# Display information about the Service:
kubectl describe services example-service

Name:                     example-service
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 run=load-balancer-example
Type:                     NodePort
IP:                       10.107.112.172
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31453/TCP
Endpoints:                172.17.0.6:8080,172.17.0.7:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>


# List the pods that are running the Hello World application:

kubectl get pods --selector="run=load-balancer-example" --output=wide

NAME                           READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
hello-world-77b74d7cc8-k4q6p   1/1     Running   0          76m   172.17.0.7   minikube   <none>           <none>
hello-world-77b74d7cc8-zpdxq   1/1     Running   0          76m   172.17.0.6   minikube   <none>           <none>


# conseguimos el IP del host con:
kubectl cluster-info dump | jq 'select(.kind == "PodList").items[0].status.hostIP'  

# Port donde atiende el servicio:
kubectl cluster-info dump | grep  nodePort | tr -d " " | cut -d: -f 2

# FIXME: para hacerlo desde json:
#kubectl cluster-info dump | jq 'select(.kind == "ServiceList").items[].spec.ports[]| select(.nodePort).nodePort'


# O sea, la app es accesible en:
curl http://192.168.199.101:31453/ ; echo


```

# Eliminamos

# To delete the Service, enter this command:
kubectl delete services example-service

# To delete the Deployment, the ReplicaSet, and the Pods that are running the Hello World application, enter this command:
kubectl delete deployment hello-world

# Referencias

* https://kubernetes.io/docs/setup/learning-environment/minikube/
* https://kubernetes.io/es/docs/tasks/tools/install-kubectl/#instalar-el-binario-de-kubectl-usando-curl
* https://kubernetes.io/docs/tasks/access-application-cluster/service-access-application-cluster/

* https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/
