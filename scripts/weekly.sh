#!/bin/bash
# written by mudler@sabayon.org

. /sbin/sark-functions.sh

NOW=$(date +"%Y-%m-%d")
mkdir -p ${VAGRANT_DIR}/logs/$NOW
chmod -R 755 ${VAGRANT_DIR}/logs/$NOW

(
    update_vagrant_repo

    IMAGES=( $(docker images | awk '{ print $1 }' | grep -v "REPOSITORY") )
    for i in "${IMAGES[@]}"
    do
    if [ -n "${i}" ]; then
      docker-companion squash --remove ${i}
    fi
    done

    docker_clean

    # Execute a nightly with default args that makes sure we compile the whole tree. Diffs checks in functions.sh will prevent useless revbumps anyway
    EMERGE_DEFAULTS_ARGS="--accept-properties=-interactive -t --verbose --update --nospinner --oneshot --complete-graph --buildpkg" /vagrant/scripts/nightly.sh

    rm -rfv /tmp/.*
    rm -rfv /tmp/*
) | tee -a ${VAGRANT_DIR}/logs/${NOW}/weekly.log
