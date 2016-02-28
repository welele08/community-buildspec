#!/bin/bash

. /vagrant/scripts/repositories.sh

system_upgrade

## cleanup

for i in "${REPOSITORIES[@]}"
do
  pushd ${VAGRANT_DIR}/repositories/$i
  send_email "[$i] Cleanup" "Started clean for $i $NOW , temp log is on $TEMPLOG"
  [ -f "clean.sh" ] && ./clean.sh  1>&2 > $TEMPLOG
  mytime=$(date +%s)
  cp -rfv $TEMPLOG "/vagrant/logs/$NOW/$i-clean.$mytime.log"
  chmod 444 ${VAGRANT_DIR}/logs/$NOW/$i-clean.$mytime.log
  send_email "[$i] Cleanup" "Finished, Log is available at: /vagrant/logs/$NOW/$i-clean.$mytime.log"
  popd
done


#vagrant_cleanup

#docker
systemctl stop docker
rm -rfv /var/lib/docker
systemctl start docker

# update crontab
crontab ${VAGRANT_DIR}/confs/crontab

rm -rf ${DISTFILES}/*
rm -rf ${ENTROPY_DOWNLOADED_PACKAGES}/*
