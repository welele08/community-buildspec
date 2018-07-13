#!/bin/bash
# written by mudler@sabayon.org

. /sbin/sark-functions.sh

export DEPLOY_SERVER
export DEPLOY_PORT
export DOCKER_PULL_IMAGE=0
export PARALLEL_JOBS="${PARALLEL_JOBS:-1}"

NOW=$(date +"%Y-%m-%d")
mkdir -p ${VAGRANT_DIR}/logs/$NOW
chmod -R 755 ${VAGRANT_DIR}/logs/$NOW

(
    update_vagrant_repo
    system_upgrade

    chmod -R 777 ${VAGRANT_DIR}/distfiles/
    env_parallel -P "${PARALLEL_JOBS}" automated_build ::: "${REPOSITORIES[@]}"
    for rep in ${REPOSITORIES[@]}
    do
	rsync -avPz --delete -e "ssh -q" /vagrant/artifacts/$rep osmc@avril-simonet.hd.free.fr:/repo
    done

    chmod 755 ${VAGRANT_DIR}/logs/
    generate_metadata
    docker_clean
) | tee -a ${VAGRANT_DIR}/logs/${NOW}/nightly.log
