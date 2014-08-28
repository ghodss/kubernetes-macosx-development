# -*- mode: ruby -*-
# # vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

CONFIG = File.join(File.dirname(__FILE__), "config.rb")

require 'fileutils'

# Defaults for config options defined in CONFIG
$gopath = ""
$expose_docker_tcp = true
$vb_gui = false
$vb_memory = 1024
$vb_cpus = 1

if File.exist?(CONFIG)
  require CONFIG
end

# If $gopath was not set in the config but the environment variable exists, grab it.
if $gopath.empty? && ENV["GOPATH"]
  $gopath = ENV["GOPATH"]
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |c|
  c.vm.define vm_name = "k8s-env" do |config|
    config.vm.hostname = vm_name

    config.vm.box = "fedora20"
    config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_fedora-20_chef-provisionerless.box"

    ip = "10.240.1.2"
    config.vm.network :private_network, ip: ip

    if $expose_docker_tcp
      config.vm.network "forwarded_port", guest: 2375, host: 2375, auto_correct: true
    end

    # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
    unless $gopath.empty?
      $gopath_src_dir = File.join($gopath, "/src")
      config.vm.synced_folder $gopath_src_dir, "/home/vagrant/gopath/src", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
    end

    config.vm.provider :virtualbox do |vb|
      vb.gui = $vb_gui
      vb.memory = $vb_memory
      vb.cpus = $vb_cpus
    end

    config.vm.provision "shell", inline: "/vagrant/setup.sh"
  end
end
