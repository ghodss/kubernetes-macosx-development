#!/bin/bash

set -e
echo "Setting up VM..."


echo "Installing system tools and docker..."
# Packages useful for testing/interacting with containers and
# source control tools are so go get works properly.
# TODO Currently (v0.7.3) Kubernetes only works with etcd 0.4.6 - later
# remove specific etcd version from yum install command.
yum -y install yum-fastestmirror git mercurial subversion docker-io etcd-0.4.6-6.fc20 curl nc
# Docker setup.
systemctl start docker
systemctl enable docker
# Set docker daemon comand line options. Keep in mind that at this point this
# overrides any existing options. This is overridden to make sure docker is
# listening on all network interfaces.
echo "OPTIONS=--selinux-enabled -H tcp://0.0.0.0:2375" > /etc/sysconfig/docker
# Supposedly you don't have to do this starting docker 1.0
# (Fedora 20 is currently 1.1.2) but I found it necessary.
usermod -a -G docker vagrant
echo "Complete."


echo "Installing go 1.3.1..."
GOBINARY=go1.3.1.linux-amd64.tar.gz
wget -q https://storage.googleapis.com/golang/$GOBINARY
tar -C /usr/local/ -xzf $GOBINARY
ln -s /usr/local/go/bin/* /usr/bin/
rm $GOBINARY
echo "Complete."


echo "Creating /etc/profile.d/k8s.sh to set GOPATH, KUBERNETES_PROVIDER and other config..."
cat >/etc/profile.d/k8s.sh << 'EOL'
# Golang setup.
export GOPATH=~/gopath
export PATH=$PATH:~/gopath/bin
# So you can start using cluster/kubecfg.sh right away.
export KUBERNETES_PROVIDER=local
# Run apiserver on 10.245.1.2 (instead of 127.0.0.1) so you can access
# apiserver from your OS X host machine.
export API_HOST=10.245.1.2
# So you can access apiserver from kubectl in the VM.
export KUBERNETES_MASTER=10.245.1.2:8080

# For convenience.
alias k="cd ~/gopath/src/github.com/GoogleCloudPlatform/kubernetes"
alias killcluster="ps axu|grep -e go/bin -e etcd |grep -v grep | awk '{print \$2}' | xargs kill"
alias kstart="k && killcluster; hack/local-up-cluster.sh"
EOL

# For some reason /etc/hosts does not alias localhost to 127.0.0.1.
echo "127.0.0.1 localhost" >> /etc/hosts

# kubelet complains if this directory doesn't exist.
mkdir /var/lib/kubelet

# The NFS mount is initially owned by root - it should be owned by vagrant.
chown vagrant.vagrant /home/vagrant/gopath

echo "Complete."


echo "Installing godep and etcd..."
# Disable requiring TTY for the sudo commands below.
sed -i 's/requiretty/\!requiretty/g' /etc/sudoers
# TODO Should we source k8s.sh instead?
export GOPATH=/home/vagrant/gopath
# Go will compile on both Mac OS X and Linux, but it will create different
# compilation artifacts on the two platforms. By mounting only GOPATH's src
# directory into the VM, you can run `go install <package>` on the Fedora VM
# and it will correctly compile <package> and install it into
# /home/vagrant/gopath/bin.
sudo -u vagrant -E go get github.com/tools/godep && sudo -u vagrant -E go install github.com/tools/godep
echo "Complete."

echo "Setup complete."
