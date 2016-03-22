# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  config.vm.box = "Sabayon/spinbase-amd64"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
     vb.gui = false
     vb.memory = "4096"
     vb.cpus = 3
  end

  config.vm.provision "shell", inline: <<-SHELL
    mkdir -p /usr/portage/licenses/
    rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
    ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept

    equo up && sudo equo u
    echo -5 | equo conf update
    equo i docker sabayon-devkit vixie-cron git wget curl ansifilter md5deep dev-perl/JSON dev-perl/libwww-perl

    systemctl enable docker
    systemctl start docker

    systemctl daemon-reload
    systemctl enable vixie-cron
    systemctl start vixie-cron
    crontab /vagrant/confs/crontab
    git clone https://github.com/Sabayon/community-repositories.git /vagrant/repositories
    rm -rf /vagrant/repositories/.git
    echo "@@@@ Provision finished, ensure everything is set up for deploy, suggestion is to reboot the machine to ensure docker is working correctly"
  SHELL
end
