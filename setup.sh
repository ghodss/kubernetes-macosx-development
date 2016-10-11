#/!/bin/bash

# Everything in this file is run as root on the VM.


# Set docker daemon comand line options. We modify systemd configuration
# for docker to start with our desired options.
# Keep in mind that at this point this
# overrides any existing options supplied by the RPM. This is overridden to
# make sure docker is listening on all network interfaces.
function setDockerDaemonOptions() {
   echo "" > /etc/sysconfig/docker
   mkdir /etc/systemd/system/docker.service.d
   tee /etc/systemd/system/docker.service.d/docker.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --selinux-enabled -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
EOF
}

# startDocker starts the docker service using systemctl
function startDocker() {
   systemctl daemon-reload
   systemctl start docker
   systemctl enable docker
   echo "Docker daemon started."
}

set -e
set -x

echo "Setting up VM..."


echo "Installing system tools..."
yum -y install epel-release
# Packages useful for testing/interacting with containers and
# source control tools are so go get works properly.
yum -y install yum-fastestmirror git mercurial subversion curl nc gcc

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum -y install docker-engine-1.10.3

# Set docker daemon comand line options. Keep in mind that at this point this
# overrides any existing options supplied by the RPM. This is overridden to
# make sure docker is listening on all network interfaces.
echo "" > /etc/sysconfig/docker
mkdir /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/docker.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --selinux-enabled -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
EOF

# # Start docker.
# systemctl start docker
# # Start docker on startup.
# systemctl enable docker
# echo "Complete."


GOVERSION=1.6.2
GOBINARY=go${GOVERSION}.linux-amd64.tar.gz
echo "Installing go ${GOVERSION}..."
wget -q https://storage.googleapis.com/golang/$GOBINARY
tar -C /usr/local/ -xzf $GOBINARY
ln -sf /usr/local/go/bin/* /usr/bin/
rm -f $GOBINARY
echo "Complete."


#ETCDVERSION=v2.2.2
#echo "Installing etcd ${ETCDVERSION}..."
#ETCDNAME=etcd-${ETCDVERSION}-linux-amd64
#ETCDBINARY=${ETCDNAME}.tar.gz
#wget -q https://github.com/coreos/etcd/releases/download/${ETCDVERSION}/${ETCDBINARY}
#tar -C /usr/local/ -xzf ${ETCDBINARY}
#mv /usr/local/${ETCDNAME} /usr/local/etcd
#ln -s /usr/local/etcd/etcd /usr/bin/etcd
#ln -s /usr/local/etcd/etcd-migrate /usr/bin/etcd-migrate
#ln -s /usr/local/etcd/etcdctl /usr/bin/etcdctl
#rm $ETCDBINARY
#echo "Complete."


echo "Creating a GOPATH in /home/vagrant/gopath local to the VM..."
# Create a gopath and symlink in the src directory. (Since we don't want to
# share bin/ and pkg/ since they are platform dependent.)
mkdir -p /home/vagrant/gopath/bin /home/vagrant/gopath/pkg
ln -s $GOPATH/src /home/vagrant/gopath/src
chown -R vagrant:vagrant /home/vagrant/gopath
echo "Complete."


echo "Creating /etc/profile.d/kubernetes.sh to set GOPATH, KUBERNETES_PROVIDER and other config..."
cat >/etc/profile.d/kubernetes.sh << 'EOL'
# Golang setup.
export GOPATH=~/gopath
export PATH=$PATH:~/gopath/bin
# So docker works without sudo.
export DOCKER_HOST=tcp://127.0.0.1:2375
# So you can start using cluster/kubecfg.sh right away.
export KUBERNETES_PROVIDER=local
# Run apiserver on 10.1.2.3 (instead of 127.0.0.1) so you can access
# apiserver from your OS X host machine.
export API_HOST=10.1.2.3
# So you can access apiserver from kubectl in the VM.
export KUBERNETES_MASTER=${API_HOST}:8080

# For convenience.
alias k="cd $GOPATH/src/k8s.io/kubernetes"
alias killcluster="ps axu|grep -e go/bin -e etcd |grep -v grep | awk '{print \$2}' | xargs kill"
alias kstart="k && killcluster; hack/local-up-cluster.sh"
EOL

# For some reason /etc/hosts does not alias localhost to 127.0.0.1.
echo "127.0.0.1 localhost" >> /etc/hosts

# kubelet complains if this directory doesn't exist.
mkdir /var/lib/kubelet

# kubernetes asks for this while building.
CGO_ENABLED=0 go install -a -installsuffix cgo std

# The NFS mount is initially owned by root - it should be owned by vagrant.
chown vagrant.vagrant /Users

echo "Complete."


echo "Installing godep..."
# Disable requiring TTY for the sudo commands below.
sed -i 's/requiretty/\!requiretty/g' /etc/sudoers
# TODO Should we source kubernetes.sh instead?
export GOPATH=/home/vagrant/gopath
# Go will compile on both Mac OS X and Linux, but it will create different
# compilation artifacts on the two platforms. By mounting only GOPATH's src
# directory into the VM, you can run `go install <package>` on the Fedora VM
# and it will correctly compile <package> and install it into
# /home/vagrant/gopath/bin.
sudo -u vagrant -E go get github.com/tools/godep && sudo -u vagrant -E go install github.com/tools/godep
echo "Complete."

startDocker
echo "Setup complete."
