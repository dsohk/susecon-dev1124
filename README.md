# Rehosting spring-petclinic java application to SUSE Container and Application Platform

This repository hosts the scripts file used as demonstration in SUSECON Digital 2020 Session [DEV-1124]. 

In this demo, we will check out the source code of a spring-based java application [petclinic](https://github.com/spring-projects/spring-petclinic) and walk you through how to containerize and rehost it into SUSE CaaS Platform (kubernetes) and SUSE Cloud Application Platform (cloud foundry).


# What do I need to run this demo?

You will need the following to run this demo:

* A Linux distro (tested with SLES15SP1) with `git`, `docker`, `kubectl` and `cf-cli` installed.
* Free account for [Docker Hub](https://hub.docker.com/) (container registry used in this demo)
* Access to a SUSE CaaS Platform cluster
* Access to a SUSE Cloud Application Platform - sign up a free account [SUSE CAP Sandbox](https://www.explore.suse.dev/)

# Porting the java app to SUSE CaaS Platform

This section guides you the steps needed to containerize and deploy the petclinic java app to SUSE CaaS Platform.

## Step 1 - Build the SLES15SP1 based openjdk11 image

Run the script below to build a SLES15SP1 based openjdk docker image. It assumes you build this with a SLES15SP1 linux host.

``` bash
./build-openjdk11.sh
```

Tag the docker image and push to docker hub

``` bash
docker images
docker tag susesamples/sles15sp1-openjdk11:latest susesamples/sles15sp1-openjdk11:11.0.7
docker login
docker push susesamples/sles15sp1-openjdk11:11.0.7
```

## Step 2 - Containerize the petclinic java app 

Run the script below to download petclinic's source code and containerize it with a multi-stage docker build file.

``` bash
./build-spring-petclinic.sh
```

Tag the docker image and push to docker hub

``` bash
docker images
docker push susesamples/sles15sp1-spring-petclinic:2.2.0
```

## Step 3 - Ensure accessible to SUSE CaaS Platform

Run the kubectl command below to ensure you have access to a SUSE CaaS Platform.

Example:

``` bash
$ kubectl get node -o wide
NAME       STATUS     ROLES    AGE    VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                              KERNEL-VERSION           CONTAINER-RUNTIME
caasp-m1   Ready      master   187d   v1.17.4   192.168.0.32   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
caasp-m2   Ready      master   186d   v1.17.4   192.168.0.33   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
caasp-m3   Ready      master   187d   v1.17.4   192.168.0.34   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
caasp-w4   Ready      worker   187d   v1.17.4   192.168.0.38   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
caasp-w5   Ready      worker   187d   v1.17.4   192.168.0.39   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
caasp-w6   Ready      worker   120d   v1.17.4   192.168.0.40   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
caasp-w7   NotReady   worker   120d   v1.17.4   192.168.0.41   <none>        SUSE Linux Enterprise Server 15 SP1   4.12.14-197.34-default   cri-o://1.16.1
```

## Step 4 - Define a new namespace for petclinic app

``` bash
$ kubectl create ns susecon
```

## Step 6 - Store docker hub login credential in SUSE CaaS Platform

Since the petclinic image stored in dockerhub which requires authentication to access to it, we need to pass the docker hub credential to SUSE CaaSP to use. Specifically, we will let this petclinic namespace to use exclusively. 

Login to docker hub first in your linux terminal session. This will store your credential in `$HOME/.docker/config.json` file.

``` bash
docker login
```

Then, create a kubernetes secret object to store your docker hub credential in the susecon namespace.

``` bash
kubectl create secret generic docker-cred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --namespace susecon \
    --type=kubernetes.io/dockerconfigjson
```

Associate the docker-cred to default service account in susecon namespace.

``` bash
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "docker-cred"}]}' -n susecon
```

## Step 7 - Deploy the petclinic container image into SUSE CaaS Platform 

Create a deployment resource for petclinic container image.

``` bash
kubectl create deployment petclinic \
  --image=susesamples/sles15sp1-spring-petclinic:2.2.0 \
  --namespace=susecon
```

Expose petclinic to be accessible with nodeport.

``` bash
kubectl expose deployment/petclinic -n susecon --type="NodePort" --port 8080
```

``` bash
kubectl get svc -n susecon
NAME        TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
petclinic   NodePort   10.99.3.184   <none>        8080:31219/TCP   30h
```

In this example, the petclinic app is exposed with high port number 31219. It can be accessible with any worker node IP address which can be found with `kubectl get node -o wide` command.


## Step 8 - Navigate to the petclinic web url

In this example, you can navigate to `http://192.168.0.38:31219` where `.38` is an IP address of a worker node and `31219` is the port exposed by `NodePort`. This is the petclinic app url. Simple and done!

# Porting the java app to SUSE Cloud Application Platform

## Step 1 - Check out the source code of the spring-petclinic java application

If you haven't check out the source code from github, please check it out now with the command below.

```
git clone 
```

## Step 2 - Build a fat-jar package of the petclinic app with container-based maven tool

Run the container based maven tool to build the jar package of the petclinic locally.

```
docker run -it --rm --name petclinic-maven \
 -v "$PWD":/usr/src/app \
 -v "$HOME"/.m2:/root/.m2 \
 -w /usr/src/app maven:3-jdk-8-slim \
  mvn clean package
```

Check the output of the jar file:

```
ls -l target/*.jar
```

## Step 3 - Login to SUSE Cloud Application Platform with CLI

Set SUSE CAP Sand Box as API endpoint, login and then create a new space `susecon` for hosting petclinic app

``` bash
cf api https://api.cap.explore.suse.dev
cf login
cf create-space susecon
cf target -s susecon
```

## Step 4 - Push the code to SUSE Cloud Application Platform

Run the command below to push the code to SUSE CAP

``` bash
cf push petclinic -p target/spring-petclinic-2.3.0.BUILD-SNAPSHOT.jar
```

## Step 5 - Navigate to the petclinic web url

List the apps deployed

``` bash
$ cf apps
Getting apps in ...
OK

name        requested state   instances   memory   disk   urls
petclinic   started           1/1         1G       1G     petclinic.cap.explore.suse.dev
```

The web url is https://petclinic.cap.explore.suse.dev

## Step 6 - Explore Stratos

Navigate to SUSE CAP Sandbox (https://stratos.cap.explore.suse.dev)



