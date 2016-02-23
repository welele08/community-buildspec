#!/bin/bash
# written by mudler@sabayon.org


. /vagrant/scripts/repositories.sh

pushd /vagrant
        git fetch --all
        git reset --hard master origin
popd

for i in "${REPOSITORIES[@]}"
do
  pushd /vagrant/repositories/$i
			#XXX: libchecks here
	popd
done
