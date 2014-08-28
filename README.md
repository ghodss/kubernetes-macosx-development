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

# Warnings

This script WILL `go get` [godep](https://github.com/tools/godep) and [etcd](https://github.com/coreos/etcd) to your gopath if they are not already there.

This configuration has only been explicitly tested on Mac OS X 10.9.3. It should work on other versions but no guarantees.

