#!/bin/bash

. /vagrant/scripts/repositories.sh

# upgrade
rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept
equo up
equo u

echo -5 | equo conf update

#cleanup

#vagrant_cleanup

#docker
systemctl stop docker
rm -rfv /var/lib/docker
systemctl start docker

equo cleanup --quick
