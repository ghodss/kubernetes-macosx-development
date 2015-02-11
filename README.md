# Developing Kubernetes on Mac OS X

Kubernetes comes with a great script that lets you run an entire cluster locally using your current source code tree named `hack/local-up-cluster.sh`. However, it only runs on Linux, which means that if you're developing on your Mac you have to copy your source tree to a Linux machine to use the script (or switch to a Linux machine for development). Go in general, however, runs fine on Mac, so here is the flow that this Vagrant configuration aims to enable:

* Edit source files on your Mac's checkout of Kubernetes (in your $GOPATH) and use `go build` (for syntax checking) and `go test` (for unit tests) directly on your Mac.
* Run `vagrant up` (in this directory) to automatically:
 * Launch a Fedora 20 VM on your Mac that has Go and Docker installed on the IP 10.245.1.2.
 * Mount your Mac's $GOPATH/src directory into the VM at `/home/vagrant/gopath/src` to share your Mac's code with the VM.
 * Enable the ability to run a Kubernetes cluster using `hack/local-up-cluster.sh`.
 * Eliminate the need for boot2docker: Use Docker in the VM for building and releasing Kubernetes by forwarding Docker's port (2375) to localhost (this is done by default).

# Getting started

You must have the following requirements:

* Virtualbox (https://www.virtualbox.org/)
* Vagrant (https://www.vagrantup.com/)
* Go and a proper GOPATH on your Mac. (See https://golang.org/doc/code.html for more information.)

Next, install Kubernetes to your GOPATH by running `go get github.com/GoogleCloudPlatform/kubernetes`. If you want to write and contribute code, fork Kubernetes with your user on GitHub, and add your repo as a remote to your local checkout by running:

```
$ export GITHUB_USERNAME=<your github username>
$ cd $GOPATH/src/github.com/GoogleCloudPlatform/kubernetes
$ git remote add $GITHUB_USERNAME https://github.com/$GITHUB_USERNAME/kubernetes
```

Now you can push branches to your fork and issue pull requests against Kubernetes.

Once you have a Kubernetes checkout in your GOPATH, git clone this repo (it does not need to be in your GOPATH), `cd` into it then run `vagrant up` inside. That will start up the VM and bootstrap it with docker, go, and a mount of your kubernetes checkout (amongst other things; see [setup.sh](setup.sh) for the complete bootstrapping process). Use `vagrant ssh` to SSH into the VM. Enter the `k` command (which is an alias to cd into the kubernetes directory), then enter `hack/local-up-cluster.sh` to start up a cluster.

The kubernetes apiserver is run on 10.245.1.2, not on 127.0.0.1, in order to enable access from your OS X host machine. If you want to use kubectl from your Mac, run `export KUBERNETES_MASTER=10.245.1.2:8080` (the VM's environment is already preconfigured as such).

If you want to tweak the Vagrant config, copy `config.sample.rb` to `config.rb` and make any modifications you like.

# Warnings

Running `vagrant up` MAY modify your Mac's GOPATH: `go get` [github.com/tools/godep](https://github.com/tools/godep) will be run in your GOPATH.

Sometimes the `$GOPATH/src` NFS mount gets wedged and you get strange errors like `Boffset: unknown state 0`, `Bseek: unknown state 0`, or that the mount isn't working. If this happens just run `vagrant reload` which will shut down and restart the VM and should fix the mount errors.

This configuration has only been explicitly tested on Mac OS X 10.9. It should work on other versions but no guarantees.
