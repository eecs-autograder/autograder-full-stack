#! /usr/bin/env bash

# Update apt first (system package installer)
sudo apt update

# Install the only editors you'll ever need. LOLLLLL
sudo apt install vim emacs --yes

sudo apt install git

# install Docker
sudo apt install -y apt-transport-https ca-certificates

sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo sh -c "echo \"deb https://apt.dockerproject.org/repo ubuntu-xenial main\" > /etc/apt/sources.list.d/docker.list"

sudo apt update
sudo apt purge lxc-docker
apt-cache policy docker-engine

sudo apt install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt install -y docker-engine
sudo systemctl enable docker

sudo systemctl start docker
sudo docker run hello-world

sudo groupadd docker
sudo usermod -aG docker $USER

sudo sh -c "curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose

sudo docker-compose -f docker-compose-dev.yml build
sudo docker-compose -f docker-compose-dev.yml up -d

sudo apt install -y npm
npm --version
nodejs --version
# sudo ln -s /usr/bin/nodejs /usr/local/bin/node

cd ag-web-typescript
npm install
sudo npm install --global typescript@2.1.0-dev.20160920
tsc

