#!/bin/bash

. /vagrant/scripts/functions.sh

system_upgrade

## cleanup

for i in "${REPOSITORIES[@]}"
do
  pushd ${VAGRANT_DIR}/repositories/$i
  send_email "[$i] Cleanup" "Started clean for $i $NOW , temp log is on $TEMPLOG"
  [ -f "clean.sh" ] && ./clean.sh  1>&2 > $TEMPLOG
  export REPOSITORY_NAME="$i"
  build_clean
  mytime=$(date +%s)
  cp -rfv $TEMPLOG "/vagrant/logs/$NOW/$i-clean.$mytime.log"
  chmod 444 ${VAGRANT_DIR}/logs/$NOW/$i-clean.$mytime.log
  send_email "[$i] Cleanup" "Finished, Log is available at: /vagrant/logs/$NOW/$i-clean.$mytime.log"
  popd
done

docker_clean

# yeah, cleanup!
rm -rfv /tmp/.*
rm -rfv /tmp/*

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

rm -rf ${DISTFILES}/*
rm -rf ${ENTROPY_DOWNLOADED_PACKAGES}/*
