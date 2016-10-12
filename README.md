# Developing Kubernetes on Mac OS X

Kubernetes comes with a great script that lets you run an entire cluster locally using your current source code tree named `hack/local-up-cluster.sh`. However, it only runs on Linux, which means that if you're developing on your Mac you have to copy your source tree to a Linux machine to use the script (or switch to a Linux machine for development). Go in general, however, runs fine on Mac, so here is the flow that this Vagrant configuration aims to enable:

* Edit source files on your Mac's checkout of Kubernetes and use `go build` (for syntax checking) and `go test` (for unit tests) directly on your Mac.
* Run `vagrant up` (in this directory) to automatically:
 * Launch a Centos 7 VM on your Mac that has Go and Docker installed on the IP 10.1.2.3.
 * Mount your Mac's `/Users` directory into the VM at `/Users` to share your Mac's code with the VM.
 * Enable the ability to run a Kubernetes cluster using `hack/local-up-cluster.sh`.
 * Eliminate the need for docker-machine: Use Docker in the VM for building and releasing Kubernetes by forwarding Docker's port (2375) to localhost (this is done by default).

# Getting started

You must have the following installed:

* Virtualbox (https://www.virtualbox.org/)
* Vagrant (https://www.vagrantup.com/)
* Go and a proper GOPATH on your Mac (see https://golang.org/doc/code.html for more information)

Next, install Kubernetes to your GOPATH by running `go get k8s.io/kubernetes/...`. If you want to write and contribute code, fork Kubernetes with your user on GitHub, and add your repo as a remote to your local checkout by running:

```
$ export GITHUB_USERNAME=<your github username>
$ cd $GOPATH/src/k8s.io/kubernetes
$ git remote add $GITHUB_USERNAME https://github.com/$GITHUB_USERNAME/kubernetes
```

Now you can push branches to your fork and issue pull requests against Kubernetes.

Once you have a Kubernetes checkout in your GOPATH:

1. `git clone` this repo (it does not need to be in your GOPATH) and `cd` into it.
1. Run `vagrant up`. That will start up the VM and bootstrap it with docker, go, and a mount of your Mac's `/Users` directory (amongst other things; see [setup.sh](setup.sh) for the complete bootstrapping process).
1. Use `vagrant ssh` to SSH into the VM.
1. `cd` into your Kubernetes directory (which should be at the same path as it is on your Mac).
1. Enter `hack/local-up-cluster.sh` to start up a cluster using the code in your checkout.

The kubernetes apiserver is run on 10.1.2.3, not on 127.0.0.1, in order to enable access from your OS X host machine. If you want to use kubectl from your Mac, run `export KUBERNETES_MASTER=10.1.2.3:8080` (the VM's environment is already preconfigured as such).

If you want to tweak the Vagrant config, copy `config.sample.rb` to `config.rb` and make any modifications you like.

# Warnings

Running `vagrant up` MAY modify your Mac's GOPATH: `go get github.com/tools/godep` will be run in your GOPATH.

Sometimes the `/Users` NFS mount gets wedged and you get strange errors like `Boffset: unknown state 0`, `Bseek: unknown state 0`, or that the mount isn't working. If this happens just run `vagrant reload` which will shut down and restart the VM and should fix the mount errors.

If you ever have trouble compiling, try running `make clean` in the kubernetes source directory. It can solve many issues.

This configuration has only been explicitly tested on Mac OS X 10.9 and 10.10. It should work on other versions but no guarantees.
