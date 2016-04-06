# -*- mode: ruby -*-
# vi: set ft=ruby :
file_to_disk='./docker_disk.vdi'
Vagrant.configure(2) do |config|
  config.vm.box = "Sabayon/spinbase-amd64"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
     vb.gui = false
     vb.memory = "6096"
     vb.cpus = 3
     vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

config.persistent_storage.enabled = true
config.persistent_storage.location = file_to_disk
config.persistent_storage.size = 210000
config.persistent_storage.format = false
config.persistent_storage.use_lvm = false

unless File.exist?(file_to_disk)
 config.vm.provision "shell", path: "scripts/provision_hd.sh"
end

config.vm.provision "shell", path: "scripts/provision.sh"
config.vm.provision "shell", run: "always", path: "scripts/provision_always.sh"

end
