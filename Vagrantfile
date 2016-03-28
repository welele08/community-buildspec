# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  config.vm.box = "Sabayon/spinbase-amd64"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
     vb.gui = false
     vb.memory = "6096"
     vb.cpus = 3
  end
  config.vm.provision "shell", inline: <<-SHELL
    mkdir -p /usr/portage/licenses/
    rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
    ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept

    equo up && sudo equo u
    echo -5 | equo conf update
    equo i docker sabayon-devkit vixie-cron git wget curl ansifilter md5deep dev-perl/JSON dev-perl/libwww-perl dev-python/pip sys-fs/btrfs-progs
    pip install shyaml

    mkdir /etc/systemd/system/docker.service.d/
    echo "[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=btrfs -H fd://
" > /etc/systemd/system/docker.service.d/vagrant_mount.conf
    # append -g /vagrant/docker_cache/ to args to specify a default location
    if [ ! -f "/vagrant/btrfs.img" ]; then
      echo "Generating BTRFS image. Hang on, it could take a while. If you don't want me to create that for you, create a btrfs.img file inside the buildpsec directory"
      echo "> equo i sys-fs/btrfs-progs"
      echo "> dd if=/dev/zero of=btrfs.img count=<SIZE> bs=1G"
      echo "> losetup /dev/loop0 btrfs.img"
      echo "> mkfs.btrfs /dev/loop0"
      dd if=/dev/zero of=/vagrant/btrfs.img count=200 bs=1G
      losetup /dev/loop0 /vagrant/btrfs.img
      mkfs.btrfs /dev/loop0
    else
      echo "BTRFS image locally detected, using it"
      losetup /dev/loop0 /vagrant/btrfs.img
    fi
    mount /dev/loop0 /var/lib/docker
    echo "/vagrant/btrfs.img /var/lib/docker btrfs loop 0 0" >> /etc/fstab


    systemctl daemon-reload

    systemctl enable docker
    systemctl start docker

    systemctl enable vixie-cron
    systemctl start vixie-cron
    crontab /vagrant/confs/crontab
    git clone https://github.com/Sabayon/community-repositories.git /vagrant/repositories
    timedatectl set-ntp true
    echo "@@@@ Provision finished, ensure everything is set up for deploy, suggestion is to reboot the machine to ensure docker is working correctly"
  SHELL
end
