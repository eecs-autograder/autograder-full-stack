#! /bin/bash

# Install docker on ubuntu 16
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates

sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo sh -c "echo \"deb https://apt.dockerproject.org/repo ubuntu-xenial main\" > /etc/apt/sources.list.d/docker.list"

sudo apt-get update
sudo apt-get purge lxc-docker
apt-cache policy docker-engine

sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install -y docker-engine
sudo systemctl enable docker

sudo service docker start
sudo docker run hello-world

sudo groupadd docker
sudo usermod -aG docker $USER

sudo sh -c "curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose
