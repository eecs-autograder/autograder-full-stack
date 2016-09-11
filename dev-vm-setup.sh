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

# Install dart on ubuntu 16
wget https://storage.googleapis.com/dart-archive/channels/stable/release/latest/linux_packages/debian_wheezy/dart_1.18.1-1_amd64.deb
sudo dpkg -i dart_1.18.1-1_amd64.deb
sudo apt-get install -y -f

echo "export PATH=\"/usr/lib/dart/bin/:$PATH\"" >> $HOME/.bashrc

sudo apt-get install openssh-server

# The Chromium desktop file should go in ~/.local/share/applications (or just use alacarte)
# Build the docker setup with `docker-compose build`
# Run it with `docker-compose up`
# You need to download and install dartium manually
# Remember to apply migrations to the ag-dev-django container
# Remember to make yourself a superuser

echo "Please log out and back in to complete the changes"
