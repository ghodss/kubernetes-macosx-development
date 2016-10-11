# -*- mode: ruby -*-
# # vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

CONFIG = File.join(File.dirname(__FILE__), "config.rb")

require 'fileutils'

# Defaults for config options defined in CONFIG
$gopath = ""
$expose_docker_tcp = true
$mount_users_dir = true
$vb_gui = false
$vb_memory = 1024
$vb_cpus = 1
$home = ENV["HOME"]

if File.exist?(CONFIG)
  require CONFIG
end

# If $gopath was not set in the config but the environment variable exists, grab it.
if $gopath.empty? && ENV["GOPATH"]
  $gopath = ENV["GOPATH"]
end

# If $gopath is still empty, abort.
if $gopath.empty?
  abort("GOPATH env var must be set (or create a config.rb to specify it manually).\n")
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |c|
  c.vm.define vm_name = "k8s-env" do |config|
    config.vm.hostname = vm_name

    config.vm.box = "geerlingguy/centos7"
    #config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.2_chef-provisionerless.box"

    ip = "10.1.2.3"
    config.vm.network :private_network, ip: ip

    config.vm.boot_timeout = 3000

    if $expose_docker_tcp
      config.vm.network "forwarded_port", guest: 2375, host: 2375, auto_correct: true
    end

    if $mount_users_dir
      # config.vm.synced_folder $home, $home, id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      config.vm.synced_folder $home, $home, id: "core"
    end

    config.vm.provider :virtualbox do |vb|
      vb.gui = $vb_gui
      vb.memory = $vb_memory
      vb.cpus = $vb_cpus
    end

    config.vm.provision "shell", inline: "GOPATH=#{$gopath} /vagrant/setup.sh"
  end
end
