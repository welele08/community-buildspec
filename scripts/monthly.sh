#!/bin/bash

. /sbin/sark-functions.sh

system_upgrade
update_vagrant_repo

## cleanup

docker_clean

local images=$(docker images | tr -s ' ' | cut -d ' ' -f 3)
if [ -n "${images}" ]; then
  docker rmi ${images}
fi


# update crontab
crontab ${VAGRANT_DIR}/confs/crontab

# yeah, dirty cleanup!
#rm -rf ${DISTFILES}/*
rm -rf ${ENTROPY_DOWNLOADED_PACKAGES}/*

rm -rfv /tmp/.*
rm -rfv /tmp/*
