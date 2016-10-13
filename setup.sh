#!/bin/bash

# A provisioning script for the created Vagrant vm.
# This script is referred from the Vagrant file and it is executed during the
# provisioning phase of starting a new vm.
# Note: For this script to work there should be only one path in GOPATH env.
# Everything in this file is run as root on the VM.


function install_system_tools() {
   echo "Installing system tools..."
   yum -y install epel-release
   # Packages useful for testing/interacting with containers and
   # source control tools are so go get works properly.
   # net-tools: for ifconfig
   yum -y install yum-fastestmirror git mercurial subversion curl nc gcc net-tools
}

# Add a repository to yum so that we can download
# supported version of docker.
function add_docker_yum_repo() {
   tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
}

# Set up yum and install the supported version of docker
function install_docker() {
   add_docker_yum_repo

   yum -y install docker-engine-1.10.3
}

# Set docker daemon comand line options. We modify systemd configuration
# for docker to start with our desired options.
# Keep in mind that at this point this
# overrides any existing options supplied by the RPM. This is overridden to
# make sure docker is listening on all network interfaces.
function set_docker_daemon_options() {
   echo "" > /etc/sysconfig/docker
   mkdir -p /etc/systemd/system/docker.service.d
   tee /etc/systemd/system/docker.service.d/docker.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --selinux-enabled -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
EOF
}

# configure_and_start_docker starts the docker service using systemctl
function configure_and_start_docker() {

   set_docker_daemon_options

   systemctl daemon-reload
   systemctl start docker
   systemctl enable docker
   echo "Docker daemon started."
}

# Downloads the file with wget if it does not exist in the current directory.
# The user passes the wget argument path to this function as the first parameter
function ensure_file_is_downloaded() {
   local wgetArg=$1
   local fileName=$(basename "${wgetArg}")
   if [ -f "${fileName}" ]; then
      echo "File: ${fileName} already exists in $(pwd) skipping download"
   else
      echo "Downloading file: ${fileName}"
      wget -q "${wgetArg}"
   fi
}

# Install go at the given version. The desired version string is passed as the
# first parameter of the function.
# Example usage:
# install_go "1.6.2"
function install_go() {
   # Creating a subshell so that changes in this function do not "escape" the
   # function. For example change directory.
   (
      cd /vagrant

      local goVersion=$1
      local goBinary=go${goVersion}.linux-amd64.tar.gz
      echo "Installing go ${goVersion}..."
      ensure_file_is_downloaded  https://storage.googleapis.com/golang/$goBinary
      tar -C /usr/local/ -xzf $goBinary
      ln -sf /usr/local/go/bin/* /usr/bin/
      echo "Installed go ${goVersion}."
   )
}

# Kubernetes development requires at least etcd version
function install_etcd() {
   # Creating a subshell so that changes in this function do not "escape" the
   # function. For example change directory.
   (
      cd /vagrant

      etcdVersion=$1
      echo "Installing etcd ${etcdVersion}..."
      etcdName=etcd-${etcdVersion}-linux-amd64
      etcdBinary=${etcdName}.tar.gz
      ensure_file_is_downloaded https://github.com/coreos/etcd/releases/download/${etcdVersion}/${etcdBinary}
      tar -C /usr/local/ -xzf ${etcdBinary}
      rm -rf  /usr/local/etcd
      mv -n /usr/local/${etcdName} /usr/local/etcd
      ln -sf /usr/local/etcd/etcd /usr/bin/etcd
      ln -sf /usr/local/etcd/etcdctl /usr/bin/etcdctl
      echo "Installed etcd ${etcdVersion}."
   )
}

# Knowing the HOST_GOPATH, set up the gopath in the Guest.
# Not that this setup assumes that the HOST_GOPATH will be in the
# /Users directory tree in the host machine. The Vagrantfile sets up
# the /Users directory as a synced_folder. So the HOST_GOPATH that is under
# /Users will be visible in the Vagrant vm.
function setup_gopath() {
   local hostGopath=$1
   local guestGopath=$2
   echo "Creating a GOPATH in ${guestGopath} local to the VM..."
   # Create a gopath and symlink in the src directory. (Since we don't want to
   # share bin/ and pkg/ since they are platform dependent.)
   mkdir -p ${guestGopath}/bin ${guestGopath}/pkg
   ln -sf ${hostGopath}/src ${guestGopath}/src
   chown -R vagrant:vagrant ${guestGopath}
   echo "Completed GOPATH setup"
}


# There are several go install and go get's to be executed.
# Kubernetes and go development may require these.
function install_go_packages() {

   echo "Installing go packages"

   # kubernetes asks for this while building.
   # FixMe: Should we execute the following command also as vagrant or not ?
   CGO_ENABLED=0 go install -a -installsuffix cgo std

   # Install godep
   sudo -u vagrant -E go get github.com/tools/godep
   sudo -u vagrant -E go install github.com/tools/godep

   # Kubernetes compilation requires this
   sudo -u vagrant -E go get -u github.com/jteeuwen/go-bindata/go-bindata

   echo "Completed install_go_packages"
}


# Populate a /etc/profile.d file so that several setup tasks are done
# automatically at every login
function write_profile_file() {
   local guestGopath=$1
   local guestIp=$2
echo "Creating /etc/profile.d/kubernetes.sh to set GOPATH, KUBERNETES_PROVIDER and other config..."
cat >/etc/profile.d/kubernetes.sh <<EOL
# Golang setup.
export GOPATH=${guestGopath}
export PATH=\$PATH:${guestGopath}/bin
# So docker works without sudo.
export DOCKER_HOST=tcp://127.0.0.1:2375
# So you can start using cluster/kubecfg.sh right away.
export KUBERNETES_PROVIDER=local
# Run apiserver on guestIP (instead of 127.0.0.1) so you can access
# apiserver from your OS X host machine.
export API_HOST=${guestIp}
# So you can access apiserver from kubectl in the VM.
export KUBERNETES_MASTER=\${API_HOST}:8080

# For convenience.
alias k="cd \$GOPATH/src/k8s.io/kubernetes"
alias killcluster="ps axu|grep -e go/bin -e etcd |grep -v grep | awk '{print \\\$2}' | xargs kill"
alias kstart="k && killcluster; hack/local-up-cluster.sh"
EOL
}



set -e
set -x


if [ -z "${GUEST_IP}" ]; then
   GUEST_IP=127.0.0.1
fi
if [ -z "${HOST_GOPATH}" ]; then
   echo "HOST_GOPATH is not set. Please set HOST_GOPATH to the GOPATH in the host os and retry"
   exit 1
fi


echo "Setting up VM..."

install_system_tools

install_docker
configure_and_start_docker

# Get the go and etcd releases.
install_go "1.6.3"
# Latest kubernetes requires a recent version of etcd
install_etcd "v3.0.10"

# HOST_GOPATH is passed by the VagrantFile looking at the Mac's environment.
GUEST_GOPATH=/home/vagrant/gopath
setup_gopath "${HOST_GOPATH}" "${GUEST_GOPATH}"
# The rest of the script installed some gobinaries. So the GOPATH needs to be known
# from this point on .
export GOPATH=${GUEST_GOPATH}

install_go_packages
write_profile_file  "${GUEST_GOPATH}" "${GUEST_IP}"


# For some reason /etc/hosts does not alias localhost to 127.0.0.1.
echo "127.0.0.1 localhost" >> /etc/hosts

# kubelet complains if this directory doesn't exist.
mkdir -p /var/lib/kubelet

# The NFS mount is initially owned by root - it should be owned by vagrant.
chown vagrant.vagrant /Users

echo "Setup complete."


