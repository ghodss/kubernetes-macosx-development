# Developing Kubernetes on Mac OS X

Kubernetes comes with a great script that lets you run an entire cluster locally using your current source code tree named `hack/local-up-cluster.sh`. However, it only runs on Linux, which means that if you're developing on your Mac you have to copy your source tree to a Linux machine to use the script (or switch to a Linux machine for development). Go in general, however, runs fine on Mac, so here is the flow that this Vagrant configuration aims to enable:

* Edit source files on your Mac's checkout of Kubernetes (in your $GOPATH) and use `go build` (for syntax checking) and `go test` (for unit tests) directly on your Mac.
* Run `vagrant up` (in this directory) to automatically:
 * Launch a Fedora 20 VM on your Mac that has Go and Docker installed on the IP 10.245.1.2.
 * Mount your Mac's $GOPATH/src directory into the VM at `/home/vagrant/gopath/src` to share your Mac's code with the VM.
 * Enable the ability to run a kubernetes cluster using `hack/local-up-cluster.sh`.
 * Eliminate the need for boot2docker: Use Docker in the VM for building and releasing Kubernetes by forwarding Docker's port (2375) to localhost (this is done by default).

# Getting started

Git clone this repo, `cd` into it then run `vagrant up` inside. That will start up the VM and bootstrap it with docker, golang and kubernetes (amongst other things; see [setup.sh](setup.sh) for the complete bootstrapping process). Use `vagrant ssh` to SSH into the VM. Enter the `k` command (which is an alias to cd into the kubernetes directory), then enter `hack/local-up-cluster.sh` to start up a cluster.

If you want to tweak the config, copy `config.sample.rb` to `config.rb` and make any modifications you like.

# Warnings

Running `vagrant up` MAY modify your $GOPATH: `go get` [github.com/tools/godep](https://github.com/tools/godep) and [github.com/coreos/etcd](https://github.com/coreos/etcd) will both be run in your $GOPATH.

This configuration has only been explicitly tested on Mac OS X 10.9.3. It should work on other versions but no guarantees.

# TODO

* Every time the Fedora 20 box is initially created, the first time `yum install` runs there is a 30-60 second delay while the first few mirrors fail. It would be great to figure out how to directly use a working mirror while still using fastestmirror for subsequent yum install commands.
