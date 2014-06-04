# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty32"

  config.vm.provision "shell", path: "install.sh", privileged: false

  # 5 sites, 5 ports
  (1..5).each do |p|
    config.vm.network "forwarded_port", guest: 5000+p, host: 5000+p,
      auto_correct: true
  end
end
