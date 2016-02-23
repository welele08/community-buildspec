#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/repositories.sh

export DEPLOY_SERVER
export DEPLOY_PORT

mkdir -p /vagrant/logs/$NOW
pushd /vagrant
        git fetch --all
        git reset --hard master origin
popd

for i in "${REPOSITORIES[@]}"
do
	pushd /vagrant/repositories/$i
      send_email "$NOW Starting build of $i" "Build started for $i, temp log is on $TEMPLOG"
			[ -f "build.sh" ] && ./build.sh  1>&2 > $TEMPLOG
      cp -rfv $TEMPLOG "/vagrant/logs/$NOW/$i.$TEMPLOG.log"
			send_email "$NOW Build for $i" "$(cat $TEMPLOG)"
	popd
done
