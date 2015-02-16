# -*- mode: ruby -*-
# vi: set ft=ruby :

$set_docker_options = <<SCRIPT
cat > /etc/default/docker <<EOL

# Docker Upstart and SysVinit configuration file

# Customize location of Docker binary (especially for development testing).
#DOCKER="/usr/local/bin/docker"

# Use DOCKER_OPTS to modify the daemon startup options.
#DOCKER_OPTS="--dns 10.30.0.254 --dns 10.30.1.254"

# If you need Docker to use an HTTP proxy, it can also be specified here.
#export http_proxy="http://127.0.0.1:3128/"

# This is also a handy place to tweak where Docker's temporary files go.
#export TMPDIR="/mnt/bigdrive/docker-tmp"
DOCKER_OPTS="-r=true --insecure-registry docker.otenv.com ${DOCKER_OPTS}"

EOL
SCRIPT

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.box = "phusion-open-ubuntu-14.04-amd64"
	config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"

	config.vm.synced_folder ".", "/home/slate"

	config.vm.provider "virtualbox" do |v|
		v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
	end

	config.vm.provision "shell", :inline => $set_docker_options

	config.vm.define :docker do |t|
	end

	config.vm.provision "docker" do |d|
	end

	config.vm.provision "shell", :inline => "sudo service docker restart"
end

# For Windows, when the machine is loaded, run:
# 1. vagrant ssh
# 2. sudo ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
# 3. exit
# 4. vagrant reload
