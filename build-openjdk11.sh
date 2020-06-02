#! /bin/bash

# Run this command on a SLES15SP1 host to build a sles15-based docker image

# Copy all zypper repos and services from SLES15SP1 docker host into etc/ folder
mkdir -p etc/repos.d
sudo cp /etc/zypp/repos.d/Basesystem_Module*.* etc/repos.d/
mkdir -p etc/services.d
sudo cp /etc/zypp/services.d/Basesystem_Module*.* etc/services.d/

# run docker build
docker build -t susesamples/sles15sp1-openjdk11 -f Dockerfile.sles15sp1-openjdk11 .

# clean up
rm -rf {cert,etc}

