#!/bin/bash

. /vagrant/scripts/repositories.sh

system_upgrade

## cleanup

for i in "${REPOSITORIES[@]}"
do
	pushd /vagrant/repositories/$i
  send_email "$NOW Clean of $i" "Build started for $i, temp log is on $TEMPLOG"
  [ -f "clean.sh" ] && ./clean.sh  1>&2 > $TEMPLOG
  mytime=$(date +%s)
  cp -rfv $TEMPLOG "/vagrant/logs/$NOW/$i-clean.$mytime.log"
  chmod 444 /vagrant/logs/$NOW/$i-clean.$mytime.log
  send_email "$NOW Clean finished for $i" "Log is available at: /vagrant/logs/$NOW/$i-clean.$mytime.log"
	popd
done


#vagrant_cleanup

#docker
systemctl stop docker
rm -rfv /var/lib/docker
systemctl start docker
