#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/repositories.sh

export DEPLOY_SERVER
export DEPLOY_PORT
export DOCKER_PULL_IMAGE=0

mkdir -p /vagrant/logs/$NOW
chmod -R 444 /vagrant/logs/$NOW
update_vagrant_repo

for i in "${REPOSITORIES[@]}"
do
	pushd /vagrant/repositories/$i
  ### XXX: Libchecks in there!
      send_email "[$i] $NOW Build" "Build started for $i at $NOW, temp log is on $TEMPLOG"
			[ -f "build.sh" ] && ./build.sh  1>&2 > $TEMPLOG
      mytime=$(date +%s)
      ansifilter $TEMPLOG > "/vagrant/logs/$NOW/$i.$mytime.log"
      chmod 444 /vagrant/logs/$NOW/$i.$mytime.log
			send_email "[$i] $NOW Build" "Finished, log is available at: /vagrant/logs/$NOW/$i.$mytime.log"
	popd
done
