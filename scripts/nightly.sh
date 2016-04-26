#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/functions.sh

export DEPLOY_SERVER
export DEPLOY_PORT
export DOCKER_PULL_IMAGE=0
export PARALLEL_JOBS="${PARALLEL_JOBS:-1}"

mkdir -p ${VAGRANT_DIR}/logs/$NOW
chmod -R 755 ${VAGRANT_DIR}/logs/$NOW
update_vagrant_repo
system_upgrade

chmod -R 777 ${VAGRANT_DIR}/distfiles/
env_parallel --bibtex -P "${PARALLEL_JOBS}" automated_build ::: "${REPOSITORIES[@]}"

chmod 755 ${VAGRANT_DIR}/logs/
generate_metadata
docker_clean
