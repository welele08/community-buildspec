#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/repositories.sh

export DEPLOY_SERVER
export DEPLOY_PORT
export DOCKER_PULL_IMAGE=1
export DOCKER_COMMIT_IMAGE=false

mkdir -p ${VAGRANT_DIR}/logs/$NOW
chmod -R 444 ${VAGRANT_DIR}/logs/$NOW
update_vagrant_repo

docker_clean
