#!/bin/bash

. /vagrant/scripts/functions.sh

system_upgrade
update_vagrant_repo

## cleanup

docker_clean

# Cleaning docker stuff with hands or eventually it will grow and eat up all the disk.
# [ -n "${DOCKER_IMAGE}" ] && docker rmi -f ${DOCKER_IMAGE} || docker rmi -f sabayon/builder-amd64
#
# systemctl stop docker
# rm -rfv /var/lib/docker
# systemctl start docker
#
# [ -n "${DOCKER_IMAGE}" ] && docker pull ${DOCKER_IMAGE} || docker pull sabayon/builder-amd64

# update crontab
crontab ${VAGRANT_DIR}/confs/crontab

# yeah, dirty cleanup!
rm -rf ${DISTFILES}/*
rm -rf ${ENTROPY_DOWNLOADED_PACKAGES}/*
rm -rfv /tmp/.*
rm -rfv /tmp/*
