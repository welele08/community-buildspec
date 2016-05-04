#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/functions.sh

update_vagrant_repo

IMAGES=( $(docker images | awk '{ print $1 }' | grep -v "REPOSITORY") )
for i in "${IMAGES[@]}"
do
if [ -n "${i}" ]; then
  docker-companion squash ${i} ${i}
fi
done

docker_clean

rm -rfv /tmp/.*
rm -rfv /tmp/*
