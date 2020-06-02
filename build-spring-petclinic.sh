#! /bin/bash

# clone the source code of spring-petclinic into local directory
git clone https://github.com/spring-projects/spring-petclinic.git

# copy the Dockerfile to the source directory
cp Dockerfile.sles15sp1-spring-petclinic spring-petclinic/

# build the docker image
cd spring-petclinic
docker build -t susesamples/sles15sp1-spring-petclinic:2.2.0 -f Dockerfile.sles15sp1-spring-petclinic .


