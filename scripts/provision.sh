#!/bin/bash

vgscan
vgchange -a y
mkdir -p /usr/portage/licenses/
rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept

equo up && sudo equo u
echo -5 | equo conf update
equo i docker sabayon-devkit vixie-cron git wget curl ansifilter md5deep \
dev-perl/JSON dev-perl/libwww-perl dev-python/pip \
sys-fs/btrfs-progs sys-apps/util-linux net-analyzer/netcat6 \
www-servers/nginx sys-process/parallel rng-tools docker-companion sabayon-sark app-misc/sabayon-auto-updater


# docker expects device mapper device and not lvm device. Do the conversion.
#eval $( lvs --nameprefixes --noheadings -o lv_name,kernel_major,kernel_minor vg-docker | while read line; do
#eval $line
#if [ "$LVM2_LV_NAME" = "datapool" ]; then
#echo POOL_DEVICE_PATH=/dev/mapper/$( cat /sys/dev/block/${LVM2_LV_KERNEL_MAJOR}:${LVM2_LV_KERNEL_MINOR}/dm/name )
#fi
#done )

#mkdir -p /etc/systemd/system/docker.service.d/
#echo "[Service]
#ExecStart=
#ExecStart=/usr/bin/docker daemon --storage-driver=btrfs -H fd://
#" > /etc/systemd/system/docker.service.d/vagrant_mount.conf

cp -rfv /vagrant/confs/rsyncd.conf /etc/rsyncd.conf
cp -rfv /vagrant/confs/nginx.conf /etc/nginx/nginx.conf
cp -rfv /vagrant/confs/rngd.service /usr/lib64/systemd/system/rngd.service

sed -i 's:txt;:txt log;:g' /etc/nginx/mime.types

systemctl daemon-reload
systemctl enable sabayon-auto-updater.timer
systemctl start sabayon-auto-updater.timer

systemctl enable docker
systemctl restart docker

systemctl enable vixie-cron
systemctl start vixie-cron

systemctl enable rsyncd
systemctl restart rsyncd

systemctl enable nginx
systemctl restart nginx

systemctl enable rngd
systemctl restart rngd

systemctl restart lvm2-monitor.service
systemctl enable lvm2-monitor.service

crontab /vagrant/confs/crontab
[ ! -d /vagrant/repositories ] && git clone https://github.com/Sabayon/community-repositories.git /vagrant/repositories
[ ! -d /vagrant/artifacts ] && mkdir -p /vagrant/artifacts
[ ! -d /vagrant/logs ] && mkdir -p /vagrant/logs
[ -d /vagrant/artifacts ] && chown -R nginx /vagrant/artifacts && chmod -R 755 /vagrant/artifacts
[ -d /vagrant/logs ] && chown -R nginx /vagrant/logs && chmod -R 755 /vagrant/logs

timedatectl set-ntp true
echo "@@@@ Provision finished, ensure everything is set up for deploy, suggestion is to reboot the machine to ensure docker is working correctly"
