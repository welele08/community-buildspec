#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/functions.sh

export DEPLOY_SERVER
export DEPLOY_PORT
export DOCKER_PULL_IMAGE=0

mkdir -p ${VAGRANT_DIR}/logs/$NOW
chmod -R 444 ${VAGRANT_DIR}/logs/$NOW
update_vagrant_repo

for i in "${REPOSITORIES[@]}"
do
  automated_build $i
done

generate_metadata

for i in "${REPOSITORIES[@]}"
do
  purge_old_packages $i
done

docker_clean
