#!/bin/bash

. /sbin/sark-functions.sh

NOW=$(date +"%Y-%m-%d")
mkdir -p ${VAGRANT_DIR}/logs/$NOW
chmod -R 755 ${VAGRANT_DIR}/logs/$NOW

(
    system_upgrade
    update_vagrant_repo

    ## cleanup

    docker_clean

    local images=$(docker images | tr -s ' ' | cut -d ' ' -f 3)
    if [ -n "${images}" ]; then
      docker rmi ${images}
    fi


    # update crontab
    crontab ${VAGRANT_DIR}/confs/crontab

    # yeah, dirty cleanup!
    #rm -rf ${DISTFILES}/*
    rm -rf ${ENTROPY_DOWNLOADED_PACKAGES}/*

    rm -rfv /tmp/.*
    rm -rfv /tmp/*
) | tee -a ${VAGRANT_DIR}/logs/${NOW}/monthly.log
