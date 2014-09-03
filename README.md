# Developing Kubernetes on Mac OS X

Kubernetes only runs on Linux, which means developing on Mac is a bit awkward. Go, however, runs fine on Mac, so here is the flow that this Vagrant configuration aims to enable:

* Edit source files on your Mac's checkout of Kubernetes (in your GOPATH) and use `go build` and `go test` (for unit tests) directly on your Mac.
* `vagrant up` to:
 * Launch a Fedora 20 VM on your Mac that has Go and Docker installed on the IP 10.240.1.2.
 * Mount your gopath's src directory into the VM at /home/vagrant/gopath/src to share your Mac's code with the VM.
 * Enable the ability to run a kubernetes cluster using hack/local-up-cluster.sh.
 * Use Docker in the VM for building and releasing Kubernetes by forwarding Docker's port (2375) to localhost, thereby eliminating the need for boot2docker.

# Getting started

Git clone this repo then run `vagrant up` inside. That should be it. If you want to tweak the config, copy `config.sample.rb` to `config.rb` and make any modifications you like.

Once you've done `vagrant up`, use `vagrant ssh` to ssh into the VM. Enter the `k` command (which is an alias to cd into the kubernetes directory), then enter `hack/local-up-cluster.sh` to start up a cluster.

# Warnings

Note that when you use this setup, all compiled binaries that Kubernetes uses will be compiled for Linux and therefore incompabile on Mac. E.g., cluster/kubecfg.sh is now only usable in the VM.

This script WILL `go get` [godep](https://github.com/tools/godep) and [etcd](https://github.com/coreos/etcd) to your gopath if they are not already there.

This configuration has only been explicitly tested on Mac OS X 10.9.3. It should work on other versions but no guarantees.

# TODO

* Every time the Fedora 20 box is initially created, the first time `yum install` runs there is a 30-60 second delay while the first few mirrors fail. It would be great to figure out how to directly use a working mirror while still using fastestmirror for subsequent yum install commands.
