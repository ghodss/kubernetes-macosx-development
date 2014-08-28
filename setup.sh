#!/bin/bash

set -e
echo "Setting up VM..."


echo "Installing system tools..."
yum -y install yum-fastestmirror git
echo "Complete."


echo "Installing go 1.3.1..."
wget -q https://storage.googleapis.com/golang/go1.3.1.linux-amd64.tar.gz
tar -C /usr/local/ -xzf go1.3.1.linux-amd64.tar.gz
ln -s /usr/local/go/bin/* /usr/bin/
echo "Complete."


echo "Installing docker..."
yum -y install docker-io
systemctl start docker
systemctl enable docker
# Supposedly you don't have to do this starting docker 1.0
# (fedora 20 is currently 1.1.2) but I found it necessary.
usermod -a -G docker vagrant
echo "Complete."


echo "Setting gopath, adding gopath/bin to PATH, and other config..."

echo "export GOPATH=~/gopath" >> /etc/bashrc
echo "export PATH=$PATH:/home/vagrant/gopath/bin" >> /etc/bashrc

# The NFS mount is initially owned by root - it should be owned by vagrant.
chown vagrant.vagrant gopath

# For some reason /etc/hosts does not alias localhost to 127.0.0.1.
echo "127.0.0.1 localhost" >> /etc/hosts

echo "Complete."


echo "Installing godep and etcd..."
go get github.com/tools/godep && go install github.com/tools/godep
go get github.com/coreos/etcd && go install github.com/coreos/etcd
echo "Complete."


echo "Setup complete."
