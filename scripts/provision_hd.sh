#!/bin/bash
set -e
set -x
if [ -f /etc/provision_env_disk_added_date ]
then
#vgscan
#vgchange -a y
echo "Provision runtime already done."
exit 0
fi
dd if=/dev/zero of=/dev/sdb bs=512 count=1 conv=notrunc
#sudo pvcreate /dev/sdb
#vgcreate vg-docker /dev/sdb
#lvcreate -n datapool -L 350G vg-docker
#lvcreate -n metapool -L 149 vg-docker

#lvconvert -y --zero n --thinpool vg-docker/datapool --poolmetadata vg-docker/metapool

# BTRFS
sudo mkfs.btrfs -f /dev/sdb
sudo mkdir -p /var/lib/docker
echo "/dev/sdb /var/lib/docker btrfs defaults 0 0" >> /etc/fstab
sudo mount -a
date > /etc/provision_env_disk_added_date
