#!/bin/bash
# written by mudler@sabayon.org


. /vagrant/scripts/repositories.sh

update_vagrant_repo

for i in "${REPOSITORIES[@]}"
do
  pushd /vagrant/repositories/$i
			#XXX: libchecks here
	popd
done
