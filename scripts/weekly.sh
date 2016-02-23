#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/repositories.sh

export DEPLOY_SERVER
export DEPLOY_PORT

mkdir -p /vagrant/logs/$NOW
chmod -R 444 /vagrant/logs/$NOW
update_vagrant_repo

for i in "${REPOSITORIES[@]}"
do
	pushd /vagrant/repositories/$i
      send_email "$NOW Starting build of $i" "Build started for $i, temp log is on $TEMPLOG"
			[ -f "build.sh" ] && ./build.sh  1>&2 > $TEMPLOG
      mytime=$(date +%s)
      cp -rfv $TEMPLOG "/vagrant/logs/$NOW/$i.$mytime.log"
      chmod 444 /vagrant/logs/$NOW/$i.$mytime.log
			send_email "$NOW Build finished for $i" "Log is available at: /vagrant/logs/$NOW/$i.$mytime.log"
	popd
done
